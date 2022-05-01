%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

#
# Import constants and structs
#
from contracts.design.constants import (
    GYOZA, MIN_L2_BLOCK_NUM_BETWEEN_FORWARD,
    ns_macro_init
)
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)

#
# Import functions / namespaces for macro world
# TODO: extract macro state from this contract to `macro_state.cairo`
#
from contracts.macro import (forward_world_macro)

#
# Import states / functions / namespaces for micro world
#
from contracts.micro.micro_state import (ns_micro_state_functions, DeviceDeployedEmapEntry, UtxSetDeployedEmapEntry)
from contracts.micro.micro_devices import (ns_micro_devices)
from contracts.micro.micro_utx import (ns_micro_utx)
from contracts.micro.micro_forwarding import (ns_micro_forwarding)
from contracts.micro.micro_iterator import (ns_micro_iterator)

# from contracts.micro import (
#     device_deploy, device_pickup_by_grid,
#     utx_deploy, utx_pickup_by_grid, forward_world_micro,
#     iterate_device_deployed_emap, DeviceDeployedEmapEntry,
#     iterate_utx_deployed_emap, UtxSetDeployedEmapEntry,
#     iterate_utx_deployed_emap_grab_all_utxs,
#     opsf_build_device
# )


##############################

#
# For yagi automation
#
@view
func yagiProbeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):

    let (_, bool) = can_forward_world ()

    return (bool)
end

@external
func yagiExecuteTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    client_forward_world ()

    return ()
end

##############################

@storage_var
func l2_block_at_last_forward () -> (block_num : felt):
end

@view
func client_view_l2_block_at_last_forward {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (block_num : felt):

    let (block_num) = l2_block_at_last_forward.read ()

    return (block_num)
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

    #
    # Initialize macro world - trisolar system placement & planet rotation
    #
    macro_state_curr.write (Dynamics(
        sun0 = Dynamic(
            q = Vec2(
                x = ns_macro_init.sun0_qx,
                y = ns_macro_init.sun0_qy
            ),
            qd = Vec2(
                x = ns_macro_init.sun0_px,
                y = ns_macro_init.sun0_py
            )
        ),
        sun1 = Dynamic(
            q = Vec2(
                x = ns_macro_init.sun1_qx,
                y = ns_macro_init.sun1_qy
            ),
            qd = Vec2(
                x = ns_macro_init.sun1_px,
                y = ns_macro_init.sun1_py
            )
        ),
        sun2 = Dynamic(
            q = Vec2(
                x = ns_macro_init.sun2_qx,
                y = ns_macro_init.sun2_qy
            ),
            qd = Vec2(
                x = ns_macro_init.sun2_px,
                y = ns_macro_init.sun2_py
            )
        ),
        plnt = Dynamic(
            q = Vec2(
                x = ns_macro_init.plnt_qx,
                y = ns_macro_init.plnt_qy
            ),
            qd = Vec2(
                x = ns_macro_init.plnt_px,
                y = ns_macro_init.plnt_py
            )
        )
    ))

    phi_curr.write (ns_macro_init.phi)

    #
    # TODO: initialize mini world - determining the seed for resource distribution function
    #


    #
    # Record L2 block at reality genesis
    #
    let (block) = get_block_number ()
    l2_block_at_last_forward.write (block)

    return()
end

##############################

#
# phi: the spin orientation of the planet in the trisolar coordinate system;
# spin axis perpendicular to the plane of orbital motion
#
@storage_var
func phi_curr () -> (phi : felt):
end

@storage_var
func macro_state_curr () -> (macro_state : Dynamics):
end

@view
func view_phi_curr {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (phi : felt):
    let (phi) = phi_curr.read ()
    return (phi)
end

@view
func view_macro_state_curr {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (macro_state : Dynamics):
    let (macro_state) = macro_state_curr.read ()
    return (macro_state)
end

func can_forward_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (block_curr : felt, bool : felt):
    alloc_locals

    #
    # At least MIN_L2_BLOCK_NUM_BETWEEN_FORWARD between last-update block and current block
    #
    let (block_curr) = get_block_number ()
    let (block_last) = l2_block_at_last_forward.read ()
    let block_diff = block_curr - block_last
    let (bool) = is_le (MIN_L2_BLOCK_NUM_BETWEEN_FORWARD, block_diff)

    return (block_curr, bool)
end

func client_forward_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Permission control (removed; allowing any third party to trigger world-forwarding for maximum availability)
    #
    # let (caller) = get_caller_address ()
    # with_attr error_message ("Isaac currently operates under gyoza the benevolent dictator. Only gyoza can tick Isaac forward."):
    #     assert caller = GYOZA
    # end

    #
    # Confirm world can be forwarded now
    #
    let (block_curr, bool) = can_forward_world ()
    local min_dist = MIN_L2_BLOCK_NUM_BETWEEN_FORWARD
    with_attr error_message("last-update block must be at least {min_dist} block away from current block."):
        assert bool = 1
    end
    l2_block_at_last_forward.write (block_curr)

    #
    # Forward macro world - orbital positions of trisolar system, and spin orientation of planet
    #
    let (macro_state : Dynamics) = macro_state_curr.read ()
    let (phi : felt) = phi_curr.read ()

    let (
        macro_state_nxt : Dynamics,
        phi_nxt : felt
    ) = forward_world_macro (macro_state, phi)

    macro_state_curr.write (macro_state_nxt)
    phi_curr.write (phi_nxt)

    #
    # Forward micro world - all activities on the surface of the planet
    #
    ns_micro_forwarding.forward_world_micro ()

    return ()
end

##############################

#
# Exposing functions for state-changing operations in micro world
#

@external
func client_deploy_device_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    type : felt, grid : Vec2) -> ():

    let (caller) = get_caller_address ()

    ns_micro_devices.device_deploy (caller, type, grid)

    return ()
end

@external
func client_pickup_device_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    grid : Vec2) -> ():

    let (caller) = get_caller_address ()

    ns_micro_devices.device_pickup_by_grid (caller, grid)

    return ()
end

@external
func client_deploy_utx_by_grids {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        src_device_grid : Vec2,
        dst_device_grid : Vec2,
        locs_len : felt,
        locs : Vec2*
    ) -> ():

    let (caller) = get_caller_address ()

    ns_micro_utx.utx_deploy (
        caller,
        utx_device_type,
        locs_len,
        locs,
        src_device_grid,
        dst_device_grid
    )

    return ()
end

@external
func client_pickup_utx_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    grid : Vec2) -> ():

    let (caller) = get_caller_address ()

    ns_micro_utx.utx_pickup_by_grid (caller, grid)

    return ()
