%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    ns_device_types, assert_device_type_is_utx,
    harvester_device_type_to_element_type,
    transformer_device_type_to_element_types,
    get_device_dimension_ptr
)
from contracts.util.structs import (Vec2)
from contracts.util.grid import (
    is_valid_grid, are_contiguous_grids_given_valid_grids,
    locate_face_and_edge_given_valid_grid,
    is_zero
)
from contracts.util.logistics import (
    ns_logistics_harvester, ns_logistics_transformer,
    ns_logistics_xpg, ns_logistics_utb, ns_logistics_utl
)
from contracts.util.manufacturing import (
    ns_manufacturing
)

##############################

## Note: for utb-set or utl-set, GridStat.deployed_device_id is the set label
struct GridStat:
    member populated : felt
    member deployed_device_type : felt
    member deployed_device_id : felt
    member deployed_device_owner : felt
end

@storage_var
func grid_stats (grid : Vec2) -> (grid_stat : GridStat):
end

func is_unpopulated_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (grid : Vec2) -> ():
    alloc_locals

    let (grid_stat : GridStat) = grid_stats.read (grid)
    local g : Vec2 = grid

    with_attr error_message ("grid ({g.x}, {g.y}) is already populated"):
        assert grid_stat.populated = 0
    end

    return ()
end

#
# Make this function static i.e. not shifting over time due to geological events, not depleting due to harvest activities;
# instead of initializing this value at civilization start and store it persistently, we choose to recompute the number everytime,
# to (1) reduce compute requirement at civ start (2) trade storage with compute (3) allows for dynamic concentration later on.
# note: if desirable, this function can be replicated as-is in frontend (instead of polling contract from starknet) to compute only-once
# the distribution of concentration value per resource type per grid
#
func get_resource_concentration_at_grid {} (grid : Vec2, resource_type : felt) -> (resource_concentration : felt):
    alloc_locals

    # Requirement 1 / have a different distribution per resource type
    # Requirement 2 / design shape & amplitudes of distribution for specific resources e.g. plutonium-241 for game design purposes
    # Requirement 3 / expose parameters controlling these distributions as constants in `contracts.design.constants` for easier tuning
    # Requirement 4 / deal with fixed-point representation for concentration values

    # with_attr error_message ("function not implemented."):
    #     assert 1 = 0
    # end

    ## assuming the concentration value has a range of [0,1000)
    return (500)
end

##############################
## Devices (including opsf)
##############################

@storage_var
func device_undeployed_ledger (owner : felt, type : felt) -> (amount : felt):
end

struct DeviceDeployedEmapEntry:
    member grid : Vec2
    member type : felt
    member id : felt
end

struct TransformerResourceBalances:
    member balance_resource_before_transform : felt
    member balance_resource_after_transform : felt
end

@storage_var
func device_deployed_emap_size () -> (size : felt):
end

@storage_var
func device_deployed_emap (emap_index : felt) -> (emap_entry : DeviceDeployedEmapEntry):
end

# for quick reverse lookup (device-id to emap-index), assuming device-id is valid
@storage_var
func device_deployed_id_to_emap_index (id : felt) -> (emap_index : felt):
end

#
# Resource balances
#
@storage_var
func harvesters_deployed_id_to_resource_balance (id : felt) -> (balance : felt):
end

@storage_var
func transformers_deployed_id_to_resource_balances (id : felt) -> (balances : TransformerResourceBalances):
end

@storage_var
func opsf_deployed_id_to_resource_balances (id : felt, element_type : felt) -> (balance : felt):
end

#
# Energy balances
#
@storage_var
func device_deployed_id_to_energy_balance (id : felt) -> (energy : felt):
end

func assert_device_footprint_populable {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        type : felt, grid : Vec2
    ):
    alloc_locals

    #
    # for given device type, confirm the underlying grid(s) lie on the same face and are unpopulated
    # TODO: consider refactor this into constants.cairo, but need to encapsulate information of shape
    #       because constants.cairo does not have access to the storage_var `grid_stats` here
    #

    let (dim_ptr) = get_device_dimension_ptr ()
    let device_dim = dim_ptr [type]
    let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)

    #
    # Check 1x1
    #
    assert_valid_unpopulated_and_same_face (grid, face)

    if device_dim == 1:
        return ()
    end

    #
    # Check 2x2
    #
    let grid_ = Vec2 (grid.x + 1, grid.y)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 1, grid.y + 1)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x, grid.y + 1)
    assert_valid_unpopulated_and_same_face (grid_, face)

    if device_dim == 2:
        return ()
    end

    #
    # Check 3x3
    #
    let grid_ = Vec2 (grid.x + 2, grid.y)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 2, grid.y + 1)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 2, grid.y + 2)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 1, grid.y + 2)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x, grid.y + 2)
    assert_valid_unpopulated_and_same_face (grid_, face)

    if device_dim == 3:
        return ()
    end

    #
    # Check 5x5
    #
    let grid_ = Vec2 (grid.x + 3, grid.y)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 3, grid.y + 1)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 3, grid.y + 2)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 3, grid.y + 3)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 2, grid.y + 3)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 1, grid.y + 3)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x, grid.y + 3)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 4, grid.y)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 4, grid.y + 1)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 4, grid.y + 2)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 4, grid.y + 3)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 4, grid.y + 4)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 3, grid.y + 4)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 2, grid.y + 4)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x + 1, grid.y + 4)
    assert_valid_unpopulated_and_same_face (grid_, face)

    let grid_ = Vec2 (grid.x, grid.y + 4)
    assert_valid_unpopulated_and_same_face (grid_, face)

    return ()
end

func assert_valid_unpopulated_and_same_face {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2, face_tgt : felt
    ) -> ():
    alloc_locals

    is_valid_grid (grid)

    let (grid_stat) = grid_stats.read (grid)
    assert grid_stat.populated = 0

    let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)
    assert face = face_tgt

    return ()
end

