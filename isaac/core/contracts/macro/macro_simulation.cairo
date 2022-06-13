%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import signed_div_rem, sign, assert_nn, assert_not_zero, unsigned_div_rem, sqrt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.hash import hash2

from contracts.design.constants import (
    G, MASS_SUN0, MASS_SUN1, MASS_SUN2, MASS_PLNT,
    G_MASS_SUN0, G_MASS_SUN1, G_MASS_SUN2,
    RADIUS_SUN0_SQ, RADIUS_SUN1_SQ, RADIUS_SUN2_SQ,
    OMEGA_DT_PLANET, TWO_PI,
    RANGE_CHECK_BOUND, SCALE_FP, SCALE_FP_SQRT, DT,
    ns_perturb
)
from contracts.util.structs import (Vec2, Dynamic, Dynamics)
from contracts.util.numerics import (mul_fp, div_fp, div_fp_ul, sqrt_fp)
from contracts.util.dynamics_ops import (dynamics_add, dynamics_mul_scalar_fp, dynamics_mul_scalar, dynamics_div_scalar)
from contracts.util.vector_ops import (distance_2, distance_3, vec2_add2, vec2_add3, compute_vector_rotate)
from contracts.util.pseudorandom import (ns_prng)
from contracts.macro.macro_state import (ns_macro_state_functions)

