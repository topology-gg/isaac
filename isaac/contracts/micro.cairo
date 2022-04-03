%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    ns_device_types,
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
    let (grid_stat : GridStat) = grid_stats.read (grid)
    assert grid_stat.populated = 0
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

# this function assumes valid grid as input
func get_resource_harvest_amount_at_grid {} (grid : Vec2, resource_type : felt) -> (amount : felt):
    let (resource_concentration) = get_resource_concentration_at_grid (grid, resource_type)

    # reserving `multipler` for the need to adjust linearly the harvesting rate
    let multiplier = 1
    return (amount = resource_concentration * multiplier)
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
    member tethered_to_utl : felt
    member tethered_to_utb : felt
    member utl_label : felt
    member utb_label : felt
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

# harvester-type device-id to resource-balance lookup; for simplicity, device-id uniquely identifies resource type harvested
@storage_var
func harvesters_deployed_id_to_resource_balance (id : felt) -> (balance : felt):
end

@storage_var
func transformers_deployed_id_to_resource_balances (id : felt) -> (balances : TransformerResourceBalances):
end

@storage_var
func opsf_deployed_id_to_resource_balances (id : felt, element_type : felt) -> (balance : felt):
end

@storage_var
func opsf_deployed_id_to_device_balances (id : felt, device_type : felt) -> (balance : felt):
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

    #
    # Check 1x1
    #
    let (grid_stat_0_0) = grid_stats.read (grid)
    assert grid_stat_0_0.populated = 0

    if device_dim == 1:
        return ()
    end

    let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)

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
        tethered_to_utl = 0,
        tethered_to_utb = 0,
        utl_label = 0,
        utb_label = 0
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
        Vec2(0,0), 0, 0, 0, 0, 0, 0
    ))
    device_deployed_emap.write (emap_index, emap_entry_last)
    let grid_0_0 = emap_entry.grid
    let type = emap_entry.type

    #
    # Untether utb/utl if tethered;
    # use `emap_entry.utb_label/utl_label` to find emap-entry of the utb-set/utl-set,
    # and unregister src/dst device from it (set device id to 0, assuming 0 does not correspond to some meaning device id)
    #
    if emap_entry.tethered_to_utb == 0:
        jmp update_devices
    end

    let (utb_set_emap_index) = utb_set_deployed_label_to_emap_index.read (emap_entry.utb_label)
    let (utb_set_emap_entry) = utb_set_deployed_emap.read (utb_set_emap_index)
    let (is_src_device) = is_zero (utb_set_emap_entry.src_device_id - grid_stat.deployed_device_id)
    let (is_dst_device) = is_zero (utb_set_emap_entry.dst_device_id - grid_stat.deployed_device_id)
    let new_src_device_id = (1-is_src_device) * utb_set_emap_entry.src_device_id
    let new_dst_device_id = (1-is_dst_device) * utb_set_emap_entry.dst_device_id

    utb_set_deployed_emap.write (utb_set_emap_index, UtbSetDeployedEmapEntry(
        utb_set_deployed_label = utb_set_emap_entry.utb_set_deployed_label,
        utb_deployed_index_start = utb_set_emap_entry.utb_deployed_index_start,
        utb_deployed_index_end = utb_set_emap_entry.utb_deployed_index_end,
        src_device_id = new_src_device_id,
        dst_device_id = new_dst_device_id
    ))

    # TODO: come back to implement for utl below
    # if emap_entry.tethered_to_utl:
    # end

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
    if bool_is_harvester == 1:
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
## utb
##############################

#
# utb is fungible before deployment, but non-fungible after deployment,
# because they are deployed as a spatially-contiguous set with the same label,
# where contiguity is defined by the coordinate system on the cube surface;
# they are also deployed exclusively to connect their src & dst devices that meet
# the resource producer-consumer relationship.
#

#
# Use enumerable map (Emap) to maintain the an array of (set label, utb index start, utb index end)
# credit to Peteris at yagi.fi
#
struct UtbSetDeployedEmapEntry:
    member utb_set_deployed_label : felt
    member utb_deployed_index_start : felt
    member utb_deployed_index_end : felt
    member src_device_id : felt
    member dst_device_id : felt
end

@storage_var
func utb_set_deployed_emap_size () -> (size : felt):
end

@storage_var
func utb_set_deployed_emap (emap_index : felt) -> (emap_entry : UtbSetDeployedEmapEntry):
end

