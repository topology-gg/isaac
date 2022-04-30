%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.util.structs import (
    Vec2
)

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
func mock_opsf_build_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid_x : felt,
        grid_y : felt,
        device_type : felt,
        device_count : felt
    ) -> ():

    opsf_build_device (caller, Vec2(grid_x, grid_y), device_type, device_count)

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

@external
func admin_write_opsf_deployed_id_to_resource_balances {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt, element_type : felt, balance : felt) -> ():
    opsf_deployed_id_to_resource_balances.write (id, element_type, balance)
    return ()
end

@view
func admin_read_device_deployed_id_to_energy_balance {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt) -> (energy : felt):
    let (energy) = device_deployed_id_to_energy_balance.read (id)
    return (energy)
end

@external
func admin_write_device_deployed_id_to_energy_balance {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt, energy : felt) -> ():
    device_deployed_id_to_energy_balance.write (id, energy)
    return ()
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
