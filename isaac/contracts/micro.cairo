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
from contracts.util.grid import (
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

## Note: for utb-set or utl-set, GridStat.deployed_device_index is the set label
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

# struct DeviceLLNode:
#     member info : DeviceInfo
#     member next : felt
# end

# struct DeviceInfo:
#     member grid : Vec2
#     member type : felt
#     member index : felt
# end

# @storage_var
# func device_deployed_linked_list (index : felt) -> (node : DeviceLLNode):
# end

#
# Append-only
# #
# @storage_var
# func device_deployed_index_to_info (index : felt) -> (info : DeployedDeviceInfo):
# end

# @storage_var
# func device_deployed_index_to_info_size () -> (size : felt):
# end

# TODO: if one picks up a device that's tethered to UTB/UTL, the UTB/UTL get picked up automatically,
#       which means the deployed device needs knowledge of the label of the associated UTB/UTL
# func device_pickup {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
# end

##############################
## utb
##############################

#
# utb is fungible before deployment, but non-fungible after deployment,
# because they are deployed as a spatially-contiguous set with the same label,
# where contiguity is defined by the coordinate system on the cube surface;
# they are also deployed exclusively to connect their src & dst devices that meet
# the resource producer-consumer relationship.
#
@storage_var
func utb_undeployed_ledger (owner : felt) -> (amount : felt):
end

#
# Use enumerable map (Emap) to maintain the an array of (set label, utb index start, utb index end)
# credit to Peteris at yagi.fi
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

@storage_var
func utb_set_deployed_label_to_index (label : felt) -> (emap_index : felt):
end

#
# Append-only
#
@storage_var
func utb_deployed_index_to_grid_size () -> (size : felt):
end

@storage_var
func utb_deployed_index_to_grid (index : felt) -> (grid : Vec2):
end

#
# Player deploys UTB
# by providing a contiguous set of grids
#
func utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, hash_ptr : HashBuiltin*, range_check_ptr} (
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
    let utb_idx_end = utb_idx_start + locs_len
    let (data_ptr) = alloc ()
    assert data_ptr [0] = 3
    assert data_ptr [1] = caller
    assert data_ptr [2] = utb_idx_start
    assert data_ptr [3] = utb_idx_end
    let (new_label) = hash_chain (data_ptr)
    recurse_utb_deploy (
        caller = caller,
        len = locs_len,
        arr = locs,
        idx = 0,
        utb_idx = utb_idx_start,
        set_label = new_label
    )

    #
    # Decrease caller's undeployed utb amount
    #
    utb_undeployed_ledger.write (caller, owned_utb_amount - locs_len)

    #
    # Update `utb_deployed_index_to_grid_size`
    #
    utb_deployed_index_to_grid_size.write (utb_idx_end)

    #
    # Insert to utb_set_deployed_emap; increase emap size
    #
    let (emap_size) = utb_set_deployed_emap_size.read ()
    utb_set_deployed_emap.write (emap_size, UtbSetDeployedEmapEntry(
        utb_set_deployed_label = new_label,
        utb_deployed_index_start = utb_idx_start,
        utb_deployed_index_end = utb_idx_end
    ))
    utb_set_deployed_emap_size.write (emap_size + 1)

    #
    # Update label-to-index for O(1) reverse lookup
    #
    utb_set_deployed_label_to_index.write (new_label, emap_size)

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
        utb_idx : felt,
        set_label : felt
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
    grid_stats.write (arr[idx], GridStat (
        populated = 1,
        deployed_device_type = ns_device_types.DEVICE_UTB,
        deployed_device_index = set_label,
        deployed_device_owner = caller
    ))

    recurse_utb_deploy (caller, len, arr, idx+1, utb_idx+1, set_label)
    return ()
end

#
# Player picks up UTB;
# given a grid, check its contains caller's own utb, and pick up the entire utb-set
#
func utb_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid : Vec2
    ) -> ():
    alloc_locals

    #
    # Check the grid contains an utb owned by caller
    #
    let (grid_stat) = grid_stats.read (grid)
    assert grid_stat.populated = 1
    assert grid_stat.deployed_device_type = ns_device_types.DEVICE_UTB
    assert grid_stat.deployed_device_owner = caller
    let utb_set_deployed_label = grid_stat.deployed_device_index

    #
    # O(1) find the emap_entry for this utb-set
    #
    let (emap_size_curr) = utb_set_deployed_emap_size.read ()
    let (emap_index) = utb_set_deployed_label_to_index.read (utb_set_deployed_label)
    let (emap_entry) = utb_set_deployed_emap.read (emap_index)
    let utb_start_index = emap_entry.utb_deployed_index_start
    let utb_end_index = emap_entry.utb_deployed_index_end

    #
    # Recurse from start utb-idx to end utb-idx for this set
    # and clear the associated grid
    #
    recurse_pickup_utb_given_start_end_utb_index (
        start_idx = utb_start_index,
        end_idx = utb_end_index,
        idx = 0
    )

    #
    # Return the entire set of utbs back to the caller
    #
    let (amount_curr) = utb_undeployed_ledger.read (caller)
    utb_undeployed_ledger.write (caller, amount_curr + utb_end_index - utb_start_index)

    #
    # Update enumerable map of utb-sets:
    # removal operation - put last entry to index at removed entry, clear index at last entry,
    # and decrease emap size by one
    #
    let (emap_entry_last) = utb_set_deployed_emap.read (emap_size_curr - 1)
    utb_set_deployed_emap.write (emap_index, emap_entry_last)
    utb_set_deployed_emap.write (emap_size_curr - 1, UtbSetDeployedEmapEntry (0,0,0))
    utb_set_deployed_emap_size.write (emap_size_curr - 1)

    ## TODO: update the tethered src and dst device info as well

    return ()
end

func recurse_pickup_utb_given_start_end_utb_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        start_idx,
        end_idx,
        idx
    ) -> ():
    alloc_locals

    if start_idx + idx == end_idx:
        return ()
    end

    let (grid_to_clear) = utb_deployed_index_to_grid.read (start_idx + idx)
    grid_stats.write (grid_to_clear, GridStat(0,0,0,0))

    recurse_pickup_utb_given_start_end_utb_index (start_idx, end_idx, idx + 1)
    return()
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