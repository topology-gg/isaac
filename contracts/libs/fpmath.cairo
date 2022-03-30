from contracts.design.constants import (
    G, MASS_SUN0, MASS_SUN1, MASS_SUN2, OMEGA_DT_PLANET, TWO_PI,
    RANGE_CHECK_BOUND, SCALE_FP, SCALE_FP_SQRT, DT
)
from contracts.util.structs import (Vec2, Dynamic, Dynamics)

#
# Utility functions for fixed-point arithmetic
#
func sqrt_fp {range_check_ptr}(x : felt) -> (y : felt):
    let (x_) = sqrt(x)
    let y = x * SCALE_FP_SQRT # compensate for the square root
    return (y)
end

func mul_fp {range_check_ptr} (
        a : felt,
        b : felt
    ) -> (
        c : felt
    ):
    # signed_div_rem by SCALE_FP after multiplication
    tempvar product = a * b
    let (c, _) = signed_div_rem(product, SCALE_FP, RANGE_CHECK_BOUND)
    return (c)
end

func div_fp {range_check_ptr} (
        a : felt,
        b : felt
    ) -> (
        c : felt
    ):
    # multiply by SCALE_FP before signed_div_rem
    tempvar a_scaled = a * SCALE_FP
    let (c, _) = signed_div_rem(a_scaled, b, RANGE_CHECK_BOUND)
    return (c)
end

func mul_fp_ul {range_check_ptr} (
        a : felt,
        b_ul : felt
    ) -> (
        c : felt
    ):
    let c = a * b_ul
    return (c)
end

func div_fp_ul {range_check_ptr} (
        a : felt,
        b_ul : felt
    ) -> (
        c : felt
    ):
    let (c, _) = signed_div_rem(a, b_ul, RANGE_CHECK_BOUND)
    return (c)
end

func vec2_add2 {} (vec2_0 : Vec2, vec2_1 : Vec2) -> (res : Vec2):
    return (
        Vec2 (
            vec2_0.x + vec2_1.x,
            vec2_0.y + vec2_1.y
        )
    )
end

func vec2_add3 {} (vec2_0 : Vec2, vec2_1 : Vec2, vec2_2 : Vec2) -> (res : Vec2):
    return (
        Vec2 (
            vec2_0.x + vec2_1.x + vec2_2.x,
            vec2_0.y + vec2_1.y + vec2_2.y
        )
    )
end