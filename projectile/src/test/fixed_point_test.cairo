// use traits::Into;

// // use gas::withdraw_gas;
// // use gas::withdraw_gas_all;

// use projectile::constants::SCALE_FP;
// use projectile::constants::SCALE_FP_u128;
// use projectile::fixed_point::Fixed;
// use projectile::fixed_point::FixedType;
// use projectile::fixed_point::FixedInto;

// #[test]
// #[available_gas(20000000)]
// fn test_fp_sqrt() {
//     // match gas::withdraw_gas() {
//     //     Option::Some(_) => {},
//     //     Option::None(_) => {
//     //         let mut data = ArrayTrait::new();
//     //         data.append('Out of gas');
//     //         panic(data);
//     //     },
//     // }

//     //Tests `fn from_felt` of `impl FixedImpl of Fixed`
//     let a_fp = Fixed::from_felt(900 * SCALE_FP);
//     //Tests `fn fp_sqrt` of `impl FixedImpl of Fixed`
//     let c_fp = Fixed::fp_sqrt(a_fp);
//     assert(c_fp.mag == 30_u128 * SCALE_FP_u128, 'result 1a invalid');
//     assert(c_fp.sign == false, 'result 1b invalid');
//     // Tests `impl FixedInto of Into::<FixedType, felt252>`
//     assert(c_fp.into() == 30 * SCALE_FP, 'result 1c invalid');

//     let a_fp = Fixed::from_felt(16000000); // 0.0016
//     let c_fp = Fixed::fp_sqrt(a_fp);
//     assert(c_fp.mag == 400000000_u128, 'result 2a invalid'); // 0.04
//     assert(c_fp.sign == false, 'result 2b invalid');
//     // Tests `impl FixedInto of Into::<FixedType, felt252>`
//     assert(c_fp.into() == 400000000, 'result 2c invalid');
// }

// #[test]
// #[available_gas(20000000)]
// fn test_fp_to_radians() {
//     //Tests `fn fp_to_radians` of `impl FixedImpl of Fixed`

//     // 0 deg
//     let theta_deg_fp = Fixed::from_felt(0 * SCALE_FP);
//     let theta_fp = Fixed::fp_to_radians(theta_deg_fp);
//     assert(theta_fp.into() == 0, 'result 1 invalid');

//     // 90 deg
//     let theta_deg_fp = Fixed::from_felt(90 * SCALE_FP);
//     let theta_fp = Fixed::fp_to_radians(theta_deg_fp);
//     assert(theta_fp.into() == 15707963268, 'result 2 invalid');

//     // -90 deg
//     let theta_deg_fp = Fixed::from_felt(-90 * SCALE_FP);
//     let theta_fp = Fixed::fp_to_radians(theta_deg_fp);
//     assert(theta_fp.into() == -15707963268, 'result 3 invalid');
// }

// #[test]
// #[available_gas(20000000)]
// fn test_fixed_pt_add() {
//     // match gas::withdraw_gas() {
//     //     Option::Some(_) => {},
//     //     Option::None(_) => {
//     //         let mut data = ArrayTrait::new();
//     //         data.append('Out of gas');
//     //         panic(data);
//     //     },
//     // }

//     // (+)(+)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     // Tests `impl FixedAdd of Add::<FixedType>`
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 1a invalid');
//     assert(c_fp.sign == false, 'result 1b invalid');
//     assert(c_fp.into() == 7 * SCALE_FP, 'result 1c invalid');
//     //
//     let a_fp = Fixed::new(5_u128 * SCALE_FP_u128, false);
//     let b_fp = Fixed::new(2_u128 * SCALE_FP_u128, false);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 2a invalid');
//     assert(c_fp.sign == false, 'result 2b invalid');
//     assert(c_fp.into() == 7 * SCALE_FP, 'result 2c invalid');
//     //
//     let a_fp = Fixed::from_felt(5000 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2000 * SCALE_FP);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.into() == 7000 * SCALE_FP, 'result 3 invalid');
//     //
//     let a_fp = Fixed::from_felt(50000000000000); // 5000
//     let b_fp = Fixed::from_felt(20000000000000); // 2000
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.into() == 70000000000000, 'result 4 invalid'); // 7000
//     //
//     let a_fp = Fixed::from_felt(4000000000); // 0.4
//     let b_fp = Fixed::from_felt(2000000000); // 0.2
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.into() == 6000000000, 'result 5 invalid'); // 0.6
//     //
//     // 2^64 - 1, or 1844674407.3709551615
//     let a_fp = Fixed::from_felt(18446744073709551615);
//     let b_fp = Fixed::from_felt(18446744073709551615);
//     let c_fp = a_fp + b_fp;
//     // 3689348814.7419103230
//     assert(c_fp.into() == 36893488147419103230, 'result 6 invalid');