func update_grid_with_new_grid_stat {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        type : felt, grid : Vec2, grid_stat : GridStat
    ) -> ():
    alloc_locals

    let (dim_ptr) = get_device_dimension_ptr ()
    let device_dim = dim_ptr [type]

    #
    # 1x1
    #
    grid_stats.write (grid, grid_stat)

    if device_dim == 1:
        return ()
    end

    #
    # 2x2
    #
    grid_stats.write (Vec2 (grid.x + 1, grid.y), grid_stat)
    grid_stats.write (Vec2 (grid.x + 1, grid.y + 1), grid_stat)
    grid_stats.write (Vec2 (grid.x, grid.y + 1), grid_stat)

    if device_dim == 2:
        return ()
    end

    #
    # 3x3
    #
    grid_stats.write (Vec2 (grid.x + 2, grid.y), grid_stat)
    grid_stats.write (Vec2 (grid.x + 2, grid.y + 1), grid_stat)
    grid_stats.write (Vec2 (grid.x + 2, grid.y + 2), grid_stat)
    grid_stats.write (Vec2 (grid.x + 1, grid.y + 2), grid_stat)
    grid_stats.write (Vec2 (grid.x, grid.y + 2), grid_stat)

    if device_dim == 3:
        return ()
    end

    #
    # 5x5
    #
    grid_stats.write (Vec2 (grid.x + 3, grid.y), grid_stat)
    grid_stats.write (Vec2 (grid.x + 3, grid.y + 1), grid_stat)
    grid_stats.write (Vec2 (grid.x + 3, grid.y + 2), grid_stat)
    grid_stats.write (Vec2 (grid.x + 3, grid.y + 3), grid_stat)
    grid_stats.write (Vec2 (grid.x + 2, grid.y + 3), grid_stat)
    grid_stats.write (Vec2 (grid.x + 1, grid.y + 3), grid_stat)
    grid_stats.write (Vec2 (grid.x, grid.y + 3), grid_stat)

    grid_stats.write (Vec2 (grid.x + 4, grid.y), grid_stat)
    grid_stats.write (Vec2 (grid.x + 4, grid.y + 1), grid_stat)
    grid_stats.write (Vec2 (grid.x + 4, grid.y + 2), grid_stat)
    grid_stats.write (Vec2 (grid.x + 4, grid.y + 3), grid_stat)
    grid_stats.write (Vec2 (grid.x + 4, grid.y + 4), grid_stat)
    grid_stats.write (Vec2 (grid.x + 3, grid.y + 4), grid_stat)
    grid_stats.write (Vec2 (grid.x + 2, grid.y + 4), grid_stat)
    grid_stats.write (Vec2 (grid.x + 1, grid.y + 4), grid_stat)
    grid_stats.write (Vec2 (grid.x, grid.y + 4), grid_stat)

    return ()
end

func device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        type : felt,
        grid : Vec2
    ) -> ():
    alloc_locals

    #
    # Check if caller owns at least 1 undeployed device of type `type`
    #
    let (amount_curr) = device_undeployed_ledger.read (caller, type)
    assert_nn (amount_curr - 1)

    #
    # Check if this device can be deployed with the origin of its footprint at `grid`
    #
    assert_device_footprint_populable (type, grid)

    #
    # Create new device id
    #
    tempvar data_ptr : felt* = new (4, caller, type, grid.x, grid.y)
    let (new_id) = hash_chain {hash_ptr = pedersen_ptr} (data_ptr)

    #
    # Update `grid_stats` at grid(s)
    #
    let new_grid_stat = GridStat(
        populated = 1,
        deployed_device_type = type,
        deployed_device_id =  new_id,
        deployed_device_owner = caller
    )
    update_grid_with_new_grid_stat (type, grid, new_grid_stat)

    #
    # Update `device_deployed_emap`
    #
    let (emap_size_curr) = device_deployed_emap_size.read ()
    device_deployed_emap_size.write (emap_size_curr + 1)
    device_deployed_emap.write (emap_size_curr, DeviceDeployedEmapEntry(
        grid = grid,
        type = type,
        id = new_id,
    ))

    #
    # Update `device_deployed_id_to_emap_index`
    #
    device_deployed_id_to_emap_index.write (new_id, emap_size_curr)

    #
    # Update `device_undeployed_ledger`: subtract by 1
    #
    device_undeployed_ledger.write (caller, type, amount_curr - 1)

    return ()
end

func recurse_untether_utx_for_deployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        id : felt,
        len : felt,
        idx : felt
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    #
    # Get utx-set label at current idx
    #
    let (utx_set_label) = utx_tether_labels_of_deployed_device.read (utx_device_type, id, idx)

    #
    # With the utx-set label, get its emap-index, then get its emap-entry
    #
    let (utx_set_emap_index) = utx_set_deployed_label_to_emap_index.read (utx_device_type, utx_set_label)
    let (utx_set_emap_entry) = utx_set_deployed_emap.read (utx_device_type, utx_set_emap_index)

    #
    # Construct new src & dst device id based on whether the device is this utx-set's src or dst device
    #
    let (is_src_device) = is_zero (utx_set_emap_entry.src_device_id - id)
    let (is_dst_device) = is_zero (utx_set_emap_entry.dst_device_id - id)
    let new_src_device_id = (1-is_src_device) * utx_set_emap_entry.src_device_id
    let new_dst_device_id = (1-is_dst_device) * utx_set_emap_entry.dst_device_id

    #
    # Update utx emap
    #
    utx_set_deployed_emap.write (
        utx_device_type, utx_set_emap_index,
        UtxSetDeployedEmapEntry(
            utx_set_deployed_label   = utx_set_emap_entry.utx_set_deployed_label,
            utx_deployed_index_start = utx_set_emap_entry.utx_deployed_index_start,
            utx_deployed_index_end   = utx_set_emap_entry.utx_deployed_index_end,
            src_device_id = new_src_device_id,
            dst_device_id = new_dst_device_id
        )
    )

    recurse_untether_utx_for_deployed_device (utx_device_type, id, len, idx + 1)

    return ()
end

