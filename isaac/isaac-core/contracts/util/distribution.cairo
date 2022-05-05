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

namespace ns_distribution:
    func get_concentration_at_grid_given_element_type {syscall_ptr : felt*, range_check_ptr} (
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

func get_adjusted_perlin_value {syscall_ptr : felt*, range_check_ptr} (
        face : felt, grid : Vec2, element_type : felt
    ) -> (res : felt):
    alloc_locals

    #
    # Get params for given `element_type
    #
    let (
        face_permut_offset,
        scaler,
        offset
    ) = ns_perlin.get_params (
        element_type
    )

    #
    # Get permuted face
    #
    let (permuated_face, _) = unsigned_div_rem (face + face_permut_offset, 6)

    #
    # Get perlin value
    #
    let (value) = get_perlin_value (
        face,
        permuated_face,
        grid
    )

    #
    # Adjust value for given scaler and offset derived from `element_type`
    #
    let (res) = adjust (
        x = value,
        scaler = scaler,
        offset = offset
    )

    return (res)
end


func adjust {range_check_ptr} (
        x : felt,
        scaler : felt,
        offset : felt
    ) -> (res : felt):

    #
    # adjust = lambda x : relu (x - offset) * scaler
    #

    let (nn) = is_nn (x - offset)

    if nn == 0:
        return (0)
    else:
        let (res, _) = signed_div_rem (x * scaler, SCALE_FP, RANGE_CHECK_BOUND)
        return (res)
    end
end