//     // (0)(+)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 7a invalid');
//     assert(c_fp.sign == false, 'result 7b invalid');
//     assert(c_fp.into() == 2 * SCALE_FP, 'result 7c invalid');

//     // (+)(0)
//     let a_fp = Fixed::from_felt(2 * SCALE_FP);
//     let b_fp = Fixed::from_felt(0);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 8a invalid');
//     assert(c_fp.sign == false, 'result 8b invalid');
//     assert(c_fp.into() == 2 * SCALE_FP, 'result 8c invalid');

//     // (+)(-)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 9a invalid');
//     assert(c_fp.sign == false, 'result 9b invalid');
//     assert(c_fp.into() == 3 * SCALE_FP, 'result 9c invalid');
//     //
//     let a_fp = Fixed::new(5_u128 * SCALE_FP_u128, false); // 5
//     let b_fp = Fixed::new(2_u128 * SCALE_FP_u128, true); // -2
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 10a invalid');
//     assert(c_fp.sign == false, 'result 10b invalid');
//     assert(c_fp.into() == 3 * SCALE_FP, 'result 10c invalid');

//     // (-)(+)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 11a invalid');
//     assert(c_fp.sign == true, 'result 11b invalid');
//     assert(c_fp.into() == -3 * SCALE_FP, 'result 11c invalid');

//     // (-)(-)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 12a invalid');
//     assert(c_fp.sign == true, 'result 12b invalid');
//     assert(c_fp.into() == -7 * SCALE_FP, 'result 12c invalid');

//     // (0)(-)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 13a invalid');
//     assert(c_fp.sign == true, 'result 13b invalid');
//     assert(c_fp.into() == -2 * SCALE_FP, 'result 13c invalid');

//     // (-)(0)
//     let a_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let b_fp = Fixed::from_felt(0);
//     let c_fp = a_fp + b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 14a invalid');
//     assert(c_fp.sign == true, 'result 14b invalid');
//     assert(c_fp.into() == -2 * SCALE_FP, 'result 14c invalid');
// }

// #[test]
// #[available_gas(20000000)]
// fn test_fixed_pt_sub() {
//     // match gas::withdraw_gas() {
//     //     Option::Some(_) => {},
//     //     Option::None(_) => {
//     //         let mut data = ArrayTrait::new();
//     //         data.append('Out of gas');
//     //         panic(data);
//     //     },
//     // }

//     // (+)(+)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     // Tests `impl FixedSub of Sub::<FixedType>`
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 1a invalid');
//     assert(c_fp.sign == false, 'result 1b invalid');
//     assert(c_fp.into() == 3 * SCALE_FP, 'result 1c invalid');
//     //
//     let a_fp = Fixed::new(5_u128 * SCALE_FP_u128, false);
//     let b_fp = Fixed::new(2_u128 * SCALE_FP_u128, false);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 2a invalid');
//     assert(c_fp.sign == false, 'result 2b invalid');
//     assert(c_fp.into() == 3 * SCALE_FP, 'result 2c invalid');

//     let a_fp = Fixed::from_felt(5000 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2000 * SCALE_FP);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.into() == 3000 * SCALE_FP, 'result 3 invalid');
//     //
//     let a_fp = Fixed::from_felt(4000000000); // 0.4
//     let b_fp = Fixed::from_felt(2000000000); // 0.2
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.into() == 2000000000, 'result 4 invalid'); // 0.2
//     //
//     // // 2^64 - 1, 1844674407.3709551615
//     let a_fp = Fixed::from_felt(18446744073709551615);
//     let b_fp = Fixed::from_felt(18446744073709551615);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 0_u128, 'result 5a invalid'); // 0
//     assert(c_fp.sign == false, 'result 5b invalid');
//     assert(c_fp.into() == 0, 'result 5c invalid');

