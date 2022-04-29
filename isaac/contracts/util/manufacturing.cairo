%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    PLANET_DIM, SCALE_FP, SCALE_FP_DIV_100, RANGE_CHECK_BOUND,
    PERLIN_SCALER
)
from contracts.util.structs import (Vec2)
from contracts.macro import (div_fp, mul_fp)

#
# Functions involved in recipes for device manufacturing at OPSF:
# for each device receipt:
# f : energy, quantities of resources -> bool can manufacture
# g :
#
