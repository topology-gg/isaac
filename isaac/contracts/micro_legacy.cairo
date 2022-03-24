%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt)
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.macro import (forward_world_macro)
from contracts.design.constants import (ns_device_types)
from contracts.util.structs import (
    MicroEvent, Vec2
)
from contracts.grid import (
    is_valid_grid, are_contiguous_grids_given_valid_grids
)

##############################

# @constructor
# func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

#     return()
# end

# @external
# func forward_micro_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
#     alloc_locals


#     return ()
# end

##############################

struct GridStat:
    member populated : felt
    member deployed_device_type : felt
    member deployed_device_index : felt
    member deployed_device_owner : felt
end

@storage_var
func grid_stats (grid : Vec2) -> (grid_stat : GridStat):
end

func is_unpopulated_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (grid : Vec2) -> ():
    let (grid_stat : GridStat) = grid_stats.read (grid)
    assert grid_stat.populated = 0
    return ()
end

##############################
## Devices (including opsf)
##############################

@storage_var
func device_undeployed_ledger (owner : felt, type : felt) -> (amount : felt):
end

struct DeviceLLNode:
    member info : DeviceInfo
    member next : felt
end

## Note: for utb-set or utl-set, DeviceInfo.index is it the set label
struct DeviceInfo:
    member owner : felt
    member grid : Vec2
    member type : felt
    member index : felt
end

@storage_var
func device_deployed_linked_list (index : felt) -> (node : DeviceLLNode):
end

#
# Append-only
#
@storage_var
func device_deployed_index_to_info (index : felt) -> (info : DeployedDeviceInfo):
end

@storage_var
func device_deployed_index_to_info_size () -> (size : felt):
end

# TODO: if one picks up a device that's tethered to UTB/UTL, the UTB/UTL get picked up automatically,
#       which means the deployed device needs knowledge of the label of the associated UTB/UTL
# func device_pickup {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
# end

##############################
## utb
##############################

#
# utb is fungible before deployment,
# but non-fungible after deployment,
# because they are deployed as a spatially-contiguous set with the same label,
# where contiguity here is defined by the coordinate system on the cube surface
#
@storage_var
func utb_undeployed_ledger (owner : felt) -> (amount : felt):
end

#
# Use enumerable map (Emap) to maintain the an array of (set label, utb index start, utb index end)
#
struct UtbSetDeployedEmapEntry:
    member utb_set_deployed_label : felt
    member utb_deployed_index_start : felt
    member utb_deployed_index_end : felt
end

@storage_var
func utb_set_deployed_emap_size () -> (size : felt):
end

@storage_var
func utb_set_deployed_emap (emap_index : felt) -> (emap_entry : UtbSetDeployedEmapEntry):
end

#
# Append-only
#
@storage_var
func utb_deployed_index_to_grid (index : felt) -> (grid : Vec2):
end

@storage_var
func utb_deployed_index_to_grid_size () -> (size : felt):
end