//     // (0)(+)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 6a invalid');
//     assert(c_fp.sign == true, 'result 6b invalid');
//     assert(c_fp.into() == -2 * SCALE_FP, 'result 6c invalid');

//     // (+)(0)
//     let a_fp = Fixed::from_felt(2 * SCALE_FP);
//     let b_fp = Fixed::from_felt(0);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 7a invalid');
//     assert(c_fp.sign == false, 'result 7b invalid');
//     assert(c_fp.into() == 2 * SCALE_FP, 'result 7c invalid');

//     // (+)(-)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 8a invalid');
//     assert(c_fp.sign == false, 'result 8b invalid');
//     assert(c_fp.into() == 7 * SCALE_FP, 'result 8c invalid');

//     // (-)(+)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 9a invalid');
//     assert(c_fp.sign == true, 'result 9b invalid');
//     assert(c_fp.into() == -7 * SCALE_FP, 'result 9c invalid');

//     // (-)(-)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 10a invalid');
//     assert(c_fp.sign == true, 'result 10b invalid');
//     assert(c_fp.into() == -3 * SCALE_FP, 'result 10c invalid');

//     // (0)(-)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 11a invalid');
//     assert(c_fp.sign == false, 'result 11b invalid');
//     assert(c_fp.into() == 2 * SCALE_FP, 'result 11c invalid');

//     // (-)(0)
//     let a_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let b_fp = Fixed::from_felt(0);
//     let c_fp = a_fp - b_fp;
//     assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 12a invalid');
//     assert(c_fp.sign == true, 'result 12b invalid');
//     assert(c_fp.into() == -2 * SCALE_FP, 'result 12c invalid');
// }

// #[test]
// #[available_gas(20000000)]
// fn test_fixed_pt_mult() {
//     // match gas::withdraw_gas() {
//     //     Option::Some(_) => {},
//     //     Option::None(_) => {
//     //         let mut data = ArrayTrait::new();
//     //         data.append('Out of gas');
//     //         panic(data);
//     //     },
//     // }

//     // (+)(+)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     // Tests `impl FixedMul of Mul::<FixedType>`
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 1a invalid');
//     assert(c_fp.sign == false, 'result 1b invalid');
//     assert(c_fp.into() == 10 * SCALE_FP, 'result 1c invalid');
//     //
//     let a_fp = Fixed::from_felt(5000 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2000 * SCALE_FP);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.into() == 10000000 * SCALE_FP, 'result 2 invalid');
//     //
//     let a_fp = Fixed::from_felt(4000000000); // 0.4
//     let b_fp = Fixed::from_felt(2000000000); // 0.2
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.into() == 800000000, 'result 3 invalid'); // 0.08
//     //
//     // max values before 'u128_mul Overflow', 2^64 - 1, or 1844674407.3709551615
//     let a_fp = Fixed::from_felt(18446744073709551615);
//     let b_fp = Fixed::from_felt(18446744073709551615);
//     let c_fp = a_fp * b_fp;
//     // 3402823669209384634.2648111928
//     assert(c_fp.into() == 34028236692093846342648111928, 'result 4 invalid');

//     // (0)(+)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 0_u128, 'result 5a invalid');
//     assert(c_fp.sign == false, 'result 5b invalid');
//     assert(c_fp.into() == 0, 'result 5c invalid');

//     // (+)(0)
//     let a_fp = Fixed::from_felt(2 * SCALE_FP);
//     let b_fp = Fixed::from_felt(0);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 0_u128, 'result 6a invalid');
//     assert(c_fp.sign == false, 'result 6b invalid');
//     assert(c_fp.into() == 0, 'result 6c invalid');

//     // (+)(-)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 7a invalid');
//     assert(c_fp.sign == true, 'result 7b invalid');
//     assert(c_fp.into() == -10 * SCALE_FP, 'result 7c invalid');

//     // (-)(+)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 8a invalid');
//     assert(c_fp.sign == true, 'result 8b invalid');
//     assert(c_fp.into() == -10 * SCALE_FP, 'result 8c invalid');

//     // (-)(-)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 9a invalid');
//     assert(c_fp.sign == false, 'result 9b invalid');
//     assert(c_fp.into() == 10 * SCALE_FP, 'result 9c invalid');

