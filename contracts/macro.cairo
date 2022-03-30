%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import signed_div_rem, sign, assert_nn, assert_not_zero, unsigned_div_rem, sqrt
from starkware.cairo.common.math_cmp import is_le
from contracts.design.constants import (
    G, MASS_SUN0, MASS_SUN1, MASS_SUN2, OMEGA_DT_PLANET, TWO_PI,
    RANGE_CHECK_BOUND, SCALE_FP, SCALE_FP_SQRT, DT
)
from contracts.util.structs import (Vec2, Dynamic, Dynamics)
from contracts.libs.fpmath import (
    sqrt_fp, mul_fp, div_fp, mul_fp_ul, div_fp_ul, vec2_add2, vec2_add3
)
from contracts.libs.dynamicsmath import (
    dynamics_add, dynamic_add, dynamics_mul_scalar, dynamic_mul_scalar_fp, dynamics_mul_scalar,
    dynamic_mul_scalar, dynamics_div_scalar, dynamic_div_scalar
)

#
# Runge-Kutta 4th-order method
#
func rk4 {range_check_ptr} (
        dt : felt,
        state : Dynamics
    ) -> (
        state_nxt : Dynamics
    ):
    alloc_locals

    # k1 = dt * differentiate (state)
    let (state_diff : Dynamics) = differentiate (state)
    let (k1 : Dynamics) = dynamics_mul_scalar_fp (state_diff, dt)

    # k2 = dt * differentiate (state + 0.5 * k1)
    let (half_k1 : Dynamics) = dynamics_div_scalar (k1, 2)
    let (state_half_k1 : Dynamics) = dynamics_add (state, half_k1)
    let (state_half_k1_diff : Dynamics) = differentiate (state_half_k1)
    let (k2 : Dynamics) = dynamics_mul_scalar_fp (state_half_k1_diff, dt)

    # k3 = dt * differentiate (state + 0.5 * k2)
    let (half_k2 : Dynamics) = dynamics_div_scalar (k2, 2)
    let (state_half_k2 : Dynamics) = dynamics_add (state, half_k2)
    let (state_half_k2_diff : Dynamics) = differentiate (state_half_k2)
    let (k3 : Dynamics) = dynamics_mul_scalar_fp (state_half_k2_diff, dt)

    # k4 = dt * differentiate (state + k3)
    let (state_k3 : Dynamics) = dynamics_add (state, k3)
    let (state_k3_diff : Dynamics) = differentiate (state_k3)
    let (k4 : Dynamics) = dynamics_mul_scalar_fp (state_k3_diff, dt)

    # state_nxt = state + (k1 + 2*k2 + 2*k3 + k4) / 6
    let (k2_2 : Dynamics) = dynamics_mul_scalar (k2, 2)
    let (k3_2 : Dynamics) = dynamics_mul_scalar (k3, 2)
    let (numerator__ : Dynamics) = dynamics_add (k1, k2_2)
    let (numerator_ : Dynamics) = dynamics_add (numerator__, k3_2)
    let (numerator : Dynamics) = dynamics_add (numerator_, k4)
    let (state_diff : Dynamics) = dynamics_div_scalar (numerator, 6)
    let (state_nxt : Dynamics) = dynamics_add (state, state_diff)

    return (state_nxt)
end

