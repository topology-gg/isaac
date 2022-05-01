%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)
from contracts.macro.macro_simulation import (
    rk4, forward_planet_spin
)

@external
func mock_rk4 {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        dt : felt,
        state : Dynamics
    ) -> (
        state_nxt : Dynamics
    ):

    let (state_nxt) = rk4 (dt, state)

    return (state_nxt)
end


@external
func mock_forward_planet_spin {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        phi : felt
    ) -> (
        phi_nxt : felt
    ):

    let (phi_nxt) = forward_planet_spin (phi)

    return (phi_nxt)
end

