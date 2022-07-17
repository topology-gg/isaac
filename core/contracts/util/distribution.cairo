%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem, unsigned_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    PLANET_DIM, SCALE_FP, SCALE_FP_DIV_100, RANGE_CHECK_BOUND,
    ns_perlin
)
from contracts.util.structs import (
    Vec2
)
from contracts.util.perlin import (
    get_perlin_value
)
from contracts.util.grid import (
    locate_face_and_edge_given_valid_grid
)
from contracts.util.numerics import (mul_fp)

namespace ns_distribution:

    @view
    func get_concentration_at_grid_given_element_type {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            grid : Vec2,
            element_type : felt
        ) -> (
            res : felt
        ):

        let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)

        let (res) = get_adjusted_perlin_value (
            face,
            grid,
            element_type
        )

        return (res)
    end

end

func get_adjusted_perlin_value {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        face : felt,
        grid : Vec2,
        element_type : felt
    ) -> (
        res : felt
    ):
    alloc_locals

    #
    # Get offset for given element_type
    #
    let (offset) = ns_perlin.get_offset (element_type)

    #
    # Get perlin value in fp
    #
    let (value_fp) = get_perlin_value (
        face,
        grid,
        element_type
    )

    #
    # Adjust value for given scaler and offset derived from `element_type`
    #
    let (res) = adjust (
        value_fp,
        offset
    )

    return (res)
end


func adjust {range_check_ptr} (
        x_fp : felt,
        offset : felt
    ) -> (
        res : felt
    ):

    #
    # adjust = lambda x : math.floor ( (x + offset)**2 )
    #
    let (res_fp) = mul_fp (
        x_fp + offset * SCALE_FP,
        x_fp + offset * SCALE_FP
    )

    #
    # return to non-fp regime
    #
    let (res, _) = unsigned_div_rem (res_fp, SCALE_FP)

    return (res)
end
