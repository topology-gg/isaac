%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from design.constants import (GYOZA)
from contracts.macro import (forward_world_macro)
from contracts.micro import (
    device_deploy, device_pickup_by_grid,
    utb_deploy, utb_pickup_by_grid, forward_world_micro,
    iterate_device_deployed_emap, DeviceDeployedEmapEntry
)
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)

##############################

@storage_var
func last_l2_block () -> (block_num : felt):
end

@storage_var
func micro_contract_address () -> (addr : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        # micro_contract_addr : felt
    ):

    #
    # Initialize macro world - trisolar system placement & planet rotation
    #
    macro_state_curr.write (Dynamics(
        sun0 = Dynamic(
            q = Vec2(
                x = 7186568302368001097728,
                y = 3618502788666131213697322783095070105623107215331596698172105163871871827969
            ),
            qd = Vec2(
                x=95543324142078754816,
                y=88608606963963625472
            )
        ),
        sun1 = Dynamic(
            q = Vec2(
                x = 3618502788666131213697322783095070105623107215331596692786523753767870922753,
                y = 1800986892264000192512
            ),
            qd = Vec2(
                x = 95543324142078754816,
                y = 88608606963963625472
            )
        ),
        sun2 = Dynamic(
            q = Vec2(x = 0, y = 0),
            qd = Vec2(
                x = 3618502788666131213697322783095070105623107215331596699782005407851714510849,
                y = 3618502788666131213697322783095070105623107215331596699795874842207944769537
            )
        ),
        plnt = Dynamic(
            q = Vec2(
                x = 3593284151184000548864,
                y = 3618502788666131213697322783095070105623107215331596699072598610003871924225
            ),
            qd = Vec2(
                x = 3618502788666131213697322783095070105623107215331596699899597191411196059649,
                y = 3618502788666131213697322783095070105623107215331596699904931589240515387393
            )
        )
    ))

    phi_curr.write (0)

    #
    # TODO: initialize mini world - determining the seed for resource distribution function
    #


    #
    # Record L2 block at reality genesis
    #
    let (block) = get_block_number ()
    last_l2_block.write (block)

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

@external
func client_forward_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    with_attr error_message ("Isaac currently operates under gyoza the benevolent dictator. Only gyoza can tick Isaac forward."):
        assert caller = GYOZA
    end

    #
    # Make sure only one L2 block has passed
    # TODO: allow fast-foward >1 L2 blocks in case of unexpected network / yagi issues
    #
    # let (block_curr) = get_block_number ()
    # let (block_last) = last_l2_block.read ()
    # let block_diff = block_curr - block_last
    # with_attr error_message("last block must be exactly one block away from current block."):
    #     assert block_diff = 1
    # end

    #
    # Forward macro world - orbital positions of trisolar system, and spin orientation of planet
    # TODO: allow fast-foward >1 DT, requiring recursive calls to forward_world_macro ()
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
func client_deploy_utb_by_grids {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        locs_len : felt,
        locs : Vec2*,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    let (caller) = get_caller_address ()

    utb_deploy (
        caller,
        locs_len,
        locs,
        src_device_grid,
        dst_device_grid
    )

    return ()
end

@external
func client_pickup_utb_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    grid : Vec2) -> ():

    let (caller) = get_caller_address ()

    utb_pickup_by_grid (caller, grid)

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