#
# Runge-Kutta 4th-order method
#
func rk4 {syscall_ptr : felt*, range_check_ptr} (
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

    # TODO: randomness derived from fiat shamir
    let delta = 0

    # state_nxt = state + (k1 + 2*k2 + 2*k3 + k4) / 6 + delta
    # TODO: add delta
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
func differentiate {syscall_ptr : felt*, range_check_ptr} (
        state : Dynamics
    ) -> (
        state_diff : Dynamics
    ):
    alloc_locals

    # TODO: refactor the following code for better readability without doing redundant computation

    let (r01_cube) = distance_3 (state.sun0.q, state.sun1.q)
    let (r02_cube) = distance_3 (state.sun0.q, state.sun2.q)
    let (r12_cube) = distance_3 (state.sun1.q, state.sun2.q)
    let (r03_cube) = distance_3 (state.sun0.q, state.plnt.q)
    let (r13_cube) = distance_3 (state.sun1.q, state.plnt.q)
    let (r23_cube) = distance_3 (state.sun2.q, state.plnt.q)

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

    let (acc_plnt_from_sun0_x) = mul_fp (G_r03_cube_m0, state.sun0.q.x - state.plnt.q.x)
    let (acc_plnt_from_sun0_y) = mul_fp (G_r03_cube_m0, state.sun0.q.y - state.plnt.q.y)
    let (acc_plnt_from_sun1_x) = mul_fp (G_r13_cube_m1, state.sun1.q.x - state.plnt.q.x)
    let (acc_plnt_from_sun1_y) = mul_fp (G_r13_cube_m1, state.sun1.q.y - state.plnt.q.y)
    let (acc_plnt_from_sun2_x) = mul_fp (G_r23_cube_m2, state.sun2.q.x - state.plnt.q.x)
    let (acc_plnt_from_sun2_y) = mul_fp (G_r23_cube_m2, state.sun2.q.y - state.plnt.q.y)

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
    let (acc_plnt : Vec2) = vec2_add3 (
        Vec2(acc_plnt_from_sun0_x, acc_plnt_from_sun0_y),
        Vec2(acc_plnt_from_sun1_x, acc_plnt_from_sun1_y),
        Vec2(acc_plnt_from_sun2_x, acc_plnt_from_sun2_y)
    )

    let state_diff = Dynamics (
        sun0 = Dynamic(state.sun0.qd, acc_sun0),
        sun1 = Dynamic(state.sun1.qd, acc_sun1),
        sun2 = Dynamic(state.sun2.qd, acc_sun2),
        plnt = Dynamic(state.plnt.qd, acc_plnt),
    )

    return (state_diff)
end

#
# A pure function for forwarding planet's rotation `phi`
#
func forward_planet_spin {range_check_ptr} (phi) -> (phi_nxt):
    let phi_nxt_cand = phi + OMEGA_DT_PLANET
    let (overflow) = is_le (TWO_PI, phi_nxt_cand)
    if overflow == 1:
        return (phi_nxt_cand - TWO_PI)
    else:
        return (phi_nxt_cand)
    end
end

#
# A pure function for applying impulse on planet's dynamic
#
func forward_planet_dynamic_applying_impulse {range_check_ptr} (
        dynamic_pre_impulse : Dynamic,
        impulse_fp : Vec2
    ) -> (
        dynamic_post_impulse : Dynamic
    ):
    alloc_locals

    let (delta_vx) = div_fp (impulse_fp.x, MASS_PLNT)
    let (delta_vy) = div_fp (impulse_fp.y, MASS_PLNT)
    let dynamic_post_impulse : Dynamic = Dynamic (
        q = dynamic_pre_impulse.q,
        qd = Vec2 (
            dynamic_pre_impulse.qd.x + delta_vx,
            dynamic_pre_impulse.qd.y + delta_vy,
        )
    )

    return (dynamic_post_impulse)
end

#
# A state-changing function for computing random perturbation (discount; reducing momentum)
# to be applied to the planet's dynamic; side effect is updating seed in PRNG
#
func forward_planet_dynamic_applying_perturbation {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        dynamic_pre_perturbation : Dynamic
    ) -> (
        dynamic_post_perturbation : Dynamic
    ):
    alloc_locals

    #
    # Produce perturbation vector before rotation
    #
    let (qdx_scaled) = mul_fp (ns_perturb.MULTIPLIER, dynamic_pre_perturbation.qd.x)
    let (qdy_scaled) = mul_fp (ns_perturb.MULTIPLIER, dynamic_pre_perturbation.qd.y)
    let perturb_vec_before_rotation = Vec2 (-qdx_scaled, -qdy_scaled)

    #
    # Pick a random rotation within bound;
    # incorporate planet velocity into random seed update (~fiat-shamir)
    #
    let (entropy) = hash2 {hash_ptr = pedersen_ptr} (dynamic_pre_perturbation.qd.x, dynamic_pre_perturbation.qd.y)
    let (prn) = ns_prng.get_prn_mod (
        mod = 2001,
        entropy = entropy
    ) # range: [0, 2000]
    let prn_shifted = prn - 1000 # range: [-1000, 1000]
    let (rotation, _) = signed_div_rem(ns_perturb.ROTATION_BOUND * prn_shifted, 1000, RANGE_CHECK_BOUND)

    #
    # Apply rotation to perturbation vector
    #
    let (perturb_vec_after_rotation) = compute_vector_rotate (
        perturb_vec_before_rotation,
        rotation
    )

    #
    # Apply perturbation to planet dynamic
    #
    let dynamic_post_perturbation : Dynamic = Dynamic (
        q = dynamic_pre_perturbation.q,
        qd = Vec2 (
            dynamic_pre_perturbation.qd.x + perturb_vec_after_rotation.x,
            dynamic_pre_perturbation.qd.y + perturb_vec_after_rotation.y,
        )
    )

    return (dynamic_post_perturbation)
end

#
# A state-changing function for forwarding the state of macro world
#
func forward_world_macro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Retrieve currnet macro states and impulse cache
    #
    let (state_curr : Dynamics) = ns_macro_state_functions.macro_state_curr_read ()
    let (phi_curr : felt) = ns_macro_state_functions.phi_curr_read ()
    let (impulse_aggregated : Vec2) = ns_macro_state_functions.impulse_cache_read ()

    #
    # Apply impulse to planet dynamic
    #
    let (plnt_dynamic_post_impulse) = forward_planet_dynamic_applying_impulse (
        state_curr.plnt,
        impulse_aggregated
    )

    #
    # Apply perturbation to planet dynamic
    #
    # let (plnt_dynamic_post_perturbation) = forward_planet_dynamic_applying_perturbation (
    #     plnt_dynamic_post_impulse
    # )
    let plnt_dynamic_post_perturbation = plnt_dynamic_post_impulse

    #
    # Assemble current state with perturbed planet dynamic;
    # side effect: seed update at prng with ~fiar-shamir
    #
    let state_curr_perturbed : Dynamics = Dynamics (
        sun0 = state_curr.sun0,
        sun1 = state_curr.sun1,
        sun2 = state_curr.sun2,
        plnt = plnt_dynamic_post_perturbation
    )

    #
    # Perform state forwarding
    #
    let (state_nxt : Dynamics) = rk4 (
        dt = DT,
        state = state_curr_perturbed
    )
    let (phi_nxt) = forward_planet_spin (
        phi = phi_curr
    )

    #
    # Update macro states and clear impulse cache
    #
    ns_macro_state_functions.macro_state_curr_write (state_nxt)
    ns_macro_state_functions.phi_curr_write (phi_nxt)
    ns_macro_state_functions.impulse_cache_write ( Vec2(0,0) )

    return ()
end

#
# Check for escape condition
#
func is_world_macro_escape_condition_met {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (met : felt):
    alloc_locals

    #
    # The escape condition has two parts:
    # 1. velocity: the planet's velocity >= escape velocity, the velocity such that kinetic energy + gravitational potential = 0
    # 2. range: calculate the center of suns' masses `center_suns`; the planet's distance from `center_suns` is >= 2x the largest among sun-to-center_suns distances
    # I don't think these conditions are ideal; I have yet to come up with an algorithm that is decidable and has minimized complexity.
    #

    #
    # 1-1. compute escape velocity (use square terms to prevent sqrt operations)
    #       1/2 * m_planet * v_esc^2 = Sum { G * M_sun_i * m_planet / r_sun_planet }
    #    => v_esc^2 = 2 * Sum { G * M_sun_i / r_sun_planet } = Sun { unit_potential_sun_i }
    #    compare this against v_planet^2
    let (state_curr : Dynamics) = ns_macro_state_functions.macro_state_curr_read ()

    let (d_sun0_plnt_sq) = distance_2 (state_curr.sun0.q, state_curr.plnt.q)
    let (d_sun1_plnt_sq) = distance_2 (state_curr.sun1.q, state_curr.plnt.q)
    let (d_sun2_plnt_sq) = distance_2 (state_curr.sun2.q, state_curr.plnt.q)

    let (d_sun0_plnt) = sqrt_fp (d_sun0_plnt_sq)
    let (d_sun1_plnt) = sqrt_fp (d_sun1_plnt_sq)
    let (d_sun2_plnt) = sqrt_fp (d_sun2_plnt_sq)

    let (unit_potential_sun0) = div_fp (G_MASS_SUN0, d_sun0_plnt)
    let (unit_potential_sun1) = div_fp (G_MASS_SUN1, d_sun1_plnt)
    let (unit_potential_sun2) = div_fp (G_MASS_SUN2, d_sun2_plnt)

    let vel_escape_sq = 2 * (unit_potential_sun0 + unit_potential_sun1 + unit_potential_sun2)

    #
    # 1-2. check escape velocity against planet's current velocity magnitude
    #
    let (vel_x_sq) = mul_fp (state_curr.plnt.qd.x, state_curr.plnt.qd.x)
    let (vel_y_sq) = mul_fp (state_curr.plnt.qd.y, state_curr.plnt.qd.y)
    let vel_sq = vel_x_sq + vel_y_sq
    let (bool_escape_velocity_reached) = is_le (vel_escape_sq, vel_sq)

    #
    # 2-1. Compute center of suns' masses `center_suns`
    # Note: assuming three suns have identical mass!
    #
    let sum_sun_xs = state_curr.sun0.q.x + state_curr.sun1.q.x + state_curr.sun2.q.x
    let sum_sun_ys = state_curr.sun0.q.y + state_curr.sun1.q.y + state_curr.sun2.q.y
    let (sun_avg_x, _) = signed_div_rem(sum_sun_xs, 3, RANGE_CHECK_BOUND)
    let (sun_avg_y, _) = signed_div_rem(sum_sun_ys, 3, RANGE_CHECK_BOUND)
    let center_suns : Vec2 = Vec2 (sun_avg_x, sun_avg_y)

    #
    # 2-2. Compute distances (in square terms) between suns and `center_suns`
    #
    let (d_sun0_center_sq) = distance_2 (center_suns, state_curr.sun0.q)
    let (d_sun1_center_sq) = distance_2 (center_suns, state_curr.sun1.q)
    let (d_sun2_center_sq) = distance_2 (center_suns, state_curr.sun2.q)

    #
    # 2-3. Compute distance (in square term) between planet and `center_suns`, check its square >= 2 * d_sunx_center_sq for all x
    #      i.e. ~1.414x in distance terms
    #
    let (d_plnt_center_sq) = distance_2 (center_suns, state_curr.plnt.q)
    let (bool_0) = is_le (d_sun0_center_sq * 2, d_sun0_center_sq)
    let (bool_1) = is_le (d_sun1_center_sq * 2, d_sun0_center_sq)
    let (bool_2) = is_le (d_sun2_center_sq * 2, d_sun0_center_sq)
    let bool_escape_range_reached = bool_0 * bool_1 * bool_2

    #
    # Merge flags
    #
    let met = bool_escape_velocity_reached * bool_escape_range_reached

    return (met)
end

#
# Check for destruction condition
#
func is_world_macro_destructed {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):
    alloc_locals

    let (state_curr : Dynamics) = ns_macro_state_functions.macro_state_curr_read ()

    #
    # Check if planet coordinate lies in each sun's radius (in square terms)
    #
    let (dist_plnt_sun0_sq) = distance_2 (state_curr.plnt.q, state_curr.sun0.q)
    let (bool_sun0_collide) = is_le (dist_plnt_sun0_sq, RADIUS_SUN0_SQ)
    if bool_sun0_collide == 1:
        return (1)
    end

    let (dist_plnt_sun1_sq) = distance_2 (state_curr.plnt.q, state_curr.sun1.q)
    let (bool_sun1_collide) = is_le (dist_plnt_sun1_sq, RADIUS_SUN1_SQ)
    if bool_sun1_collide == 1:
        return (1)
    end

    let (dist_plnt_sun2_sq) = distance_2 (state_curr.plnt.q, state_curr.sun2.q)
    let (bool_sun2_collide) = is_le (dist_plnt_sun2_sq, RADIUS_SUN2_SQ)
    if bool_sun2_collide == 1:
        return (1)
    end

    #
    # Otherwise not collided
    #
    return (0)

end