//     // (0)(-)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 0_u128, 'result 10a invalid');
//     assert(c_fp.sign == false, 'result 10b invalid');
//     assert(c_fp.into() == 0, 'result 10c invalid');

//     // (-)(0)
//     let a_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let b_fp = Fixed::from_felt(0);
//     let c_fp = a_fp * b_fp;
//     assert(c_fp.mag == 0_u128, 'result 11a invalid');
//     assert(c_fp.sign == false, 'result 11b invalid');
//     assert(c_fp.into() == 0, 'result 11c invalid');
// }

// #[test]
// #[available_gas(20000000)]
// fn test_fixed_pt_div() {
//     // match gas::withdraw_gas() {
//     //     Option::Some(_) => {},
//     //     Option::None(_) => {
//     //         let mut data = ArrayTrait::new();
//     //         data.append('Out of gas');
//     //         panic(data);
//     //     },
//     // }

//     // (+)(+)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     // Tests `impl FixedDiv of Div::<FixedType>`
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 25000000000_u128, 'result 1a invalid'); // 2.5
//     assert(c_fp.sign == false, 'result 1b invalid');
//     assert(c_fp.into() == 25000000000, 'result 1c invalid'); // 2.5
//     //
//     let a_fp = Fixed::new(5_u128 * SCALE_FP_u128, false);
//     let b_fp = Fixed::new(2_u128 * SCALE_FP_u128, false);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 25000000000_u128, 'result 2a invalid'); // 2.5
//     assert(c_fp.sign == false, 'result 2b invalid');
//     assert(c_fp.into() == 25000000000, 'result 2c invalid'); // 2.5
//     //
//     let a_fp = Fixed::from_felt(2000 * SCALE_FP);
//     let b_fp = Fixed::from_felt(5000 * SCALE_FP);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.into() == 4000000000, 'result 3 invalid'); // 0.4
//     //
//     let a_fp = Fixed::from_felt(4000000000); // 0.4
//     let b_fp = Fixed::from_felt(2000000000); // 0.2
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.into() == 20000000000, 'result 4 invalid'); // 2
//     //
//     // 2^64 - 1, 1844674407.3709551615
//     let a_fp = Fixed::from_felt(18446744073709551615);
//     let b_fp = Fixed::from_felt(18446744073709551615);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.into() == 10000000000, 'result 5 invalid'); // 1.0

//     // (0)(+)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 0_u128, 'result 6a invalid');
//     assert(c_fp.sign == false, 'result 6b invalid');
//     assert(c_fp.into() == 0, 'result 6c invalid');

//     // (+)(-)
//     let a_fp = Fixed::from_felt(5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 25000000000_u128, 'result 7a invalid'); // 2.5
//     assert(c_fp.sign == true, 'result 7b invalid');
//     assert(c_fp.into() == -25000000000, 'result 7c invalid'); // -2.5
//     //
//     let a_fp = Fixed::new(5_u128 * SCALE_FP_u128, false); // 5
//     let b_fp = Fixed::new(2_u128 * SCALE_FP_u128, true); // -2
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 25000000000_u128, 'result 8a invalid'); // 2.5
//     assert(c_fp.sign == true, 'result 8b invalid');
//     assert(c_fp.into() == -25000000000, 'result 8c invalid'); // -2.5

//     // (-)(+)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(2 * SCALE_FP);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 25000000000_u128, 'result 9a invalid'); // 2.5
//     assert(c_fp.sign == true, 'result 9b invalid');
//     assert(c_fp.into() == -25000000000, 'result 9c invalid'); // -2.5

//     // (-)(-)
//     let a_fp = Fixed::from_felt(-5 * SCALE_FP);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 25000000000_u128, 'result 10a invalid'); // 2.5
//     assert(c_fp.sign == false, 'result 10b invalid');
//     assert(c_fp.into() == 25000000000, 'result 10c invalid'); // 2.5

//     // (0)(-)
//     let a_fp = Fixed::from_felt(0);
//     let b_fp = Fixed::from_felt(-2 * SCALE_FP);
//     let c_fp = a_fp / b_fp;
//     assert(c_fp.mag == 0_u128, 'result 11a invalid');
//     assert(c_fp.sign == false, 'result 11b invalid');
//     assert(c_fp.into() == 0, 'result 11c invalid');
// }