func device_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid : Vec2
    ) -> ():
    alloc_locals

    #
    # Check if caller owns the device on `grid`
    #
    let (grid_stat) = grid_stats.read (grid)
    assert grid_stat.populated = 1
    assert grid_stat.deployed_device_owner = caller

    #
    # Update `device_deployed_emap`
    #
    let (emap_index) = device_deployed_id_to_emap_index.read (grid_stat.deployed_device_id)
    let (emap_size_curr) = device_deployed_emap_size.read ()
    let (emap_entry) = device_deployed_emap.read (emap_index)
    let (emap_entry_last) = device_deployed_emap.read (emap_size_curr - 1)
    device_deployed_emap_size.write (emap_size_curr - 1)
    device_deployed_emap.write (emap_size_curr - 1, DeviceDeployedEmapEntry(
        Vec2(0,0), 0, 0
    ))
    device_deployed_emap.write (emap_index, emap_entry_last)
    let grid_0_0 = emap_entry.grid
    let type = emap_entry.type

    #
    # Update `device_deployed_id_to_emap_index`
    #
    let id_moved = emap_entry_last.id
    device_deployed_id_to_emap_index.write (id_moved, emap_index)

    #
    # Untether all utx-sets tethered to this device
    #
    let (utb_tether_count) = utx_tether_count_of_deployed_device.read (ns_device_types.DEVICE_UTB, grid_stat.deployed_device_id)
    recurse_untether_utx_for_deployed_device (
        utx_device_type = ns_device_types.DEVICE_UTB,
        id = grid_stat.deployed_device_id,
        len = utb_tether_count,
        idx = 0
    )

    let (utl_tether_count) = utx_tether_count_of_deployed_device.read (ns_device_types.DEVICE_UTL, grid_stat.deployed_device_id)
    recurse_untether_utx_for_deployed_device (
        utx_device_type = ns_device_types.DEVICE_UTL,
        id = grid_stat.deployed_device_id,
        len = utl_tether_count,
        idx = 0
    )

    update_devices:
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr
    #
    # Clear entry in device-id to resource-balance lookup
    #
    let (bool_is_harvester) = is_device_harvester (grid_stat.deployed_device_type)
    let (bool_is_transformer) = is_device_transformer (grid_stat.deployed_device_type)

    check_harvesters:
    tempvar bool_is_harvester_minus_one = bool_is_harvester - 1
    jmp check_transformers if bool_is_harvester_minus_one != 0

    harvesters_deployed_id_to_resource_balance.write (
        grid_stat.deployed_device_id,
        0
    )
    jmp recycle

    check_transformers:
    if bool_is_transformer == 1:
        transformers_deployed_id_to_resource_balances.write (
            grid_stat.deployed_device_id,
            TransformerResourceBalances (0,0)
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    recycle:
    #
    # Recycle device back to caller
    #
    let (amount_curr) = device_undeployed_ledger.read (caller, grid_stat.deployed_device_type)
    device_undeployed_ledger.write (caller, grid_stat.deployed_device_type, amount_curr + 1)

    update_grid_stat:
    update_grid_with_new_grid_stat (type, grid_0_0, GridStat(
        populated = 0,
        deployed_device_type = 0,
        deployed_device_id = 0,
        deployed_device_owner = 0
    ))

    return ()
end

##############################
## utx
##############################

#
# utx (utb/utl) is fungible before deployment, but non-fungible after deployment,
# because they are deployed as a spatially-contiguous set with the same label,
# where contiguity is defined by the coordinate system on the cube surface;
# they are also deployed exclusively to connect their src & dst devices that meet
# the resource producer-consumer relationship.
#

#
# Use enumerable map (Emap) to maintain the an array of (set label, utx index start, utx index end)
# credit to Peteris at yagi.fi
#
struct UtxSetDeployedEmapEntry:
    member utx_set_deployed_label : felt
    member utx_deployed_index_start : felt
    member utx_deployed_index_end : felt
    member src_device_id : felt
    member dst_device_id : felt
end

@storage_var
func utx_set_deployed_emap_size (utx_device_type : felt) -> (size : felt):
end

@storage_var
func utx_set_deployed_emap (utx_device_type : felt, emap_index : felt) -> (emap_entry : UtxSetDeployedEmapEntry):
end

# for quick reverse lookup (utx-set label to emap-index)
@storage_var
func utx_set_deployed_label_to_emap_index (utx_device_type : felt, label : felt) -> (emap_index : felt):
end

#
# Append-only
#
@storage_var
func utx_deployed_index_to_grid_size (utx_device_type : felt) -> (size : felt):
end

@storage_var
func utx_deployed_index_to_grid (utx_device_type : felt, index : felt) -> (grid : Vec2):
end

#
# Recording the utx-sets tethered to a given id of deployed-device
#
@storage_var
func utx_tether_count_of_deployed_device (utx_device_type : felt, device_id : felt) -> (count : felt):
end

@storage_var
func utx_tether_labels_of_deployed_device (utx_device_type : felt, device_id : felt, idx : felt) -> (utx_set_label : felt):
end

#
# Player deploys UTX
# by providing a contiguous set of grids
#
func utx_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utx_device_type : felt,
        locs_len : felt,
        locs : Vec2*,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():
    alloc_locals

    assert_device_type_is_utx (utx_device_type)

    #
    # Check if caller owns at least `locs_len` amount of undeployed utx
    #
    let (local owned_utx_amount) = device_undeployed_ledger.read (caller, utx_device_type)
    local len = locs_len
    with_attr error_message ("attempt to deploy {len} amount of UTXs but owning only {owned_utx_amount}"):
        assert_le (locs_len, owned_utx_amount)
    end

    #
    # Check if caller owns src and dst device
    #
    let (src_grid_stat) = grid_stats.read (src_device_grid)
    let (dst_grid_stat) = grid_stats.read (dst_device_grid)
    with_attr error_message ("source-device grid is not populated"):
        assert src_grid_stat.populated = 1
    end
    with_attr error_message ("destination-device grid is not populated"):
        assert dst_grid_stat.populated = 1
    end
    with_attr error_message ("source-device is not owned by caller"):
        assert src_grid_stat.deployed_device_owner = caller
    end
    with_attr error_message ("destination-device is not owned by caller"):
        assert dst_grid_stat.deployed_device_owner = caller
    end

    #
    # Retrieve emap entry for src & dst devices
    #
    let src_device_id = src_grid_stat.deployed_device_id
    let dst_device_id = dst_grid_stat.deployed_device_id
    let (src_emap_index) = device_deployed_id_to_emap_index.read (src_device_id)
    let (dst_emap_index) = device_deployed_id_to_emap_index.read (dst_device_id)
    let (src_emap_entry) = device_deployed_emap.read (src_emap_index)
    let (dst_emap_entry) = device_deployed_emap.read (dst_emap_index)

    #
    # Check locs[0] is contiguous to src_device_id's grid using `are_contiguous_grids_given_valid_grids()`
    #
    are_contiguous_grids_given_valid_grids (locs[0], src_device_grid)

    #
    # Check locs[locs_len-1] is contiguous to dst_device_id's grid using `are_contiguous_grids_given_valid_grids()`
    #
    are_contiguous_grids_given_valid_grids (locs[locs_len-1], dst_device_grid)

    #
    # Check the type of (src,dst) meets (producer,consumer) relationship give utx type
    #
    are_producer_consumer_relationship (
        utx_device_type,
        src_grid_stat.deployed_device_type,
        dst_grid_stat.deployed_device_type
    )

    #
    # Recursively check for each locs's grid: (1) grid validity (2) grid unpopulated (3) grid is contiguous to previous grid
    #
    let (utx_idx_start) = utx_deployed_index_to_grid_size.read (utx_device_type)
    let utx_idx_end = utx_idx_start + locs_len
    tempvar data_ptr : felt* = new (3, caller, utx_idx_start, utx_idx_end)
    let (new_label) = hash_chain {hash_ptr = pedersen_ptr} (data_ptr)
    recurse_utx_deploy (
        caller = caller,
        utx_device_type = utx_device_type,
        len = locs_len,
        arr = locs,
        idx = 0,
        utx_idx = utx_idx_start,
        set_label = new_label
    )

    #
    # Decrease caller's undeployed utx amount
    #
    device_undeployed_ledger.write (caller, utx_device_type, owned_utx_amount - locs_len)

    #
    # Update `utx_deployed_index_to_grid_size`
    #
    utx_deployed_index_to_grid_size.write (utx_device_type, utx_idx_end)

    #
    # Insert to utx_set_deployed_emap; increase emap size
    #
    let (emap_size) = utx_set_deployed_emap_size.read (utx_device_type)
    utx_set_deployed_emap.write (
        utx_device_type, emap_size,
        UtxSetDeployedEmapEntry(
            utx_set_deployed_label   = new_label,
            utx_deployed_index_start = utx_idx_start,
            utx_deployed_index_end   = utx_idx_end,
            src_device_id = src_device_id,
            dst_device_id = dst_device_id
    ))
    utx_set_deployed_emap_size.write (utx_device_type, emap_size + 1)

    #
    # Update label-to-index for O(1) reverse lookup
    #
    utx_set_deployed_label_to_emap_index.write (utx_device_type, new_label, emap_size)

    #
    # For src and dst device, update their `utx_tether_count_of_deployed_device` and `utx_tether_labels_of_deployed_device`
    #
    let (count) = utx_tether_count_of_deployed_device.read (utx_device_type, src_emap_entry.id)
    utx_tether_count_of_deployed_device.write (utx_device_type, src_emap_entry.id, count + 1)
    utx_tether_labels_of_deployed_device.write (
        utx_device_type, src_emap_entry.id, count,
        new_label
    )

    let (count) = utx_tether_count_of_deployed_device.read (utx_device_type, dst_emap_entry.id)
    utx_tether_count_of_deployed_device.write (utx_device_type, dst_emap_entry.id, count + 1)
    utx_tether_labels_of_deployed_device.write (
        utx_device_type, dst_emap_entry.id, count,
        new_label
    )

    return ()
end


func recurse_utx_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utx_device_type : felt,
        len : felt,
        arr : Vec2*,
        idx : felt,
        utx_idx : felt,
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
    with_attr error_message ("recurse_utx_deploy(): grids are not contiguous."):
        are_contiguous_grids_given_valid_grids (arr[idx-1], arr[idx])
    end

    deploy:
    #
    # Update `utx_deployed_index_to_grid`
    #
    utx_deployed_index_to_grid.write (utx_device_type, utx_idx, arr[idx])

    #
    # Update global grid_stats ledger
    #
    grid_stats.write (arr[idx], GridStat (
        populated = 1,
        deployed_device_type = utx_device_type,
        deployed_device_id = set_label,
        deployed_device_owner = caller
    ))

    recurse_utx_deploy (caller, utx_device_type, len, arr, idx+1, utx_idx+1, set_label)
    return ()
end

#
# Player picks up UTX;
# given a grid, check its contains caller's own utx, and pick up the entire utx-set
#
func utx_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid : Vec2
    ) -> ():
    alloc_locals

    #
    # Check the grid contains an utx owned by caller
    #
    let (grid_stat) = grid_stats.read (grid)
    assert grid_stat.populated = 1
    assert grid_stat.deployed_device_owner = caller
    let utx_device_type = grid_stat.deployed_device_type
    assert_device_type_is_utx (utx_device_type)
    let utx_set_deployed_label = grid_stat.deployed_device_id

    #
    # O(1) find the emap_entry for this utx-set
    #
    let (emap_size_curr) = utx_set_deployed_emap_size.read (utx_device_type)
    let (emap_index) = utx_set_deployed_label_to_emap_index.read (utx_device_type, utx_set_deployed_label)
    let (emap_entry) = utx_set_deployed_emap.read (utx_device_type, emap_index)
    let utx_start_index = emap_entry.utx_deployed_index_start
    let utx_end_index = emap_entry.utx_deployed_index_end

    #
    # Recurse from start utx-idx to end utx-idx for this set
    # and clear the associated grid
    #
    recurse_pickup_utx_given_start_end_utx_index (
        utx_device_type = utx_device_type,
        start_idx = utx_start_index,
        end_idx = utx_end_index,
        idx = 0
    )

    #
    # Return the entire set of utxs back to the caller
    #
    let (amount_curr) = device_undeployed_ledger.read (caller, utx_device_type)
    device_undeployed_ledger.write (caller, utx_device_type, amount_curr + utx_end_index - utx_start_index)

    #
    # Update enumerable map of utx-sets:
    # removal operation - put last entry to index at removed entry, clear index at last entry,
    # and decrease emap size by one
    #
    let (emap_entry_last) = utx_set_deployed_emap.read (utx_device_type, emap_size_curr - 1)
    utx_set_deployed_emap.write (utx_device_type, emap_index, emap_entry_last)
    utx_set_deployed_emap.write (utx_device_type, emap_size_curr - 1, UtxSetDeployedEmapEntry (0,0,0,0,0))
    utx_set_deployed_emap_size.write (utx_device_type, emap_size_curr - 1)

    #
    # Update `utx_tether_count_of_deployed_device` and `utx_tether_labels_of_deployed_device` for both src and dst device
    #
    let (tether_count) = utx_tether_count_of_deployed_device.read (utx_device_type, emap_entry.src_device_id)
    utx_tether_count_of_deployed_device.write (utx_device_type, emap_entry.src_device_id, tether_count - 1)
    utx_tether_labels_of_deployed_device.write (utx_device_type, emap_entry.src_device_id, tether_count - 1, 0)

    let (tether_count) = utx_tether_count_of_deployed_device.read (utx_device_type, emap_entry.dst_device_id)
    utx_tether_count_of_deployed_device.write (utx_device_type, emap_entry.dst_device_id, tether_count - 1)
    utx_tether_labels_of_deployed_device.write (utx_device_type, emap_entry.dst_device_id, tether_count - 1, 0)

    return ()