# for quick reverse lookup (utb-set label to emap-index)
@storage_var
func utb_set_deployed_label_to_emap_index (label : felt) -> (emap_index : felt):
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
    let (local owned_utb_amount) = device_undeployed_ledger.read (caller, ns_device_types.DEVICE_UTB)
    assert_le (locs_len, owned_utb_amount)

    #
    # Check if caller owns src and dst device
    #
    let (src_grid_stat) = grid_stats.read (src_device_grid)
    let (dst_grid_stat) = grid_stats.read (dst_device_grid)
    assert src_grid_stat.populated = 1
    assert dst_grid_stat.populated = 1
    assert src_grid_stat.deployed_device_owner = caller
    assert dst_grid_stat.deployed_device_owner = caller

    #
    # Check src and dst device are untethered to utb
    #
    let src_device_id = src_grid_stat.deployed_device_id
    let dst_device_id = dst_grid_stat.deployed_device_id
    let (src_emap_index) = device_deployed_id_to_emap_index.read (src_device_id)
    let (dst_emap_index) = device_deployed_id_to_emap_index.read (dst_device_id)
    let (src_emap_entry) = device_deployed_emap.read (src_emap_index)
    let (dst_emap_entry) = device_deployed_emap.read (dst_emap_index)
    assert src_emap_entry.tethered_to_utb = 0
    assert dst_emap_entry.tethered_to_utb = 0

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
    tempvar data_ptr : felt* = new (3, caller, utb_idx_start, utb_idx_end)
    let (new_label) = hash_chain {hash_ptr = pedersen_ptr} (data_ptr)
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
    device_undeployed_ledger.write (caller, ns_device_types.DEVICE_UTB, owned_utb_amount - locs_len)

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
        utb_deployed_index_end = utb_idx_end,
        src_device_id = src_device_id,
        dst_device_id = dst_device_id
    ))
    utb_set_deployed_emap_size.write (emap_size + 1)

    #
    # Update label-to-index for O(1) reverse lookup
    #
    utb_set_deployed_label_to_emap_index.write (new_label, emap_size)


    #
    # Update device emap entries for src and dst device
    #
    let (src_emap_index) = device_deployed_id_to_emap_index.read (src_device_id)
    device_deployed_emap.write (src_emap_index, DeviceDeployedEmapEntry(
        grid = src_emap_entry.grid,
        type = src_emap_entry.type,
        id = src_emap_entry.id,
        tethered_to_utl = src_emap_entry.tethered_to_utl,
        tethered_to_utb = 1,
        utl_label = src_emap_entry.utl_label,
        utb_label = new_label
    ))

    let (dst_emap_index) = device_deployed_id_to_emap_index.read (dst_device_id)
    device_deployed_emap.write (dst_emap_index, DeviceDeployedEmapEntry(
        grid = dst_emap_entry.grid,
        type = dst_emap_entry.type,
        id = dst_emap_entry.id,
        tethered_to_utl = dst_emap_entry.tethered_to_utl,
        tethered_to_utb = 1,
        utl_label = dst_emap_entry.utl_label,
        utb_label = new_label
    ))

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
        deployed_device_id = set_label,
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
    let utb_set_deployed_label = grid_stat.deployed_device_id

    #
    # O(1) find the emap_entry for this utb-set
    #
    let (emap_size_curr) = utb_set_deployed_emap_size.read ()
    let (emap_index) = utb_set_deployed_label_to_emap_index.read (utb_set_deployed_label)
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
    let (amount_curr) = device_undeployed_ledger.read (caller, ns_device_types.DEVICE_UTB)
    device_undeployed_ledger.write (caller, ns_device_types.DEVICE_UTB, amount_curr + utb_end_index - utb_start_index)

    #
    # Update enumerable map of utb-sets:
    # removal operation - put last entry to index at removed entry, clear index at last entry,
    # and decrease emap size by one
    #
    let (emap_entry_last) = utb_set_deployed_emap.read (emap_size_curr - 1)
    utb_set_deployed_emap.write (emap_index, emap_entry_last)
    utb_set_deployed_emap.write (emap_size_curr - 1, UtbSetDeployedEmapEntry (0,0,0,0,0))
    utb_set_deployed_emap_size.write (emap_size_curr - 1)

    #
    # Update the tethered src and dst device info as well
    #
    let src_device_id = emap_entry.src_device_id
    let dst_device_id = emap_entry.dst_device_id
    let (src_emap_index) = device_deployed_id_to_emap_index.read (src_device_id)
    let (dst_emap_index) = device_deployed_id_to_emap_index.read (dst_device_id)
    let (src_emap_entry) = device_deployed_emap.read (src_emap_index)
    let (dst_emap_entry) = device_deployed_emap.read (dst_emap_index)

    device_deployed_emap.write (src_emap_index, DeviceDeployedEmapEntry(
        grid = src_emap_entry.grid,
        type = src_emap_entry.type,
        id = src_emap_entry.id,
        tethered_to_utl = src_emap_entry.tethered_to_utl,
        tethered_to_utb = 0,
        utl_label = src_emap_entry.utl_label,
        utb_label = 0
    ))

    device_deployed_emap.write (dst_emap_index, DeviceDeployedEmapEntry(
        grid = dst_emap_entry.grid,
        type = dst_emap_entry.type,
        id = dst_emap_entry.id,
        tethered_to_utl = dst_emap_entry.tethered_to_utl,
        tethered_to_utb = 0,
        utl_label = dst_emap_entry.utl_label,
        utb_label = 0
    ))

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

