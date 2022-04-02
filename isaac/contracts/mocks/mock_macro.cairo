%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)
from contracts.macro import (
    forward_world_macro,
    differentiate
)

@external
func mock_forward_world_macro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        state : Dynamics,
        phi : felt
    ) -> (
        state_nxt : Dynamics,
        phi_nxt : felt
    ):

    let (state_nxt, phi_nxt) = forward_world_macro (state, phi)

    return (state_nxt, phi_nxt)
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