#
# First-order derivative of state
#
func differentiate {range_check_ptr} (
        state : Dynamics
    ) -> (
        state_diff : Dynamics
    ):
    alloc_locals

    # TODO: refactor the following code for better readability without doing redundant computation

    let (r01_cube) = distance_cube (state.sun0.q, state.sun1.q)
    let (r02_cube) = distance_cube (state.sun0.q, state.sun1.q)
    let (r12_cube) = distance_cube (state.sun0.q, state.sun1.q)
    let (r03_cube) = distance_cube (state.sun0.q, state.merc.q)
    let (r13_cube) = distance_cube (state.sun1.q, state.merc.q)
    let (r23_cube) = distance_cube (state.sun2.q, state.merc.q)

    let (G_r01_cube) = div_fp (G, r01_cube)
    let (G_r02_cube) = div_fp (G, r02_cube)
    let (G_r12_cube) = div_fp (G, r12_cube)

    let (G_r03_cube) = div_fp (G, r03_cube)
    let (G_r13_cube) = div_fp (G, r13_cube)
    let (G_r23_cube) = div_fp (G, r23_cube)

    let (G_r01_cube_m0) = mul_fp (G_r01_cube, MASS_SUN0)
    let (G_r01_cube_m1) = mul_fp (G_r01_cube, MASS_SUN1)

    let (G_r02_cube_m0) = mul_fp (G_r02_cube, MASS_SUN0)
    let (G_r02_cube_m2) = mul_fp (G_r02_cube, MASS_SUN2)

    let (G_r12_cube_m1) = mul_fp (G_r12_cube, MASS_SUN1)
    let (G_r12_cube_m2) = mul_fp (G_r12_cube, MASS_SUN2)

    let (G_r03_cube_m0) = mul_fp (G_r03_cube, MASS_SUN0)
    let (G_r13_cube_m1) = mul_fp (G_r13_cube, MASS_SUN1)
    let (G_r23_cube_m2) = mul_fp (G_r23_cube, MASS_SUN2)

    let (acc_sun0_from_sun1_x) = mul_fp (G_r01_cube_m1, state.sun1.q.x - state.sun0.q.x)
    let (acc_sun0_from_sun1_y) = mul_fp (G_r01_cube_m1, state.sun1.q.y - state.sun0.q.y)
    let (acc_sun0_from_sun2_x) = mul_fp (G_r02_cube_m2, state.sun2.q.x - state.sun0.q.x)
    let (acc_sun0_from_sun2_y) = mul_fp (G_r02_cube_m2, state.sun2.q.y - state.sun0.q.y)

    let (acc_sun1_from_sun0_x) = mul_fp (G_r01_cube_m0, state.sun0.q.x - state.sun1.q.x)
    let (acc_sun1_from_sun0_y) = mul_fp (G_r01_cube_m0, state.sun0.q.y - state.sun1.q.y)
    let (acc_sun1_from_sun2_x) = mul_fp (G_r12_cube_m2, state.sun2.q.x - state.sun1.q.x)
    let (acc_sun1_from_sun2_y) = mul_fp (G_r12_cube_m2, state.sun2.q.y - state.sun1.q.y)

    let (acc_sun2_from_sun0_x) = mul_fp (G_r02_cube_m0, state.sun0.q.x - state.sun2.q.x)
    let (acc_sun2_from_sun0_y) = mul_fp (G_r02_cube_m0, state.sun0.q.y - state.sun2.q.y)
    let (acc_sun2_from_sun1_x) = mul_fp (G_r12_cube_m1, state.sun1.q.x - state.sun2.q.x)
    let (acc_sun2_from_sun1_y) = mul_fp (G_r12_cube_m1, state.sun1.q.y - state.sun2.q.y)

    let (acc_merc_from_sun0_x) = mul_fp (G_r03_cube_m0, state.sun0.q.x - state.merc.q.x)
    let (acc_merc_from_sun0_y) = mul_fp (G_r03_cube_m0, state.sun0.q.y - state.merc.q.y)
    let (acc_merc_from_sun1_x) = mul_fp (G_r13_cube_m1, state.sun1.q.x - state.merc.q.x)
    let (acc_merc_from_sun1_y) = mul_fp (G_r13_cube_m1, state.sun1.q.y - state.merc.q.y)
    let (acc_merc_from_sun2_x) = mul_fp (G_r23_cube_m2, state.sun2.q.x - state.merc.q.x)
    let (acc_merc_from_sun2_y) = mul_fp (G_r23_cube_m2, state.sun2.q.y - state.merc.q.y)

    let (acc_sun0 : Vec2) = vec2_add2 (
        Vec2(acc_sun0_from_sun1_x, acc_sun0_from_sun1_y),
        Vec2(acc_sun0_from_sun2_x, acc_sun0_from_sun2_y)
    )
    let (acc_sun1 : Vec2) = vec2_add2 (
        Vec2(acc_sun1_from_sun0_x, acc_sun1_from_sun0_y),
        Vec2(acc_sun1_from_sun2_x, acc_sun1_from_sun2_y)
    )
    let (acc_sun2 : Vec2) = vec2_add2 (
        Vec2(acc_sun2_from_sun0_x, acc_sun2_from_sun0_y),
        Vec2(acc_sun2_from_sun1_x, acc_sun2_from_sun1_y)
    )
    let (acc_merc : Vec2) = vec2_add3 (
        Vec2(acc_merc_from_sun0_x, acc_merc_from_sun0_y),
        Vec2(acc_merc_from_sun1_x, acc_merc_from_sun1_y),
        Vec2(acc_merc_from_sun2_x, acc_merc_from_sun2_y)
    )

    let state_diff = Dynamics (
        sun0 = Dynamic(state.sun0.qd, acc_sun0),
        sun1 = Dynamic(state.sun1.qd, acc_sun1),
        sun2 = Dynamic(state.sun2.qd, acc_sun2),
        merc = Dynamic(state.merc.qd, acc_merc),
    )

    return (state_diff)
end

func distance_cube {range_check_ptr} (
        pos0 : Vec2, pos1 : Vec2
    ) -> (res : felt):
    alloc_locals

    # TODO: optimize away potential FP compensation that is redundant

    let x_delta = pos0.x - pos1.x
    let (x_delta_sq) = mul_fp (x_delta, x_delta)

    let y_delta = pos0.y - pos1.y
    let (y_delta_sq) = mul_fp (y_delta, y_delta)

    let diff_sq = x_delta_sq + y_delta_sq
    let (diff) = sqrt_fp (diff_sq)

    let (res) = mul_fp (diff_sq, diff)
    return (res)
end

func forward_planet_spin {range_check_ptr} (phi) -> (phi_nxt):
    let phi_nxt_cand = phi + OMEGA_DT_PLANET
    let (overflow) = is_le (TWO_PI, phi_nxt_cand)
    if overflow == 1:
        return (phi_nxt_cand - TWO_PI)
    else:
        return (phi_nxt_cand)
    end
end

func forward_world_macro {pedersen_ptr : HashBuiltin*, range_check_ptr}(
        state : Dynamics,
        phi : felt
    ) -> (
        state_nxt : Dynamics,
        phi_nxt : felt
    ):
    alloc_locals

    let (state_nxt : Dynamics) = rk4 (dt=DT, state=state)
    let (phi_nxt) = forward_planet_spin (phi)
    ## add handling of momentum kick created by NDPE launch

    return (state_nxt, phi_nxt)
end