#
# Player deploys UTB
# by providing a contiguous set of grids
#
func utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        locs_len : felt,
        locs : Vec2*,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():
    alloc_locals

    #
    # Check if caller owns at least `locs_len` amount of undeployed utb
    #
    let (owned_utb_amount) = utb_undeployed_ledger.read (caller)
    assert_lt (owned_utb_amount, locs_len)

    #
    # Check if caller owns src and dst device
    #
    let (src_grid_stat) = grid_stats.read (src_device_grid)
    let (dst_grid_stat) = grid_stats.read (src_device_grid)
    assert src_grid_stat.populated = 1
    assert dst_grid_stat.populated = 1
    assert src_grid_stat.deployed_device_owner = caller
    assert dst_grid_stat.deployed_device_owner = caller

    #
    # Check locs[0] is contiguous to src_device_id's grid using `are_contiguous_grids_given_valid_grids()`
    #
    are_contiguous_grids_given_valid_grids (locs[0], src_device_grid)

    #
    # Check locs[locs_len-1] is contiguous to dst_device_id's grid using `are_contiguous_grids_given_valid_grids()`
    #
    are_contiguous_grids_given_valid_grids (locs[locs_len-1], dst_device_grid)

    #
    # Check the type of (src,dst) meets (producer,consumer) relationship
    #
    are_resource_producer_consumer_relationship (
        src_grid_stat.deployed_device_type,
        dst_grid_stat.deployed_device_type
    )

    #
    # Recursively check for each locs's grid: (1) grid validity (2) grid unpopulated (3) grid is contiguous to previous grid
    #
    let (utb_idx_start) = utb_deployed_index_to_grid_size.read ()
    recurse_utb_deploy (
        caller = caller,
        len = locs_len,
        arr = locs,
        idx = 0,
        utb_idx = utb_idx_start
    )

    #
    # Decrease caller's undeployed utb amount
    #
    utb_undeployed_ledger.write (caller, owned_utb_amount - locs_len)

    #
    # Update `utb_deployed_index_to_grid_size`
    #
    utb_deployed_index_to_grid_size.write (utb_idx_start + locs_len)

    # Insert to utb_set_deployed_emap; increase emap size
    let (data_ptr) = alloc ()
    assert data_ptr [0] = 3
    assert data_ptr [1] = caller
    assert data_ptr [2] = utb_idx_start
    assert data_ptr [3] = utb_idx_end
    let (new_label) = hash_chain (data_ptr)
    utb_set_deployed_emap.write (emap_size, UtbSetDeployedEmapEntry(
        utb_set_deployed_label = new_label,
        utb_deployed_index_start = utb_idx_start,
        utb_deployed_index_end = utb_idx_start + locs_len
    ))
    let (emap_size) = utb_set_deployed_emap_size.read ()
    utb_set_deployed_emap_size.write (emap_size + 1)

    # #
    # # Update `utb_set_deployed_linked_list` and its tail
    # #
    # let (old_tail_label) = utb_set_deployed_linked_list_tail.read ()
    # let (new_tail_label) = old_tail_label + 1
    # utb_set_deployed_linked_list_tail.write (new_tail_label)
    # let (old_tail_node) = utb_set_deployed_linked_list.read (old_tail_label)
    # let old_tail_node_ = DeployedUtbSetLLNode (
    #     info = old_tail_node.info,
    #     next = new_tail_label
    # )
    # let new_tail_node = DeployedUtbSetLLNode (
    #     info = DeployedUtbSetInfo (start_index = utb_idx_start, end_index = utb_idx_start + locs_len),
    #     next = 0
    # )
    # utb_set_deployed_linked_list.write (old_tail_label, old_tail_node_)
    # utb_set_deployed_linked_list.write (new_tail_label, new_tail_node)

    #
    # Register caller address with `new_tail_label`
    #
    utb_set_label_to_owner.write (new_tail_label, caller)

    ## TODO: when implement device_pickup(), come back here and add registry of utb-set info with device info
    ##       so that: (1) player checks the device and knows which utb-index it is that connects to it
    ##                (2) when the utb-tethered device gets picked up, the utb-set gets picked up automatically

    return ()
end


func recurse_utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        len : felt,
        arr : Vec2*,
        idx : felt,
        utb_idx : felt
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    #
    # In the following checks, any failure would revert this tx
    #
    # 1. check loc is a valid grid coordinate
    is_valid_grid (arr[idx])

    # 2. check loc is not already populated
    is_unpopulated_grid (arr[idx])

    # 3. check loc is contiguous with previous loc, unless idx==0
    if idx == 0:
        jmp deploy
    end
    are_contiguous_grids_given_valid_grids (arr[idx-1], arr[idx])

    deploy:
    #
    # Update utb_deployed_index_to_grid
    #
    utb_deployed_index_to_grid.write (utb_idx, arr[idx])

    #
    # Update global grid_stats ledger
    #
    grid_stats.write ( GridStat (
        populated = 1,
        deployed_device_type = ns_device_types.DEVICE_UTB,
        deployed_device_index = utb_idx,
        deployed_device_owner = caller
    ) )

    recurse_utb_deploy (len, arr, idx+1, utb_idx+1)
    return ()