end

func recurse_pickup_utx_given_start_end_utx_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        start_idx : felt,
        end_idx : felt,
        idx : felt
    ) -> ():
    alloc_locals

    if start_idx + idx == end_idx:
        return ()
    end

    let (grid_to_clear) = utx_deployed_index_to_grid.read (utx_device_type, start_idx + idx)
    grid_stats.write (grid_to_clear, GridStat(0,0,0,0))

    recurse_pickup_utx_given_start_end_utx_index (utx_device_type, start_idx, end_idx, idx + 1)
    return()
end

#
# Tether utx-set to src and device manually;
# useful when player wants to re-tether a deployed utx-set to new devices
# instead of having to pick up and redeploy the utx-set
#
func utx_tether_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utx_device_type : felt,
        utx_grid : Vec2,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    with_attr error_message ("Not implemented."):
        assert 1 = 0
    end

    return ()
end

##############################

func are_producer_consumer_relationship {range_check_ptr} (
    utx_device_type, device_type0, device_type1) -> ():

    # TODO: refactor this code to improve extensibility

    alloc_locals
    # upgrade input to local for error-message accessibility
    local x = device_type0
    local y = device_type1
    local z = utx_device_type


    if utx_device_type == ns_device_types.DEVICE_UTB:
        #
        # From harvester to corresponding refinery / enrichment facility
        #
        # iron harvester => iron refinery
        if (device_type0 - ns_device_types.DEVICE_FE_HARV + 1) * (device_type1 - ns_device_types.DEVICE_FE_REFN + 1) == 1:
            return ()
        end

        # aluminum harvester => aluminum refinery
        if (device_type0 - ns_device_types.DEVICE_AL_HARV + 1) * (device_type1 - ns_device_types.DEVICE_AL_REFN + 1) == 1:
            return ()
        end

        # copper harvester => copper refinery
        if (device_type0 - ns_device_types.DEVICE_CU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_CU_REFN + 1) == 1:
            return ()
        end

        # silicon harvester => silicon refinery
        if (device_type0 - ns_device_types.DEVICE_SI_HARV + 1) * (device_type1 - ns_device_types.DEVICE_SI_REFN + 1) == 1:
            return ()
        end

        # plutonium harvester => plutonium enrichment facility
        if (device_type0 - ns_device_types.DEVICE_PU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_PEF + 1) == 1:
            return ()
        end

        #
        # From harvester straight to OPSF
        #
        # iron harvester => OPSF
        if (device_type0 - ns_device_types.DEVICE_FE_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # aluminum harvester => OPSF
        if (device_type0 - ns_device_types.DEVICE_AL_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # copper harvester => OPSF
        if (device_type0 - ns_device_types.DEVICE_CU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # silicon harvester => OPSF
        if (device_type0 - ns_device_types.DEVICE_SI_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # plutonium harvester => OPSF
        if (device_type0 - ns_device_types.DEVICE_PU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        #
        # From refinery/enrichment facility to OPSF
        #
        # iron refinery => OPSF
        if (device_type0 - ns_device_types.DEVICE_FE_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # aluminum refinery => OPSF
        if (device_type0 - ns_device_types.DEVICE_AL_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # copper refinery => OPSF
        if (device_type0 - ns_device_types.DEVICE_CU_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # silicon refinery => OPSF
        if (device_type0 - ns_device_types.DEVICE_SI_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        # plutonium enrichment facility => OPSF
        if (device_type0 - ns_device_types.DEVICE_PEF + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
            return ()
        end

        tempvar range_check_ptr = range_check_ptr
    else:
        ## UTL

        #
        # SPG / NPG => any of the devices;
        # meaning device_type0 needs to be power generator (pg) :: {0, 1}
        # and device_type1 needs to be power consumer (pc) :: {2, 3 ... 14}
        #

        let (is_device_type0_pg) = is_nn_le (device_type0, 1)
        let (is_device_type1_pc) = is_nn_le (device_type1 - 2, 12)
        if is_device_type0_pg * is_device_type1_pc == 1:
            return ()
        end

        tempvar range_check_ptr = range_check_ptr
    end

    with_attr error_message("resource producer-consumer relationship check failed, with utx_device_type = {z}, device_type0 = {x} and device_type1 = {y}"):
        assert 1 = 0
    end
    return ()
end

func is_device_harvester {range_check_ptr} (type : felt) -> (bool : felt):
    let (bool) = is_nn_le (
        type - ns_device_types.DEVICE_HARVESTER_MIN,
        ns_device_types.DEVICE_HARVESTER_MAX - ns_device_types.DEVICE_HARVESTER_MIN
    )
    return (bool)
end

func is_device_transformer {range_check_ptr} (type : felt) -> (bool : felt):
    let (bool) = is_nn_le (
        type - ns_device_types.DEVICE_TRANSFORMER_MIN,
        ns_device_types.DEVICE_TRANSFORMER_MAX - ns_device_types.DEVICE_TRANSFORMER_MIN
    )
    return (bool)
end

func is_device_opsf {range_check_ptr} (type : felt) -> (bool : felt):
    if type == ns_device_types.DEVICE_OPSF:
        return (1)
    else:
        return (0)
    end
end

##############################

func resource_energy_update_at_devices {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    let (emap_size) = device_deployed_emap_size.read ()
    recurse_resource_energy_update_at_devices (
        len = emap_size,
        idx = 0
    )

    return ()
end

func recurse_resource_energy_update_at_devices {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len : felt, idx : felt
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    let (emap_entry) = device_deployed_emap.read (idx)
    let (bool_is_harvester) = is_device_harvester (emap_entry.type)
    let (bool_is_transformer) = is_device_transformer (emap_entry.type)

    #
    # For power generator
    #
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr
    handle_power_generator:
    ## solar power generator
    if emap_entry.type == ns_device_types.DEVICE_SPG:
        let (energy_generated) = ns_logistics_xpg.spg_solar_exposure_to_energy_generated_per_tick (
            solar_exposure = 10 # TODO!!!
        )
        let (curr_energy) = device_deployed_id_to_energy_balance.read (emap_entry.id)
        device_deployed_id_to_energy_balance.write (
            emap_entry.id,
            curr_energy + energy_generated
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    ## nuclear power generator
    if emap_entry.type == ns_device_types.DEVICE_NPG:
        let (curr_energy) = device_deployed_id_to_energy_balance.read (emap_entry.id)
        let (energy_generated) = ns_logistics_xpg.npg_energy_supplied_to_energy_generated_per_tick (curr_energy)
        device_deployed_id_to_energy_balance.write (
            emap_entry.id,
            curr_energy + energy_generated
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    #
    # For harvester => increase resource based on resource concentration at land
    #
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr
    handle_harvester:
    if bool_is_harvester == 1:
        #
        # Get harvest quantity based on {element type, concentration (from perlin), and energy supplied at last tick}
        #
        let (element_type) = harvester_device_type_to_element_type (emap_entry.type)
        let (concentration) = get_resource_concentration_at_grid (emap_entry.grid, element_type)
        let (energy_last_tick) = device_deployed_id_to_energy_balance.read (emap_entry.id)
        let (quantity_harvested) = ns_logistics_harvester.harvester_quantity_per_tick (
            element_type, concentration, energy_last_tick
        )

        #
        # Update resource balance at this harvester
        #
        let (quantity_curr) = harvesters_deployed_id_to_resource_balance.read (emap_entry.id)
        harvesters_deployed_id_to_resource_balance.write (
            emap_entry.id,
            quantity_curr + quantity_harvested
        )

        #
        # Clear energy balance at this harvester -- only power generator can store energy
        #
        device_deployed_id_to_energy_balance.write (
            emap_entry.id,
            0
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    #
    # For transformer (refinery/PEF) => decrease raw resource and increase transformed resource
    #
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr
    handle_transformer:
    if bool_is_transformer == 1:
        #
        # Determine the max quantity that can be transformed at this tick given element type and energy supplied at last tick
        #
        let (element_type_before, element_type_after) = transformer_device_type_to_element_types (emap_entry.type)
        let (balances) = transformers_deployed_id_to_resource_balances.read (emap_entry.id)
        let (energy_last_tick) = device_deployed_id_to_energy_balance.read (emap_entry.id)
        let (should_transform_quantity) = ns_logistics_transformer.transformer_quantity_per_tick (
            element_type_before,
            energy_last_tick
        )

        #
        # If balance of element_type_before < `should_transform_quantity`, only transform current balance;
        # otherwise, transform `should_transform_quantity`
        #
        local transform_amount
        let (bool) = is_le (balances.balance_resource_before_transform, should_transform_quantity)
        if bool == 1:
            assert transform_amount = balances.balance_resource_before_transform
        else:
            assert transform_amount = should_transform_quantity
        end

        #
        # Apply transform on balances
        #
        transformers_deployed_id_to_resource_balances.write (
            emap_entry.id,
            TransformerResourceBalances (
                balances.balance_resource_before_transform - transform_amount,
                balances.balance_resource_after_transform + transform_amount
            )
        )

        #
        # Clear energy balance at this transformer -- only power generator can store energy
        #
        device_deployed_id_to_energy_balance.write (
            emap_entry.id,
            0
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    #
    # Handle OPSF
    #
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr
    handle_opsf:
    if emap_entry.type == ns_device_types.DEVICE_OPSF:
        #
        # Clear energy balance at this OPSF -- only power generator can store energy
        #
        device_deployed_id_to_energy_balance.write (
            emap_entry.id,
            0
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    #
    # Tail recursion
    #
    recurse:
    recurse_resource_energy_update_at_devices (len, idx + 1)

    return ()
end

func resource_transfer_across_utb_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    #
    # recursively traverse `utx_set_deployed_emap`
    #
    let (emap_size) = utx_set_deployed_emap_size.read (ns_device_types.DEVICE_UTB)
    recurse_resource_transfer_across_utb_sets (
        len = emap_size, idx = 0
    )
    return ()
end

func recurse_resource_transfer_across_utb_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len, idx
    ) -> ():
    alloc_locals

    #
    # transfer resource from source to destination according to transport rate
    # NOTE: source device can be connected to multiple utb, resulting in higher transport rate
    # NOTE: opsf as destination device can be connected to multiple utb transporting same/different kinds of resources
    #

    if idx == len:
        return ()
    end

    #
    # check if source device and destination device are still deployed;
    # note: haven't figured out how to do conditional jump in recursion elegantly
    #
    let (emap_entry) = utx_set_deployed_emap.read (ns_device_types.DEVICE_UTB, idx)
    let (is_src_tethered) = is_not_zero (emap_entry.src_device_id)
    let (is_dst_tethered) = is_not_zero (emap_entry.dst_device_id)
    let  utb_set_length = emap_entry.utx_deployed_index_end - emap_entry.utx_deployed_index_start

    #
    # If both sides are tethered => handle resource transportation
    #
    if is_src_tethered * is_dst_tethered == 1:
        #
        # Find out source / destination device type
        #
        let (emap_index_src) = device_deployed_id_to_emap_index.read (emap_entry.src_device_id)
        let (emap_entry_src) = device_deployed_emap.read (emap_index_src)
        let (emap_index_dst) = device_deployed_id_to_emap_index.read (emap_entry.dst_device_id)
        let (emap_entry_dst) = device_deployed_emap.read (emap_index_dst)
        let src_type = emap_entry_src.type
        let dst_type = emap_entry_dst.type
        let (bool_src_harvester) = is_device_harvester (src_type)
        let (bool_dst_opsf) = is_device_opsf (dst_type)

        local quantity_received
        local element_type

        ## Handle source device first

        #
        # Source device is harvester
        #
        if bool_src_harvester == 1:
            #
            # Determine quantity to be sent from source
            #
            let (element_type_) = harvester_device_type_to_element_type (src_type)
            assert element_type = element_type_
            let (src_balance) = harvesters_deployed_id_to_resource_balance.read (emap_entry.src_device_id)
            let (quantity_should_send) = ns_logistics_utb.utb_quantity_should_send_per_tick (
                src_balance
            )

            #
            # Determine quantity to be received at destination
            #
            let (quantity_should_receive) = ns_logistics_utb.utb_quantity_should_receive_per_tick (
                src_balance,
                utb_set_length
            )
            assert quantity_received = quantity_should_receive

            #
            # Update source device resource balance
            #
            harvesters_deployed_id_to_resource_balance.write (
                emap_entry.src_device_id,
                src_balance - quantity_should_send
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr

        #
        # Source device is transformer
        #
        else:
            #
            # Determine quantity to be sent from source
            #
            let (_, element_type_) = transformer_device_type_to_element_types (src_type)
            assert element_type = element_type_
            let (src_balances) = transformers_deployed_id_to_resource_balances.read (emap_entry.src_device_id)
            let src_balance = src_balances.balance_resource_after_transform
            let (quantity_should_send) = ns_logistics_utb.utb_quantity_should_send_per_tick (
                src_balance
            )

            #
            # Determine quantity to be received at destination
            #
            let (quantity_should_receive) = ns_logistics_utb.utb_quantity_should_receive_per_tick (
                src_balance,
                utb_set_length
            )
            assert quantity_received = quantity_should_receive

            #
            # Update source device resource balance
            #
            transformers_deployed_id_to_resource_balances.write (
                emap_entry.src_device_id,
                TransformerResourceBalances(
                    src_balances.balance_resource_before_transform,
                    src_balance - quantity_should_send
            ))

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        ## Then handle destination device

        #
        # Destination device is OPSF
        #
        if bool_dst_opsf == 1:
            #
            # Update destination device resource balance
            #
            let (dst_balance) = opsf_deployed_id_to_resource_balances.read (emap_entry.dst_device_id, element_type)
            opsf_deployed_id_to_resource_balances.write (
                emap_entry.dst_device_id,
                element_type,
                dst_balance + quantity_received
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr

        #
        # Destination device is transformer
        #
        else:
            #
            # Update destination device resource balance
            #
            let (dst_balances) = transformers_deployed_id_to_resource_balances.read (emap_entry.dst_device_id)
            transformers_deployed_id_to_resource_balances.write (
                emap_entry.dst_device_id,
                TransformerResourceBalances(
                    dst_balances.balance_resource_before_transform + quantity_received,
                    dst_balances.balance_resource_after_transform
            ))

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    recurse_resource_transfer_across_utb_sets (len, idx + 1)
    return ()
end


func energy_transfer_across_utl_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    #
    # recursively traverse `utx_set_deployed_emap`
    #
    let (emap_size) = utx_set_deployed_emap_size.read (ns_device_types.DEVICE_UTL)
    recurse_energy_transfer_across_utl_sets (
        len = emap_size, idx = 0
    )
    return ()
end

func recurse_energy_transfer_across_utl_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len, idx
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    #
    # check if source device and destination device are still deployed
    #
    let (emap_entry) = utx_set_deployed_emap.read (ns_device_types.DEVICE_UTL, idx)
    let (is_src_tethered) = is_not_zero (emap_entry.src_device_id)
    let (is_dst_tethered) = is_not_zero (emap_entry.dst_device_id)
    let  utl_set_length = emap_entry.utx_deployed_index_end - emap_entry.utx_deployed_index_start

    if is_src_tethered * is_dst_tethered == 1:
        #
        # Get device id of source and destination
        #
        let (emap_index_src) = device_deployed_id_to_emap_index.read (emap_entry.src_device_id)
        let (emap_entry_src) = device_deployed_emap.read (emap_index_src)
        let (emap_index_dst) = device_deployed_id_to_emap_index.read (emap_entry.dst_device_id)
        let (emap_entry_dst) = device_deployed_emap.read (emap_index_dst)
        let src_device_id = emap_entry_src.id
        let dst_device_id = emap_entry_dst.id
        let (src_device_energy) = device_deployed_id_to_energy_balance.read (src_device_id)
        let (dst_device_energy) = device_deployed_id_to_energy_balance.read (dst_device_id)

        #
        # Determine energy should send and energy should receive
        #
        let (energy_should_send) = ns_logistics_utl.utl_energy_should_send_per_tick (
            src_device_energy
        )
        let (energy_should_receive) = ns_logistics_utl.utl_energy_should_receive_per_tick (
            src_device_energy,
            utl_set_length
        )

        #
        # Effect energy update at source
        #
        device_deployed_id_to_energy_balance.write (
            src_device_id,
            src_device_energy - energy_should_send
        )

        #
        # Effect energy update at destination
        # note: could have multi-fanin resulting higher energy boost
        #
        device_deployed_id_to_energy_balance.write (
            dst_device_id,
            dst_device_energy + energy_should_receive
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end


    recurse_energy_transfer_across_utl_sets (
        len,
        idx + 1
    )
    return ()
end

func forward_world_micro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    #
    # Effect resource & energy update at device;
    # akin to propagating D->Q for flip-flops in digital circuit
    #
    resource_energy_update_at_devices ()

    #
    # Effect resource transfer across deployed utb-sets;
    # akin to propagating values through wires in digital circuit
    #
    resource_transfer_across_utb_sets ()
    energy_transfer_across_utl_sets ()

    return ()
end

#####################################
## Iterators for client view purposes
#####################################

#
# Iterating over device emap
#
func iterate_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (
        emap_len : felt,
        emap : DeviceDeployedEmapEntry*
    ):
    alloc_locals

    let (emap_size) = device_deployed_emap_size.read ()
    let (emap : DeviceDeployedEmapEntry*) = alloc ()

    recurse_traverse_device_deployed_emap (emap_size, emap, 0)

    return (emap_size, emap)
end

func recurse_traverse_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    len : felt,
    arr : DeviceDeployedEmapEntry*,
    idx : felt) -> ():

    if idx == len:
        return ()
    end

    let (emap_entry) = device_deployed_emap.read (idx)
    assert arr[idx] = emap_entry

    recurse_traverse_device_deployed_emap (len, arr, idx+1)

    return ()
end


#
# Iterating over utx emap
#
func iterate_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        emap_len : felt,
        emap : UtxSetDeployedEmapEntry*
    ):
    alloc_locals

    let (emap_size) = utx_set_deployed_emap_size.read (utx_device_type)
    let (emap : UtxSetDeployedEmapEntry*) = alloc ()

    recurse_traverse_utx_deployed_emap (utx_device_type, emap_size, emap, 0)

    return (emap_size, emap)
end

func recurse_traverse_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        len : felt,
        arr : UtxSetDeployedEmapEntry*,
        idx : felt
    ) -> ():

    if idx == len:
        return ()
    end

    let (emap_entry) = utx_set_deployed_emap.read (utx_device_type, idx)
    assert arr[idx] = emap_entry

    recurse_traverse_utx_deployed_emap (utx_device_type, len, arr, idx+1)

    return ()
end

@view
func iterate_utx_deployed_emap_grab_all_utxs {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (

        grids_len : felt,
        grids : Vec2*
    ):
    alloc_locals

    #
    # Double recursion:
    # recurse over utx-deployed emap,
    # then for each entry, recurse from index start to index end to grab the grids
    # return one big array of grids
    #

    let (grids : Vec2*) = alloc ()
    let (outer_loop_len) = utx_set_deployed_emap_size.read (utx_device_type)
    let (count_final) = recurse_outer_grab_utxs (
        utx_device_type = utx_device_type,
        len = outer_loop_len,
        idx = 0,
        arr = grids,
        count = 0
    )

    return (count_final, grids)
end

func recurse_outer_grab_utxs {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        len : felt,
        idx : felt,
        arr : Vec2*,
        count : felt
    ) -> (
        count_final : felt
    ):
    alloc_locals

    if idx == len:
        return (count)
    end

    #
    # inner recursion
    #
    let (emap_entry)  = utx_set_deployed_emap.read (utx_device_type, idx)
    let utx_idx_start = emap_entry.utx_deployed_index_start
    let utx_idx_end   = emap_entry.utx_deployed_index_end

    with_attr error_message ("utx_idx_start should not equal to utx_idx_end for any utx emap entry."):
        assert_not_equal (utx_idx_start, utx_idx_end)
    end

    recurse_inner_grab_utxs (
        utx_device_type = utx_device_type,
        idx_start = utx_idx_start,
        idx_end = utx_idx_end,
        off = 0,
        arr = arr
    )

    #
    # tail recursion
    #
    let (count_final) = recurse_outer_grab_utxs (
        utx_device_type,
        len,
        idx + 1,
        &arr [utx_idx_end - utx_idx_start],
        count + utx_idx_end - utx_idx_start
    )
    return (count_final)
end

func recurse_inner_grab_utxs {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        idx_start : felt,
        idx_end : felt,
        off : felt,
        arr : Vec2*
    ) -> ():
    alloc_locals

    if idx_start + off == idx_end:
        return ()
    end

    let (grid : Vec2) = utx_deployed_index_to_grid.read (utx_device_type, idx_start + off)

    local offset = off
    with_attr error_message ("`arr` at {offset} already occupied."):
        assert arr[off] = grid
    end

    recurse_inner_grab_utxs (
        utx_device_type,
        idx_start,
        idx_end,
        off + 1,
        arr
    )
    return ()
end

######################################
## OPSF functions
######################################

#
# Client invokes to build device at OPSF; can build multiple devices of the same type with one invoke
#
func opsf_build_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid : Vec2,
        device_type : felt,
        device_count : felt
    ) -> ():
    alloc_locals

    #
    # Check if `caller` owns the device at `opsf_grid`
    #
    let (grid_stat) = grid_stats.read (grid)
    assert grid_stat.populated = 1
    assert grid_stat.deployed_device_owner = caller

    #
    # Check if an OPSF is deployed at `opsf_grid`
    #
    assert grid_stat.deployed_device_type = ns_device_types.DEVICE_OPSF
    let opsf_device_id = grid_stat.deployed_device_id

    #
    # Get resource & energy requirement for manufacturing one device of type `device_type`
    #
    let (
        energy : felt,
        resource_arr_len : felt,
        resource_arr : felt*
    ) = ns_manufacturing.get_resource_energy_requirement_given_device_type (
        device_type
    )

    #
    # Consume opsf energy; revert if insufficient
    #
    let (curr_energy) = device_deployed_id_to_energy_balance.read (opsf_device_id)
    assert_le (energy, curr_energy)
    device_deployed_id_to_energy_balance.write (
        opsf_device_id,
        curr_energy - energy
    )

    #
    # Recurse update resource balance at this OPSF; revert if any balance is insufficient
    #
    recurse_consume_device_balance_at_opsf (
        opsf_device_id = opsf_device_id,
        device_count = device_count,
        len = resource_arr_len,
        arr = resource_arr,
        idx = 0
    )
    return ()
end

func recurse_consume_device_balance_at_opsf {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        opsf_device_id : felt,
        device_count : felt,
        len : felt,
        arr : felt*,
        idx : felt
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    #
    # Check if opsf has sufficient resource balance of this type
    #
    let (curr_balance) = opsf_deployed_id_to_resource_balances.read (
        opsf_device_id, idx
    )
    let quantity_should_consume = arr[idx] * device_count
    assert_le (quantity_should_consume, curr_balance)

    #
    # Update opsf's resource balance of this type
    #
    opsf_deployed_id_to_resource_balances.write (
        opsf_device_id, idx,
        curr_balance - quantity_should_consume
    )

    #
    # Tail recursion
    #
    recurse_consume_device_balance_at_opsf (
        opsf_device_id,
        device_count,
        len,
        arr,
        idx + 1
    )
    return ()
end

######################################
## Mock functions for testing purposes
######################################

@external
func mock_device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        type : felt,
        grid_x : felt,
        grid_y : felt
    ) -> ():

    device_deploy (
        caller,
        type,
        Vec2 (grid_x, grid_y)
    )

    return ()
end


@external
func mock_device_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid_x : felt,
        grid_y : felt
    ) -> ():
    alloc_locals

    device_pickup_by_grid (
        caller,
        Vec2 (grid_x, grid_y)
    )

    return ()
end


@external
func mock_utx_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utx_device_type : felt,
        locs_x_len : felt,
        locs_x : felt*,
        locs_y_len : felt,
        locs_y : felt*,
        src_device_grid_x : felt,
        src_device_grid_y : felt,
        dst_device_grid_x : felt,
        dst_device_grid_y : felt
    ) -> ():
    alloc_locals

    assert_device_type_is_utx (utx_device_type)

    # since our Account implementation can't sign arbitary struct,
    # for testing purposes we need to break locs array into two arrays,
    # one for x's and one for y's

    assert locs_x_len = locs_y_len
    let locs_len = locs_x_len
    let (locs : Vec2*) = alloc ()
    assemble_xy_arrays_into_vec2_array (
        len = locs_x_len,
        arr_x = locs_x,
        arr_y = locs_y,
        arr = locs,
        idx = 0
    )

    utx_deploy (
        caller,
        utx_device_type,
        locs_len,
        locs,
        Vec2 (src_device_grid_x, src_device_grid_y),
        Vec2 (dst_device_grid_x, dst_device_grid_y)
    )

    return ()
end

func assemble_xy_arrays_into_vec2_array {range_check_ptr} (
        len : felt,
        arr_x : felt*,
        arr_y : felt*,
        arr : Vec2*,
        idx : felt
    ) -> ():
    if idx == len:
        return ()
    end

    assert arr[idx] = Vec2 (arr_x[idx], arr_y[idx])

    assemble_xy_arrays_into_vec2_array (
        len, arr_x, arr_y, arr, idx + 1
    )
    return ()
end


@external
func mock_utx_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid_x : felt,
        grid_y : felt
    ) -> ():

    utx_pickup_by_grid (
        caller,
        Vec2 (grid_x, grid_y)
    )

    return ()
end


@external
func mock_utx_tether_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utx_device_type : felt,
        utx_grid : Vec2,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    utx_tether_by_grid (
        caller,
        utx_device_type,
        utx_grid,
        src_device_grid,
        dst_device_grid
    )

    return ()
end


@external
func mock_are_producer_consumer_relationship {range_check_ptr} (
    utx_device_type, device_type0, device_type1) -> ():

    are_producer_consumer_relationship (
        utx_device_type,
        device_type0,
        device_type1
    )

    return ()
end

@external
func mock_forward_world_micro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    forward_world_micro ()

    return ()
end

#######################################
## Admin functions for testing purposes
#######################################

@view
func admin_read_grid_stats {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (grid : Vec2) -> (grid_stat : GridStat):
    let (grid_stat) = grid_stats.read (grid)
    return (grid_stat)
end

@view
func admin_read_device_undeployed_ledger {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    owner : felt, type : felt) -> (amount : felt):
    let (amount) = device_undeployed_ledger.read (owner, type)
    return (amount)
end

@external
func admin_write_device_undeployed_ledger {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    owner : felt, type : felt, amount : felt):
    device_undeployed_ledger.write (owner, type, amount)
    return ()
end

@view
func admin_read_device_deployed_emap_size {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (size : felt):
    let (size) = device_deployed_emap_size.read ()
    return (size)
end

@view
func admin_read_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    emap_index : felt) -> (emap_entry : DeviceDeployedEmapEntry):
    let (emap_entry) = device_deployed_emap.read (emap_index)
    return (emap_entry)
end

@view
func admin_read_device_deployed_id_to_emap_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt) -> (emap_index : felt):
    let (emap_index) = device_deployed_id_to_emap_index.read (id)
    return (emap_index)
end

@view
func admin_read_harvesters_deployed_id_to_resource_balance {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt) -> (balance : felt):
    let (balance) = harvesters_deployed_id_to_resource_balance.read (id)
    return (balance)
end

@view
func admin_read_transformers_deployed_id_to_resource_balances {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt) -> (balances : TransformerResourceBalances):
    let (balances) = transformers_deployed_id_to_resource_balances.read (id)
    return (balances)
end

@view
func admin_read_opsf_deployed_id_to_resource_balances {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt, element_type : felt) -> (balance : felt):
    let (balance) = opsf_deployed_id_to_resource_balances.read (id, element_type)
    return (balance)
end


@view
func admin_read_utx_set_deployed_emap_size {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type : felt) -> (size : felt):
    let (size) = utx_set_deployed_emap_size.read (utx_device_type)
    return (size)
end

@view
func admin_read_utx_set_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type : felt, emap_index : felt) -> (emap_entry : UtxSetDeployedEmapEntry):
    let (emap_entry) = utx_set_deployed_emap.read (utx_device_type, emap_index)
    return (emap_entry)
end

@view
func admin_read_utx_set_deployed_label_to_emap_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type : felt, label : felt) -> (emap_index : felt):
    let (emap_index) = utx_set_deployed_label_to_emap_index.read (utx_device_type, label)
    return (emap_index)
end

@view
func admin_read_utx_deployed_index_to_grid_size {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type : felt) -> (size : felt):
    let (size) = utx_deployed_index_to_grid_size.read (utx_device_type)
    return (size)
end

@view
func admin_read_utx_deployed_index_to_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type : felt, index : felt) -> (grid : Vec2):
    let (grid) = utx_deployed_index_to_grid.read (utx_device_type, index)
    return (grid)
end


@view
func admin_read_utx_tether_count_of_deployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type : felt, device_id : felt) -> (count : felt):

    let (count) = utx_tether_count_of_deployed_device.read (utx_device_type, device_id)

    return (count)
end


@view
func admin_read_utx_tether_labels_of_deployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    utx_device_type, device_id : felt, idx : felt) -> (utx_set_label : felt):

    let (utx_set_label) = utx_tether_labels_of_deployed_device.read (utx_device_type, device_id, idx)

    return (utx_set_label)
end
