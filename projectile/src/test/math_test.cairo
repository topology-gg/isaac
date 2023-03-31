use traits::Into;

// use gas::withdraw_gas;
// use gas::withdraw_gas_all;

use projectile::constants::SCALE_FP;
use projectile::constants::SCALE_FP_u128;

use projectile::fixed_point::FixedPt;
// use projectile::fixed_point::FixedPtType;
use projectile::fixed_point::FixedPtInto;
use projectile::math::distance_two_points_fp;
use projectile::math::cosine_8th_fp;
use projectile::math::cos_approx_fp;
use projectile::math::sin_approx_fp;

#[test]
#[available_gas(20000000)]
fn test_distance_two_points_fp() {
    let x_1_fp = FixedPt::from_felt(0 * SCALE_FP);
    let y_1_fp = FixedPt::from_felt(0 * SCALE_FP);
    let x_2_fp = FixedPt::from_felt(4 * SCALE_FP);
    let y_2_fp = FixedPt::from_felt(3 * SCALE_FP);
    let r_fp = distance_two_points_fp(x_1_fp, y_1_fp, x_2_fp, y_2_fp, );
    assert(r_fp.mag == 5_u128 * SCALE_FP_u128, 'result 1a invalid');
    assert(r_fp.sign == false, 'result 1b invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(r_fp.into() == 5 * SCALE_FP, 'result 1c invalid');

    let x_1_fp = FixedPt::from_felt(-40 * SCALE_FP);
    let y_1_fp = FixedPt::from_felt(-90 * SCALE_FP);
    let x_2_fp = FixedPt::from_felt(-10 * SCALE_FP);
    let y_2_fp = FixedPt::from_felt(-50 * SCALE_FP);
    let r_fp = distance_two_points_fp(x_1_fp, y_1_fp, x_2_fp, y_2_fp, );
    assert(r_fp.into() == 50 * SCALE_FP, 'result 2 invalid');

    let x_1_fp = FixedPt::from_felt(3 * SCALE_FP);
    let y_1_fp = FixedPt::from_felt(3 * SCALE_FP);
    let x_2_fp = FixedPt::from_felt(15 * SCALE_FP);
    let y_2_fp = FixedPt::from_felt(8 * SCALE_FP);
    let r_fp = distance_two_points_fp(x_1_fp, y_1_fp, x_2_fp, y_2_fp, );
    assert(r_fp.into() == 13 * SCALE_FP, 'result 3 invalid');

    let x_1_fp = FixedPt::from_felt(-9 * SCALE_FP);
    let y_1_fp = FixedPt::from_felt(3 * SCALE_FP);
    let x_2_fp = FixedPt::from_felt(3 * SCALE_FP);
    let y_2_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let r_fp = distance_two_points_fp(x_1_fp, y_1_fp, x_2_fp, y_2_fp, );
    assert(r_fp.into() == 13 * SCALE_FP, 'result 4 invalid');
}

#[test]
#[available_gas(20000000)]
fn test_cosine_8th_fp() {
    // Values used below in `assert` statements reflect the 
    //   fact that the approximation in `fn cosine_8th_fp` 
    //   is significantly less accurate for larger angles. 
    //   (This is the reason for `fn cos_approx_fp`.)

    // 0 deg
    let theta_deg_fp = FixedPt::from_felt(0 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    assert(cos_theta_fp.into() == 1 * SCALE_FP, 'result 1 invalid');

    // 60 deg
    let theta_deg_fp = FixedPt::from_felt(60 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = 0.5, but not exact so test if 0.499999 < mag < 0.500001
    assert(cos_theta_fp.mag > 4999990000_u128, 'result 2a invalid');
    assert(cos_theta_fp.mag < 5000010000_u128, 'result 2b invalid');
    assert(cos_theta_fp.sign == false, 'result 2c invalid');
    //
    // -60 deg
    let theta_deg_fp = FixedPt::from_felt(-60 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = 0.5, but not exact so test if 0.499999 < mag < 0.500001
    assert(cos_theta_fp.mag > 4999990000_u128, 'result 3a invalid');
    assert(cos_theta_fp.mag < 5000010000_u128, 'result 3b invalid');
    assert(cos_theta_fp.sign == false, 'result 3c invalid');

    // 90 deg
    let theta_deg_fp = FixedPt::from_felt(90 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = 0, but not exact so test if mag < 0.0001
    assert(cos_theta_fp.mag < 1000000_u128, 'result 4 invalid');
    //
    // -90 deg
    let theta_deg_fp = FixedPt::from_felt(-90 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = 0, but not exact so test if mag < 0.0001
    assert(cos_theta_fp.mag < 1000000_u128, 'result 5 invalid');

    // 120 deg
    let theta_deg_fp = FixedPt::from_felt(120 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = -0.5, but not exact so test if 0.499 < mag < 0.501
    assert(cos_theta_fp.mag > 4990000000_u128, 'result 6a invalid');
    assert(cos_theta_fp.mag < 5010000000_u128, 'result 6b invalid');
    assert(cos_theta_fp.sign == true, 'result 6c invalid');
    //
    // -120 deg
    let theta_deg_fp = FixedPt::from_felt(-120 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = -0.5, but not exact so test if 0.499 < mag < 0.501
    assert(cos_theta_fp.mag > 4990000000_u128, 'result 7a invalid');
    assert(cos_theta_fp.mag < 5010000000_u128, 'result 7b invalid');
    assert(cos_theta_fp.sign == true, 'result 7c invalid');

    // 180 deg
    let theta_deg_fp = FixedPt::from_felt(180 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = -1, but not exact so test if 0.97 < mag < 1.03
    assert(cos_theta_fp.mag > 9700000000_u128, 'result 8a invalid');
    assert(cos_theta_fp.mag < 10300000000_u128, 'result 8b invalid');
    assert(cos_theta_fp.sign == true, 'result 8c invalid');
    //
    // -180 deg
    let theta_deg_fp = FixedPt::from_felt(-180 * SCALE_FP);
    let theta_fp = FixedPt::fp_to_radians(theta_deg_fp);
    let cos_theta_fp = cosine_8th_fp(theta_fp);
    // Should be = -1, but not exact so test if 0.97 < mag < 1.03
    assert(cos_theta_fp.mag > 9700000000_u128, 'result 9a invalid');
    assert(cos_theta_fp.mag < 10300000000_u128, 'result 9b invalid');
    assert(cos_theta_fp.sign == true, 'result 9c invalid');
}

#[test]
#[available_gas(20000000)]
fn test_cos_approx_fp() {
    // `fn cos_approx_fp` takes arg `theta_deg_fp` which is needed
    // for exact comparisons before calculations are done

    // Values used below in `assert` statements, compared to 
    //   those used above in `test_cosine_8th_fp`, reflect the
    //   fact that `fn cos_approx_fp` significantly improves the
    //   cosine approximation for |theta_deg| >= 90 degrees.

    // 0 deg
    let theta_deg_fp = FixedPt::from_felt(0 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    assert(cos_theta_deg_fp.into() == 1 * SCALE_FP, 'result 1 invalid');

    // 60 deg
    let theta_deg_fp = FixedPt::from_felt(60 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be = 0.5, but not exact so test if 0.499999 < mag < 0.500001
    assert(cos_theta_deg_fp.mag > 4999990000_u128, 'result 2a invalid');
    assert(cos_theta_deg_fp.mag < 5000010000_u128, 'result 2b invalid');
    assert(cos_theta_deg_fp.sign == false, 'result 2c invalid');
    //
    // -60 deg
    let theta_deg_fp = FixedPt::from_felt(-60 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be = 0.5, but not exact so test if 0.499999 < mag < 0.500001
    assert(cos_theta_deg_fp.mag > 4999990000_u128, 'result 3a invalid');
    assert(cos_theta_deg_fp.mag < 5000010000_u128, 'result 3b invalid');
    assert(cos_theta_deg_fp.sign == false, 'result 3c invalid');

    // 90 deg
    let theta_deg_fp = FixedPt::from_felt(90 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be exactly 0
    assert(cos_theta_deg_fp.mag == 0_u128, 'result 4a invalid');
    assert(cos_theta_deg_fp.sign == false, 'result 4b invalid');
    //
    // -90 deg
    let theta_deg_fp = FixedPt::from_felt(-90 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be exactly 0
    assert(cos_theta_deg_fp.mag == 0_u128, 'result 5a invalid');
    assert(cos_theta_deg_fp.sign == false, 'result 5b invalid');

    // 120 deg
    let theta_deg_fp = FixedPt::from_felt(120 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be = -0.5, but not exact so test if 0.499999 < mag < 0.500001
    assert(cos_theta_deg_fp.mag > 4999990000_u128, 'result 6a invalid');
    assert(cos_theta_deg_fp.mag < 5000010000_u128, 'result 6b invalid');
    assert(cos_theta_deg_fp.sign == true, 'result 6c invalid');
    //
    // -120 deg
    let theta_deg_fp = FixedPt::from_felt(-120 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be = -0.5, but not exact so test if 0.499999 < mag < 0.500001
    assert(cos_theta_deg_fp.mag > 4999990000_u128, 'result 7a invalid');
    assert(cos_theta_deg_fp.mag < 5000010000_u128, 'result 7b invalid');
    assert(cos_theta_deg_fp.sign == true, 'result 7c invalid');

    // 180 deg
    let theta_deg_fp = FixedPt::from_felt(180 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be = -1, but not exact so test if 0.9999999 < mag < 1.0000001
    assert(cos_theta_deg_fp.mag > 9999999000_u128, 'result 8a invalid');
    assert(cos_theta_deg_fp.mag < 10000001000_u128, 'result 8b invalid');
    assert(cos_theta_deg_fp.sign == true, 'result 8c invalid');
    //
    // -180 deg
    let theta_deg_fp = FixedPt::from_felt(-180 * SCALE_FP);
    let cos_theta_deg_fp = cos_approx_fp(theta_deg_fp);
    // Should be = -1, but not exact so test if 0.9999999 < mag < 1.0000001
    assert(cos_theta_deg_fp.mag > 9999999000_u128, 'result 9a invalid');
    assert(cos_theta_deg_fp.mag < 10000001000_u128, 'result 9b invalid');
    assert(cos_theta_deg_fp.sign == true, 'result 9c invalid');
}

#[test]
#[available_gas(20000000)]
fn test_sin_approx_fp() {
    // `fn sin_approx_fp` takes arg `theta_deg_fp` like `fn cos_approx_fp`

    // 0 deg
    let theta_deg_fp = FixedPt::from_felt(0 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    assert(sin_theta_deg_fp.into() == 0 * SCALE_FP, 'result 1 invalid');

    // 30 deg
    let theta_deg_fp = FixedPt::from_felt(30 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be = 0.5, but not exact so test if 0.4999 < mag < 0.5001
    assert(sin_theta_deg_fp.mag > 4999000000_u128, 'result 2a invalid');
    assert(sin_theta_deg_fp.mag < 5001000000_u128, 'result 2b invalid');
    assert(sin_theta_deg_fp.sign == false, 'result 2c invalid');
    //
    // -30 deg
    let theta_deg_fp = FixedPt::from_felt(-30 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be = -0.5, but not exact so test if 0.4999 < mag < 0.5001
    assert(sin_theta_deg_fp.mag > 4999000000_u128, 'result 3a invalid');
    assert(sin_theta_deg_fp.mag < 5001000000_u128, 'result 3b invalid');
    assert(sin_theta_deg_fp.sign == true, 'result 3c invalid');

    // 90 deg
    let theta_deg_fp = FixedPt::from_felt(90 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be exactly 1
    assert(sin_theta_deg_fp.mag == 1_u128 * SCALE_FP_u128, 'result 4a invalid');
    assert(sin_theta_deg_fp.sign == false, 'result 4b invalid');
    //
    // -90 deg
    let theta_deg_fp = FixedPt::from_felt(-90 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be exactly -1
    assert(sin_theta_deg_fp.mag == 1_u128 * SCALE_FP_u128, 'result 5a invalid');
    assert(sin_theta_deg_fp.sign == true, 'result 5b invalid');

    // 150 deg
    let theta_deg_fp = FixedPt::from_felt(150 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be = 0.5, but not exact so test if 0.4999 < mag < 0.5001
    assert(sin_theta_deg_fp.mag > 4999000000_u128, 'result 6a invalid');
    assert(sin_theta_deg_fp.mag < 5001000000_u128, 'result 6b invalid');
    assert(sin_theta_deg_fp.sign == false, 'result 6c invalid');
    //
    // -150 deg
    let theta_deg_fp = FixedPt::from_felt(-150 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be = -0.5, but not exact so test if 0.4999 < mag < 0.5001
    assert(sin_theta_deg_fp.mag > 4999000000_u128, 'result 7a invalid');
    assert(sin_theta_deg_fp.mag < 5001000000_u128, 'result 7b invalid');
    assert(sin_theta_deg_fp.sign == true, 'result 7c invalid');

    // 180 deg
    let theta_deg_fp = FixedPt::from_felt(180 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be exactly 0
    assert(sin_theta_deg_fp.mag == 0_u128, 'result 8a invalid');
    assert(sin_theta_deg_fp.sign == false, 'result 8b invalid');
    //
    // -180 deg
    let theta_deg_fp = FixedPt::from_felt(-180 * SCALE_FP);
    let sin_theta_deg_fp = sin_approx_fp(theta_deg_fp);
    // Should be exactly 0
    assert(sin_theta_deg_fp.mag == 0_u128, 'result 9a invalid');
    assert(sin_theta_deg_fp.sign == false, 'result 9b invalid');
}

