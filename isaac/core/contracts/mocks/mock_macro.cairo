%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)
from contracts.macro.macro_simulation import forward_world_macro, rk4, forward_planet_spin, differentiate
from contracts.macro.macro_state import ns_macro_state_functions
from contracts.design.constants import ns_macro_init

@event
func macro_state_event (dynamics : Dynamics):
end

@external
func forward_macro_sequentially {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        len : felt
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    mock_forward_world_macro ()

    let (dynamics) = ns_macro_state_functions.macro_state_curr_read ()
    macro_state_event.emit (dynamics)

    forward_macro_sequentially (
        idx + 1,
        len
    )
    return ()
end

@external
func mock_forward_world_macro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    forward_world_macro ()

    return ()
end

@external
func reset_macro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Reset macro world - trisolar system placement & planet rotation
    #
    let (macro_initial_state) = get_macro_initial_state ()
    ns_macro_state_functions.macro_state_curr_write (macro_initial_state)
    ns_macro_state_functions.phi_curr_write (ns_macro_init.phi)

    return ()
end

@external
func mock_forward_planet_spin {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        phi_fp : felt
    ) -> (
        phi_fp_nxt : felt
    ):
    alloc_locals

    let (phi_fp_nxt) = forward_planet_spin (phi_fp)

    return (phi_fp_nxt)
end

@external
func mock_rk4 {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        dt : felt,
        state : Dynamics
    ) -> (
        state_nxt : Dynamics
    ):
    alloc_locals

    let (state_nxt) = rk4 (dt, state)

    return (state_nxt)
end

@external
func mock_differentiate {syscall_ptr : felt*, range_check_ptr} (
        state : Dynamics
    ) -> (
        state_diff : Dynamics
    ):

    let (state_diff) = differentiate (state)

    return (state_diff)
end

func get_macro_initial_state {} () -> (dynamics : Dynamics):
    return (Dynamics(
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
end