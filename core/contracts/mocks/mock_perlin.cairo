%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.util.structs import (Vec2)
from contracts.util.perlin import (
    fade
)

@view
func mock_fade {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        t : felt
    ) -> (
        res : felt
    ):

    let (res) = fade (t)

    return (res)
end