#
# Tether utb-set to src and device manually;
# useful when player retethers a deployed utb-set to new devices
# and wishes to avoid picking up and deploying utb-set again
#
func utb_tether_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utb_grid : Vec2,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    with_attr error_message ("Not implemented."):
        assert 1 = 0
    end

    return ()
end

##############################

func are_resource_producer_consumer_relationship {range_check_ptr} (
    device_type0, device_type1) -> ():

    # TODO: refactor this code to improve extensibility

    alloc_locals
    local x = device_type0
    local y = device_type1

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

    with_attr error_message("resource producer-consumer relationship check failed, with device_type0 = {x} and device_type1 = {y}"):
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

func resource_update_at_devices {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    let (emap_size) = device_deployed_emap_size.read ()
    recurse_resource_update_at_devices (
        len = emap_size,
        idx = 0
    )

    return ()
end

func recurse_resource_update_at_devices {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
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
    # For harvester => increase resource based on resource concentration at land # TODO: use energy to boost harvest rate
    #
    handle_harvester:
    if bool_is_harvester == 1:
        let (element_type) = harvester_device_type_to_element_type (emap_entry.type)
        let (amount_harvested) = get_resource_harvest_amount_at_grid (emap_entry.grid, element_type)
        let (amount_curr) = harvesters_deployed_id_to_resource_balance.read (emap_entry.id)
        harvesters_deployed_id_to_resource_balance.write (
            emap_entry.id,
            amount_curr + amount_harvested
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
    handle_transformer:
    local syscall_ptr : felt* = syscall_ptr
    local pedersen_ptr : HashBuiltin* = pedersen_ptr
    local range_check_ptr = range_check_ptr
    if bool_is_transformer == 1:
        let (element_type_raw, element_type_transformed) = transformer_device_type_to_element_types (emap_entry.type)
        ## TODO: design transform rate per element type
        let (balances) = transformers_deployed_id_to_resource_balances.read (emap_entry.id)
        let (bool_can_transform_resource) = transformer_has_resource_to_transform (emap_entry.type, balances)

        if bool_can_transform_resource == 1:
            transformers_deployed_id_to_resource_balances.write (
                emap_entry.id,
                TransformerResourceBalances (
                    balances.balance_resource_before_transform - 1,
                    balances.balance_resource_after_transform + 1,
                )
            )
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    recurse:
    recurse_resource_update_at_devices (len, idx + 1)

    return ()
end

## TODO
func transformer_has_resource_to_transform {range_check_ptr} (
        device_type : felt,
        balances : TransformerResourceBalances
    ) -> (bool : felt):

    if balances.balance_resource_before_transform != 0:
        return (1)
    end

    return (0)

    # (reference)
    # TransformerResourceBalances:
    #   member balance_resource_before_transform : felt
    #   member balance_resource_after_transform : felt
    # end
end

func resource_transfer_across_utb_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    #
    # recursively traverse `utb_set_deployed_emap`
    #
    let (emap_size) = utb_set_deployed_emap_size.read ()
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
    let (emap_entry) = utb_set_deployed_emap.read (idx)
    let (is_src_tethered) = is_not_zero (emap_entry.src_device_id)
    let (is_dst_tethered) = is_not_zero (emap_entry.dst_device_id)
    if is_src_tethered * is_dst_tethered == 1:
        #
        # Transport resource src => dst
        #
        let (emap_index_src) = device_deployed_id_to_emap_index.read (emap_entry.src_device_id)
        let (emap_entry_src) = device_deployed_emap.read (emap_index_src)
        let (emap_index_dst) = device_deployed_id_to_emap_index.read (emap_entry.dst_device_id)
        let (emap_entry_dst) = device_deployed_emap.read (emap_index_dst)
        let src_type = emap_entry_src.type
        let dst_type = emap_entry_dst.type
        let (bool_src_harvester) = is_device_harvester (src_type)
        let (bool_dst_opsf) = is_device_opsf (dst_type)

        local transport_amount
        local element_type
        if bool_src_harvester == 1:
            # src device is harvester
            let (element_type_) = harvester_device_type_to_element_type (src_type)
            assert element_type = element_type_
            assert transport_amount = 1
            let (src_balance) = harvesters_deployed_id_to_resource_balance.read (emap_entry.src_device_id)
            harvesters_deployed_id_to_resource_balance.write (emap_entry.src_device_id, src_balance - transport_amount)

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            # src device is transformer; transporting `element_type_after_transform`
            let (_, element_type_) = transformer_device_type_to_element_types (src_type)
            assert element_type = element_type_
            assert transport_amount = 1
            let (src_balances) = transformers_deployed_id_to_resource_balances.read (emap_entry.src_device_id)
            transformers_deployed_id_to_resource_balances.write (emap_entry.src_device_id, TransformerResourceBalances(
                balance_resource_before_transform = src_balances.balance_resource_before_transform,
                balance_resource_after_transform = src_balances.balance_resource_after_transform - transport_amount
            ))

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        if bool_dst_opsf == 1:
            # dst device is OPSF
            let (dst_balance) = opsf_deployed_id_to_resource_balances.read (emap_entry.dst_device_id, element_type)
            opsf_deployed_id_to_resource_balances.write (emap_entry.dst_device_id, element_type, dst_balance + transport_amount)

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            # dst device is transformer
            let (dst_balances) = transformers_deployed_id_to_resource_balances.read (emap_entry.dst_device_id)
            transformers_deployed_id_to_resource_balances.write (emap_entry.dst_device_id, TransformerResourceBalances(
                balance_resource_before_transform = dst_balances.balance_resource_before_transform + transport_amount,
                balance_resource_after_transform = dst_balances.balance_resource_after_transform
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


func forward_world_micro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    #
    # Effect resource update at device;
    # akin to propagating D->Q for FFs
    #
    resource_update_at_devices ()

    #
    # Effect resource transfer across deployed utb-sets;
    # akin to propagating values through wires
    #
    resource_transfer_across_utb_sets ()

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
func mock_utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
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

    utb_deploy (
        caller,
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
func mock_utb_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid_x : felt,
        grid_y : felt
    ) -> ():

    utb_pickup_by_grid (
        caller,
        Vec2 (grid_x, grid_y)
    )

    return ()
end


@external
func mock_utb_tether_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utb_grid : Vec2,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    utb_tether_by_grid (
        caller,
        utb_grid,
        src_device_grid,
        dst_device_grid
    )

    return ()
end


@external
func mock_are_resource_producer_consumer_relationship {range_check_ptr} (
    device_type0, device_type1) -> ():

    are_resource_producer_consumer_relationship (
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
func admin_read_utb_set_deployed_emap_size {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (size : felt):
    let (size) = utb_set_deployed_emap_size.read ()
    return (size)
end

@view
func admin_read_utb_set_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    emap_index : felt) -> (emap_entry : UtbSetDeployedEmapEntry):
    let (emap_entry) = utb_set_deployed_emap.read (emap_index)
    return (emap_entry)
end

@view
func admin_read_utb_set_deployed_label_to_emap_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    label : felt) -> (emap_index : felt):
    let (emap_index) = utb_set_deployed_label_to_emap_index.read (label)
    return (emap_index)
end

@view
func admin_read_utb_deployed_index_to_grid_size {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (size : felt):
    let (size) = utb_deployed_index_to_grid_size.read ()
    return (size)
end

@view
func admin_read_utb_deployed_index_to_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    index : felt) -> (grid : Vec2):
    let (grid) = utb_deployed_index_to_grid.read (index)
    return (grid)
end