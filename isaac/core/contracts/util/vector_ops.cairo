%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (signed_div_rem, sqrt)
from contracts.util.structs import (Vec2)
from contracts.util.numerics import (mul_fp, sqrt_fp, sine_7th)
from contracts.design.constants import (
    SCALE_FP
)

#
# Function for calculating squared distance between two Vec2
#
func distance_2 {range_check_ptr} (
        pos0 : Vec2, pos1 : Vec2
    ) -> (res : felt):
    alloc_locals

    let x_delta = pos0.x - pos1.x
    let (x_delta_sq) = mul_fp (x_delta, x_delta)

    let y_delta = pos0.y - pos1.y
    let (y_delta_sq) = mul_fp (y_delta, y_delta)

    let diff_sq = x_delta_sq + y_delta_sq

    return (diff_sq)
end

#
# Function for calculating cubed distance between two Vec2
#
func distance_3 {range_check_ptr} (
        pos0 : Vec2, pos1 : Vec2
    ) -> (res : felt):
    alloc_locals

    let (diff_sq) = distance_2 (pos0, pos1)
    let (diff) = sqrt_fp (diff_sq)
    let (res) = mul_fp (diff_sq, diff)

    return (res)
end

#
# Function for adding two Vec2
#
func vec2_add2 {} (vec2_0 : Vec2, vec2_1 : Vec2) -> (res : Vec2):
    return (
        Vec2 (
            vec2_0.x + vec2_1.x,
            vec2_0.y + vec2_1.y
        )
    )
end

#
# Function for adding three Vec2
#
func vec2_add3 {} (vec2_0 : Vec2, vec2_1 : Vec2, vec2_2 : Vec2) -> (res : Vec2):
    return (
        Vec2 (
            vec2_0.x + vec2_1.x + vec2_2.x,
            vec2_0.y + vec2_1.y + vec2_2.y
        )
    )
end

func dot_fp {range_check_ptr} (
    v1 : Vec2, v2 : Vec2) -> (dot : felt):

    let (x_prod) = mul_fp (v1.x, v2.x)
    let (y_prod) = mul_fp (v1.y, v2.y)

    return (x_prod + y_prod)
end

func magnitude_fp {range_check_ptr} (
    v : Vec2) -> (mag : felt):

    let (vx_sq) = mul_fp (v.x, v.x)
    let (vy_sq) = mul_fp (v.y, v.y)
    let (mag) = sqrt_fp (vx_sq + vy_sq)

    return (mag)
end

func compute_vector_rotate {range_check_ptr} (
    vec : Vec2, phi : felt) -> (vec_rotated : Vec2):
    alloc_locals

    #
    # Compute cos(phi) and sin(phi)
    #
    let (local sin_phi) = sine_7th (phi)
    let (local sin_phi_sq) = mul_fp (sin_phi, sin_phi)
    local phi_ = phi
    with_attr error_message ("sqrt(1-sin^2) went wrong, with sin(phi) = {sin_phi}, phi = {phi_}"):
        let (cos_phi) = sqrt_fp (1*SCALE_FP - sin_phi_sq)
    end

    #
    # Apply rotation matrix
    # [[cos -sin],
    #  [sin  cos]]
    # => [x*cos - y*sin, x*sin + y*cos]
    #
    let (x_mul_cos) = mul_fp (vec.x, cos_phi)
    let (x_mul_sin) = mul_fp (vec.x, sin_phi)
    let (y_mul_cos) = mul_fp (vec.y, cos_phi)
    let (y_mul_sin) = mul_fp (vec.y, sin_phi)
    let vec_rotated : Vec2 = Vec2 (
        x_mul_cos - y_mul_sin,
        x_mul_sin + y_mul_cos
    )

    return (vec_rotated)
end

func compute_vector_rotate_90 {range_check_ptr} (
    vec : Vec2) -> (vec_rotated : Vec2):

    #
    # Apply rotation matrix
    # [[0 -1],
    #  [1  0]]
    # => [-y, x]
    #
    let vec_rotated : Vec2 = Vec2 (-vec.y, vec.x)

    return (vec_rotated)
end