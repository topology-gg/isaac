%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import abs_value
from starkware.cairo.common.math_cmp import is_le

from contracts.math import sqrt_fp, mul_fp, mul_fp_nfp, div_fp, div_fp_nfp
from contracts.constants import PI_fp, g_fp, x_0_fp, y_0_fp, x_min_fp, x_max_fp, y_min_fp
//
// Functions for physics
//

// Time of projectile in plot area
func time_in_plot_fp{range_check_ptr}(theta_0_deg: felt, v_0x_fp: felt, v_0y_fp: felt) -> felt {  
    alloc_locals;
    local range_check_ptr = range_check_ptr;

    // Max time needed for y-direction
    let v_0y_squared_fp = mul_fp(v_0y_fp, v_0y_fp);
    let delta_y_max_fp = y_min_fp - y_0_fp;
    let g_delta_y_max_fp = mul_fp(g_fp, delta_y_max_fp);
    let two_g_delta_y_max_fp = mul_fp_nfp (g_delta_y_max_fp, 2);
    let diff_fp = v_0y_squared_fp - two_g_delta_y_max_fp;
    let root_fp = sqrt_fp(diff_fp);
    let sum_fp = v_0y_fp + root_fp;
    let t_max_y_fp = div_fp(sum_fp, g_fp);

    //
    // Find max time needed for x_direction, t_max_x
    // Then t_max is minimum of t_max_x and t_max_y
    //
    // Check if abs(theta_0_deg) <, =, or > 90 degrees 
    // Use theta_0_deg because calculated theta_0 in radians is slightly rounded
    // Then find t_max_x, and then t_max
    let abs_value_theta_0_deg = abs_value(theta_0_deg);
    let bool1 = is_le(abs_value_theta_0_deg, 90);
    if (bool1 == 1) {
        // abs(theta_0_deg) <= 90
        if (abs_value_theta_0_deg == 90) {
            // abs(theta_0_deg) = 90, so v_0x = 0, so t_max_x = infinite, so
            tempvar t_max_fp = t_max_y_fp;
            tempvar range_check_ptr = range_check_ptr;

        } else {
            // abs(theta_0_deg) < 90, so v_0x > 0, so projectile moves toward x_max
            let delta_x_max_fp = x_max_fp - x_0_fp;
            let t_max_x_fp = div_fp(delta_x_max_fp, v_0x_fp);

            let bool2 = is_le(t_max_x_fp,t_max_y_fp);
            if (bool2 == 1) {
                tempvar t_max_fp = t_max_x_fp;
                tempvar range_check_ptr = range_check_ptr;
            } else {
                tempvar t_max_fp = t_max_y_fp;
                tempvar range_check_ptr = range_check_ptr;
            }
        }

    } else {
        // abs(theta_0_deg) > 90, so v_0x < 0, so projectile moves toward x_min
        let delta_x_max_fp = x_min_fp - x_0_fp;
        let t_max_x_fp = div_fp(delta_x_max_fp, v_0x_fp);
        let bool2 = is_le(t_max_x_fp,t_max_y_fp);

        if (bool2 == 1) {
            tempvar t_max_fp = t_max_x_fp;
            tempvar range_check_ptr = range_check_ptr;
        } else {
            tempvar t_max_fp = t_max_y_fp;
            tempvar range_check_ptr = range_check_ptr;
        }
    }

    return t_max_fp;
}

// Horizontal position
func x_value_fp{range_check_ptr}(v_0x_fp: felt, t_fp: felt) -> felt {
    let v_0x_t_fp = mul_fp(v_0x_fp, t_fp);
    let x_fp = x_0_fp + v_0x_t_fp;
    return x_fp;
}

// Vertical position
func y_value_fp{range_check_ptr}(v_0y_fp: felt, t_fp: felt) -> felt {
    let v_0y_t_fp = mul_fp(v_0y_fp, t_fp);
    let t_squared_fp = mul_fp(t_fp, t_fp);
    let g_t_squared_fp = mul_fp(g_fp, t_squared_fp);
    let half_g_t_squared_fp = div_fp_nfp(g_t_squared_fp, 2);
    let y_fp = y_0_fp + v_0y_t_fp - half_g_t_squared_fp;
    return y_fp;
}