end

#
# Player picks up UTB;
# given the label of utb-set, pick up the entire contiguous set
#
func utb_pickup {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utb_set_label : felt
    ) -> ():
    alloc_locals

    #
    # Check the utb-index refers to a utb sets owned by caller
    #
    let (utb_set_owner) = utb_set_label_to_owner.read (utb_set_label)
    assert caller = utb_set_owner

    #
    # Recurse from start utb-idx to end utb-idx for this set
    # and clear the associated grid
    #
    let (node : DeployedUtbSetLLNode) = utb_set_deployed_linked_list.read (utb_set_label)
    recurse_utb_pickup (
        # TODO
    )

    #
    # Return the entire set of utbs back to the caller
    #


    #
    # Update utb-set linked list --
    # remove the node with this label from the linked list
    #

    ## TODO: update the tethered src and dst device info as well

    return ()
end

# TODO
func forward_utb_effect_resource_transfer {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    # TODO:
    # recursively traverse `utb_set_deployed_linked_list`
    #   for each set, check if source device and destination device are still deployed;
    #   if yes, transfer resource from source to destination according to transport rate
    # NOTE: source device can be connected to multiple utb, resulting in higher transport rate
    # NOTE: opsf as destination device can be connected to multiple utb transporting same/different kinds of resources

    return ()
end

##############################

func are_resource_producer_consumer_relationship {range_check_ptr} (
    device_type0, device_type1) -> ():

    #
    # From harvester to corresponding refinery / enrichment facility
    #
    # iron harvester => iron refinery
    if (device_type0 - ns_device_types.DEVICE_FE_HARV) * (device_type1 - ns_device_types.DEVICE_FE_REFN) == 0:
        return ()
    end

    # aluminum harvester => aluminum refinery
    if (device_type0 - ns_device_types.DEVICE_AL_HARV) * (device_type1 - ns_device_types.DEVICE_AL_REFN) == 0:
        return ()
    end

    # copper harvester => copper refinery
    if (device_type0 - ns_device_types.DEVICE_CU_HARV) * (device_type1 - ns_device_types.DEVICE_CU_REFN) == 0:
        return ()
    end

    # silicon harvester => silicon refinery
    if (device_type0 - ns_device_types.DEVICE_SI_HARV) * (device_type1 - ns_device_types.DEVICE_SI_REFN) == 0:
        return ()
    end

    # plutonium harvester => plutonium enrichment facility
    if (device_type0 - ns_device_types.DEVICE_PU_HARV) * (device_type1 - ns_device_types.DEVICE_PEF) == 0:
        return ()
    end

    #
    # From harvester straight to OPSF
    #
    # iron harvester => OPSF
    if (device_type0 - ns_device_types.DEVICE_FE_HARV) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # aluminum harvester => OPSF
    if (device_type0 - ns_device_types.DEVICE_AL_HARV) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # copper harvester => OPSF
    if (device_type0 - ns_device_types.DEVICE_CU_HARV) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # silicon harvester => OPSF
    if (device_type0 - ns_device_types.DEVICE_SI_HARV) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # plutonium harvester => OPSF
    if (device_type0 - ns_device_types.DEVICE_PU_HARV) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    #
    # From refinery/enrichment facility to OPSF
    #
    # iron refinery => OPSF
    if (device_type0 - ns_device_types.DEVICE_FE_REFN) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # aluminum refinery => OPSF
    if (device_type0 - ns_device_types.DEVICE_AL_REFN) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # copper refinery => OPSF
    if (device_type0 - ns_device_types.DEVICE_CU_REFN) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # silicon refinery => OPSF
    if (device_type0 - ns_device_types.DEVICE_SI_REFN) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    # plutonium enrichment facility => OPSF
    if (device_type0 - ns_device_types.DEVICE_PEF) * (device_type1 - ns_device_types.DEVICE_OPSF) == 0:
        return ()
    end

    with_attr error_message("resource producer-consumer relationship check failed."):
        assert 1 = 0
    end
    return ()
end