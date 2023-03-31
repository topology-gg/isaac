use projectile::constants::SCALE_FP;
use projectile::constants::PI;
use projectile::fixed_point::FixedPt;
use projectile::fixed_point::FixedPtType;
//
// Math functions
//
// Finds distance between fixed point coordinate values (x_1, y_1) and (x_2, y_2)
fn distance_two_points_fp(
    x_1_fp: FixedPtType, y_1_fp: FixedPtType, x_2_fp: FixedPtType, y_2_fp: FixedPtType
) -> FixedPtType {
    let x_diff_fp = x_2_fp - x_1_fp;
    let y_diff_fp = y_2_fp - y_1_fp;
    let x_diff_sq_fp = x_diff_fp * x_diff_fp;
    let y_diff_sq_fp = y_diff_fp * y_diff_fp;
    let sum_fp = x_diff_sq_fp + y_diff_sq_fp;
    let r_fp = FixedPt::fp_sqrt(sum_fp);
    r_fp
}

// Taylor series approximation of cosine(theta) for FP theta value
// Uses 5 terms (to 8th order)
// Assumes -pi <= theta <= +pi
fn cosine_8th_fp(theta_fp: FixedPtType) -> FixedPtType {
    //
    // cos(theta) ~= 1 - theta^2/2! + theta^4/4! - theta^6/6! + theta^8/8!

    let theta_2_fp = theta_fp * theta_fp;
    let theta_4_fp = theta_2_fp * theta_2_fp;
    let theta_6_fp = theta_2_fp * theta_4_fp;
    let theta_8_fp = theta_2_fp * theta_6_fp;

    // factorial values
    let two_fact_fp = FixedPt::from_felt(2 * SCALE_FP);
    let four_fact_fp = FixedPt::from_felt(24 * SCALE_FP);
    let six_fact_fp = FixedPt::from_felt(720 * SCALE_FP);
    let eight_fact_fp = FixedPt::from_felt(40320 * SCALE_FP);

    let theta_2_div_2fact_fp = theta_2_fp / two_fact_fp;
    let theta_4_div_4fact_fp = theta_4_fp / four_fact_fp;
    let theta_6_div_6fact_fp = theta_6_fp / six_fact_fp;
    let theta_8_div_8fact_fp = theta_8_fp / eight_fact_fp;

    let one_fp = FixedPt::from_felt(1 * SCALE_FP);
    let value_fp = one_fp
        - theta_2_div_2fact_fp
        + theta_4_div_4fact_fp
        - theta_6_div_6fact_fp
        + theta_8_div_8fact_fp;

    if (value_fp.mag == 0_u128) {
        FixedPt::new(0_u128, false) // force sign=false if mag=0
    } else {
        value_fp
    }
}

// Cosine approximation:
// 
// Taylor series approximation is more accurate if -pi/2 <= theta <= +pi/2. 
// So:
//   If theta is in quadrant II or III:
//     (1) "move" angle to quadrant I or II for cosine calculation
//     (2) force negative sign for cos(theta)
//   (Use theta_deg_fp for comparisons; calculated theta_fp is slightly rounded)
//   Then call cosine_8th_fp
fn cos_approx_fp(theta_deg_fp: FixedPtType) -> FixedPtType {
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let pi_fp = FixedPt::from_felt(PI); // PI is already scaled up
    let zero_fp = FixedPt::from_felt(0);

    if (theta_deg_fp.mag > 900000000000_u128) {
        if (theta_deg_fp.sign == false) { // Quadrant II
            // Move to quadrant I, force cos(theta) to be negative
            let theta_moved_fp = pi_fp - theta_fp;
            let non_neg_cos_theta_fp = cosine_8th_fp(theta_moved_fp);
            zero_fp - non_neg_cos_theta_fp
        } else { // Quadrant III
            // Move to quadrant IV, force cos(theta) to be negative
            let theta_moved_fp = zero_fp - pi_fp - theta_fp;
            let non_neg_cos_theta_fp = cosine_8th_fp(theta_moved_fp);
            zero_fp - non_neg_cos_theta_fp
        }
    } else {
        if (theta_deg_fp.mag == 900000000000_u128) { // +-90 degrees
            // Use exact value of cos(+-90) = 0
            FixedPt::new(0_u128, false)
        } else { // Quadrant I or IV
            cosine_8th_fp(theta_fp)
        }
    }
}

// Sine approximation: need to force correct signs
fn sin_approx_fp(theta_deg_fp: FixedPtType) -> FixedPtType {
    let zero_fp = FixedPt::from_felt(0);
    let one_fp = FixedPt::from_felt(1 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    let cos_theta_squared_fp = cos_theta_deg_fp * cos_theta_deg_fp;
    let diff_fp = one_fp - cos_theta_squared_fp;
    let root_fp = FixedPt::fp_sqrt(diff_fp);

    if (theta_deg_fp.sign == false) {
        // If theta_0 >= 0, then sin_theta_0 >= 0
        root_fp
    // FixedPt::fp_sqrt(one_fp - cos_theta_squared_fp)
    } else {
        // If theta_0 < 0, then sin_theta_0 < 0
        zero_fp - root_fp
    // zero_fp - FixedPt::fp_sqrt(one_fp - cos_theta_squared_fp)
    }
}
