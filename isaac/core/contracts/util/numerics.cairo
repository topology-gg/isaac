%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (signed_div_rem, sqrt)
from starkware.cairo.common.math_cmp import is_le
from contracts.design.constants import (
    PI,
    SCALE_FP_SQRT, SCALE_FP, RANGE_CHECK_BOUND
)

#
# Utility functions for fixed-point arithmetic
#
func sqrt_fp {range_check_ptr}(x : felt) -> (y : felt):
    let (x_) = sqrt(x)
    let y = x_ * SCALE_FP_SQRT # compensate for the square root
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

func sine_7th {range_check_ptr} (
        theta : felt) -> (value : felt):
        alloc_locals

        #
        # sin(theta) ~= theta - theta^3/3! + theta^5/5! - theta^7/7!
        #

        local theta_norm
        let (bool) = is_le (PI, theta)
        if bool == 1:
            assert theta_norm = theta - PI
        else:
            assert theta_norm = theta
        end

        let (local theta_2) = mul_fp (theta_norm, theta_norm)
        let (local theta_3) = mul_fp (theta_2, theta_norm)
        let (local theta_5) = mul_fp (theta_2, theta_3)
        let (local theta_7) = mul_fp (theta_2, theta_5)

        let (theta_3_div6) = div_fp_ul (theta_3, 6)
        let (theta_5_div120) = div_fp_ul (theta_5, 120)
        let (theta_7_div5040) = div_fp_ul (theta_7, 5040)

        let value = theta_norm - theta_3_div6 + theta_5_div120 - theta_7_div5040

        if bool == 1:
            return (-value)
        else:
            return (value)
        end
    end