%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    GYOZA, MIN_L2_BLOCK_NUM_BETWEEN_FORWARD,
    ns_macro_init
)
from contracts.macro import (forward_world_macro)
from contracts.micro import (
    device_deploy, device_pickup_by_grid,
    utx_deploy, utx_pickup_by_grid, forward_world_micro,
    iterate_device_deployed_emap, DeviceDeployedEmapEntry,
    iterate_utx_deployed_emap, UtxSetDeployedEmapEntry,
    iterate_utx_deployed_emap_grab_all_utxs
)
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)

##############################

#
# For yagi automation
#
@view
func probeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):

    let (_, bool) = can_forward_world ()

    return (bool)
end

@external
func executeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
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
    forward_world_micro ()

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

    device_deploy (caller, type, grid)

    return ()
end

@external
func client_pickup_device_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    grid : Vec2) -> ():

    let (caller) = get_caller_address ()

    device_pickup_by_grid (caller, grid)

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

    utx_deploy (
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

    utx_pickup_by_grid (caller, grid)

    return ()
end

#
# Exposing functions for observing the micro world
#

@view
func client_view_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (
        emap_len : felt,
        emap : DeviceDeployedEmapEntry*
    ):

    let (emap_len, emap) = iterate_device_deployed_emap ()

    return (emap_len, emap)
end


@view
func client_view_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        emap_len : felt,
        emap : UtxSetDeployedEmapEntry*
    ):

    let (emap_len, emap) = iterate_utx_deployed_emap (utx_device_type)

    return (emap_len, emap)
end

@view
func client_view_all_utx_grids {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        grids_len : felt,
        grids : Vec2*
    ):

    let (grids_len, grids) = iterate_utx_deployed_emap_grab_all_utxs (utx_device_type)

    return (grids_len, grids)
end