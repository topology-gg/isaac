%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.util.structs import (Vec2)
from contracts.util.distribution import (
    get_adjusted_perlin_value
)

@view
func mock_get_adjusted_perlin_value {syscall_ptr : felt*, range_check_ptr} (
        face : felt, grid : Vec2, element_type : felt
    ) -> (res : felt):

    let (res) = get_adjusted_perlin_value (face, grid, element_type)

    return (res)
end


# @view
# func mock_get_perlin_value {syscall_ptr : felt*, range_check_ptr} (
#         face : felt, grid : Vec2
#     ) -> (res : felt):

#     let (res) = get_perlin_value (face, grid)

#     return (res)
# end