end

@external
func client_opsf_build_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2,
        device_type : felt,
        device_count : felt
    ) -> ():

    let (caller) = get_caller_address ()

    ns_micro_devices.opsf_build_device (
        caller,
        grid,
        device_type,
        device_count
    )

    return ()
end

#
# State-changing functions with input arguments flattened (no struct) for testing purposes
#

@external
func flat_device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        type : felt,
        grid_x : felt,
        grid_y : felt
    ) -> ():

    client_deploy_device_by_grid (
        type,
        Vec2 (grid_x, grid_y)
    )

    return ()
end


@external
func flat_device_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid_x : felt,
        grid_y : felt
    ) -> ():
    alloc_locals

    client_pickup_device_by_grid (
        Vec2 (grid_x, grid_y)
    )

    return ()
end


@external
func flat_utx_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        src_device_grid_x : felt,
        src_device_grid_y : felt,
        dst_device_grid_x : felt,
        dst_device_grid_y : felt,
        locs_x_len : felt,
        locs_x : felt*,
        locs_y_len : felt,
        locs_y : felt*
    ) -> ():
    alloc_locals

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

    client_deploy_utx_by_grids (
        utx_device_type,
        Vec2 (src_device_grid_x, src_device_grid_y),
        Vec2 (dst_device_grid_x, dst_device_grid_y),
        locs_len,
        locs
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
func flat_utx_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid_x : felt,
        grid_y : felt
    ) -> ():

    client_pickup_utx_by_grid (
        Vec2 (grid_x, grid_y)
    )

    return ()
end

@external
func flat_opsf_build_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid_x : felt,
        grid_y : felt,
        device_type : felt,
        device_count : felt
    ) -> ():

    client_opsf_build_device (
        Vec2 (grid_x, grid_y),
        device_type,
        device_count
    )

    return ()
end

#
# Exposing iterator functions for observing the micro world
#

@view
func client_view_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (
        emap_len : felt,
        emap : DeviceDeployedEmapEntry*
    ):

    let (emap_len, emap) = ns_micro_iterator.iterate_device_deployed_emap ()

    return (emap_len, emap)
end

@view
func client_view_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        emap_len : felt,
        emap : UtxSetDeployedEmapEntry*
    ):

    let (emap_len, emap) = ns_micro_iterator.iterate_utx_deployed_emap (utx_device_type)

    return (emap_len, emap)
end

@view
func client_view_all_utx_grids {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        grids_len : felt,
        grids : Vec2*
    ):

    let (grids_len, grids) = ns_micro_iterator.iterate_utx_deployed_emap_grab_all_utxs (utx_device_type)

    return (grids_len, grids)
end

#
# Admin functions
#

@external
func admin_give_undeployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    to : felt, type : felt, amount : felt):

    #
    # Confirm admin identity
    #
    # let (caller) = get_caller_address ()
    # with_attr error_message ("Only admin can invoke this function."):
    #     assert caller = GYOZA
    # end

    #
    # Give device
    #
    ns_micro_state_functions.device_undeployed_ledger_write (to, type, amount)

    return ()
end


@external
func admin_write_opsf_deployed_id_to_resource_balances {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt, element_type : felt, balance : felt):

    #
    # Confirm admin identity
    #
    # let (caller) = get_caller_address ()
    # with_attr error_message ("Only admin can invoke this function."):
    #     assert caller = GYOZA
    # end

    ns_micro_state_functions.opsf_deployed_id_to_resource_balances_write (id, element_type, balance)

    return ()
end

@external
func admin_write_device_deployed_id_to_energy_balance {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt, energy : felt):

    #
    # Confirm admin identity
    #
    # let (caller) = get_caller_address ()
    # with_attr error_message ("Only admin can invoke this function."):
    #     assert caller = GYOZA
    # end

    ns_micro_state_functions.device_deployed_id_to_energy_balance_write (id, energy)

    return ()
end



