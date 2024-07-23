%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import abs_value
from starkware.cairo.common.math_cmp import is_le, is_nn

from contracts.constants import SCALE_FP, PI_fp, g_fp, x_0_fp, y_0_fp, x_min_fp, x_max_fp, y_min_fp, y_max_fp
from contracts.math import mul_fp, div_fp, div_fp_nfp, cosine_6th_fp, cosine_8th_fp, cosine_approx, sine_approx
from contracts.physics import time_in_plot_fp, x_value_fp, y_value_fp

//
// Functions to fill arrays
//

// Calculate position coordinate values and fill arrays
func position_fp_s_filler{range_check_ptr}(num_pts: felt, v_0x_fp: felt, v_0y_fp: felt, delta_t_fp: felt, t_fp: felt, x_fp_s: felt*, y_fp_s: felt*) {

    // Return after cuing up all coordinate values
    if (num_pts == 0) {
        return ();
    }

    // Recursively call to go through all coordinate values
    position_fp_s_filler(num_pts - 1, v_0x_fp, v_0y_fp, delta_t_fp, t_fp + delta_t_fp, x_fp_s + 1, y_fp_s + 1);

    // after return from 0, now num_pts = 1, t_fp = t_max_fp, begin to fill arrays in reverse
    assert x_fp_s[0] = x_value_fp(v_0x_fp, t_fp);
    assert y_fp_s[0] = y_value_fp(v_0y_fp, t_fp);

    return ();
}

//
//  View function for input of num_pts, lambda, and d; then create intensity plot data
//
@view
func projectile_path{range_check_ptr}(num_pts: felt, theta_0_deg: felt, v_0: felt) -> (
    x_fp_s_len : felt, x_fp_s: felt*, y_fp_s_len : felt, y_fp_s: felt*, 
) {
    alloc_locals;

    // Check inputs
    with_attr error_message("Check that 2 <= num_pts <= 25; integer only") {
        assert is_le(2, num_pts) = 1;
    }
    with_attr error_message("Check that 2 <= num_pts <= 25; integer only") {
        assert is_le(num_pts, 25) = 1; 
    }

    with_attr error_message("Check that -179 <= theta_0_deg <= +180; integer only") {
        assert is_le(-179, theta_0_deg) = 1; 
    }
    with_attr error_message("Check that -179 <= theta_0_deg <= +180; integer only") {
        assert is_le(theta_0_deg, 180) = 1; 
    }

    with_attr error_message("Check that v_0 >= 1; integer only") {
        assert is_le(1, v_0) = 1;
    }

    // Scale up inputs to be fixed point values
    let theta_0_deg_fp = theta_0_deg * SCALE_FP;
    let v_0_fp = v_0 * SCALE_FP;

    // Convert angle to radians
    let pi_over_180_fp = div_fp_nfp(PI_fp, 180);
    let theta_0_fp = mul_fp(theta_0_deg_fp, pi_over_180_fp);

    // Trig function approximations
    // Use below instead of this: let (cos_theta_0_fp) = cosine_8th_fp(theta_0_fp);
    // for better approx of cosine
    let (cos_theta_0_fp) = cosine_approx(theta_0_fp, theta_0_deg);
    let (sin_theta_0_fp) = sine_approx(theta_0_fp, cos_theta_0_fp);

    // Initial velocity vector components
    let v_0x_fp = mul_fp(v_0_fp, cos_theta_0_fp);
    let v_0y_fp = mul_fp(v_0_fp, sin_theta_0_fp);

    // Total time projectile remains in plot area
    let t_max_fp = time_in_plot_fp(theta_0_deg, v_0x_fp, v_0y_fp);

    // Time step size
    let delta_t_fp = div_fp_nfp(t_max_fp, num_pts - 1);

    // Initial time
    let t_0_fp = 0 * SCALE_FP;

    // Allocate memory segments for position coordinate arrays
    //let (position_fp_s: Position_fp*) = alloc(); 
    let (x_fp_s: felt*) = alloc();
    let (y_fp_s: felt*) = alloc();

    // Fill position arrays
    position_fp_s_filler(num_pts, v_0x_fp, v_0y_fp, delta_t_fp, t_0_fp, x_fp_s, y_fp_s);

    // Length of arrays
    let x_fp_s_len = num_pts;
    let y_fp_s_len = num_pts;

    return (x_fp_s_len=x_fp_s_len , x_fp_s=x_fp_s, y_fp_s_len=y_fp_s_len, y_fp_s=y_fp_s);
}
