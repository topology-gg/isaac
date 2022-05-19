%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le, sign)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    SCALE_FP,
    ns_ndpe_impulse_function
)
from contracts.util.structs import (
    Vec2, Dynamics
)
from contracts.macro.macro_simulation import (
    mul_fp, div_fp, div_fp_ul, sqrt_fp
)

##############################

func compute_impulse_in_micro_coord {range_check_ptr} (
        energy_consumed : felt,
        face : felt
    ) -> (
        impulse_fp : Vec2
    ):
    alloc_locals

    #
    # If face is top (3) or bottom (1), return 0 impulse
    #
    if face == 3:
        return ( Vec2(0,0) )
    end
    if face == 1:
        return ( Vec2(0,0) )
    end

    #
    # Compute impulse magnitude:
    # piecewise linear function, with increasing slope;
    # design idea is the more energy used to drill earth,
    # the deeper it drills, reaching softer mass and higher drilling efficiency,
    # resulting in higher impulse generated;
    # ignoring the E=MC^2 to prioritize game design objective over scientific believability.
    #
    local impulse_magnitude_fp
    let (bool_3) = is_le (
        ns_ndpe_impulse_function.X_THRESH_2_3,
        energy_consumed
    )
    let (bool_2) = is_nn_le (
        energy_consumed - ns_ndpe_impulse_function.X_THRESH_1_2,
        ns_ndpe_impulse_function.X_THRESH_2_3 - ns_ndpe_impulse_function.X_THRESH_1_2
    )

    #
    # If energy consumed lies in segment #3 of piecewise linear function
    #
    if bool_3 == 1:
        assert impulse_magnitude_fp = ns_ndpe_impulse_function.Y_OFFSET_3 + (energy_consumed - ns_ndpe_impulse_function.X_THRESH_2_3) * ns_ndpe_impulse_function.SLOPE_3
    end

    #
    # If energy consumed lies in segment #2 of piecewise linear function
    #
    if bool_2 == 1:
        assert impulse_magnitude_fp = ns_ndpe_impulse_function.Y_OFFSET_2 + (energy_consumed - ns_ndpe_impulse_function.X_THRESH_1_2) * ns_ndpe_impulse_function.SLOPE_2
    end

    #
    # Energy consumed lies in segment #1 of piecewise linear function
    #
    assert impulse_magnitude_fp = ns_ndpe_impulse_function.Y_OFFSET_1 + energy_consumed * ns_ndpe_impulse_function.SLOPE_1

    #
    # Determine impulse directionality based on `face` in micro coordinate system
    #    2
    # 4     0
    #    5     ---> x
    #
    if face == 0:
        return ( Vec2(impulse_magnitude_fp, 0) )
    end

    if face == 2:
        return ( Vec2(0, impulse_magnitude_fp) )
    end

    if face == 4:
        return ( Vec2(-impulse_magnitude_fp, 0) )
    end

    ## face == 5
    return ( Vec2(0, -impulse_magnitude_fp) )
end