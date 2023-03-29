// use option::OptionTrait;
use traits::Into;
use array::ArrayTrait;

use gas::withdraw_gas;
use gas::withdraw_gas_all;

use projectile::constants::SCALE_FP;
use projectile::constants::SCALE_FP_u128;
// use projectile::constants::SCALE_FP_SQRT;
// use projectile::constants::SCALE_FP_SQRT_u128;
use projectile::constants::HALF_PRIME;
use projectile::fixed_point::FixedPt;
use projectile::fixed_point::FixedPtType;
use projectile::fixed_point::FixedPtInto; // needed to call c_fp.into()
// use projectile::math;

#[test]
// #[available_gas(9999999)]
fn test_fixed_pt_sqrt() {
    // match gas::withdraw_gas() {
    //     Option::Some(_) => {},
    //     Option::None(_) => {
    //         let mut data = ArrayTrait::new();
    //         data.append('Out of gas');
    //         panic(data);
    //     },
    // }

    //Tests `fn sqrt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(900 * SCALE_FP);
    let c_fp = FixedPt::sqrt(a_fp);
    assert(c_fp.mag == 30_u128 * SCALE_FP_u128, 'result 1ai invalid');
    assert(c_fp.sign == false, 'result 1aii invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(c_fp.into() == 30 * SCALE_FP, 'result 1aiii invalid');
    //
    let a_fp = FixedPt::from_felt(16000000); // 0.0016
    let c_fp = FixedPt::sqrt(a_fp);
    assert(c_fp.mag == 400000000_u128, 'result 2ai invalid'); // 0.04
    assert(c_fp.sign == false, 'result 2aii invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(c_fp.into() == 400000000, 'result 2aiii invalid');
}


#[test]
// #[available_gas(9999999)]
fn test_fixed_pt_add() {
    // match gas::withdraw_gas() {
    //     Option::Some(_) => {},
    //     Option::None(_) => {
    //         let mut data = ArrayTrait::new();
    //         data.append('Out of gas');
    //         panic(data);
    //     },
    // }

    // (+)(+)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    // Tests `impl FixedPtAdd of Add::<FixedPtType>`
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 1ai invalid');
    assert(c_fp.sign == false, 'result 1aii invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(c_fp.into() == 7 * SCALE_FP, 'result 1aiii invalid');
    //
    //Tests `fn new` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::new(5_u128 * SCALE_FP_u128, false);
    let b_fp = FixedPt::new(2_u128 * SCALE_FP_u128, false);
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 1bi invalid');
    assert(c_fp.sign == false, 'result 1bii invalid');
    assert(c_fp.into() == 7 * SCALE_FP, 'result 1biii invalid');
    // //
    // let a_fp = FixedPt::from_felt(5000 * SCALE_FP);
    // let b_fp = FixedPt::from_felt(2000 * SCALE_FP);
    // let c_fp = a_fp + b_fp;
    // assert(c_fp.into() == 7000 * SCALE_FP, 'result 2 invalid');
    // //
    // let a_fp = FixedPt::from_felt(50000000000000); // 5000
    // let b_fp = FixedPt::from_felt(20000000000000); // 2000
    // let c_fp = a_fp + b_fp;
    // assert(c_fp.into() == 70000000000000, 'result 3 invalid'); // 7000
    // //
    // let a_fp = FixedPt::from_felt(4000000000); // 0.4
    // let b_fp = FixedPt::from_felt(2000000000); // 0.2
    // let c_fp = a_fp + b_fp;
    // assert(c_fp.into() == 6000000000, 'result 4 invalid'); // 0.6
    // //
    // // max values before overflow
    // let a_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    // let b_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    // let c_fp = a_fp + b_fp;
    // assert(c_fp.into() == 36893488147419103230, 'result 5 invalid'); // 3689348814.7419103230

    // (0)(+)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 6ai invalid');
    assert(c_fp.sign == false, 'result 6aii invalid');
    assert(c_fp.into() == 2 * SCALE_FP, 'result 6aiii invalid');

    // // (+)(0)
    // let a_fp = FixedPt::from_felt(2 * SCALE_FP);
    // let b_fp = FixedPt::from_felt(0);
    // let c_fp = a_fp + b_fp;
    // assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 7i invalid');
    // assert(c_fp.sign == false, 'result 7ii invalid');
    // assert(c_fp.into() == 2 * SCALE_FP, 'result 7iii invalid');

    // (+)(-)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 8ai invalid');
    assert(c_fp.sign == false, 'result 8aii invalid');
    assert(c_fp.into() == 3 * SCALE_FP, 'result 8aiii invalid');
    //
    //Tests `fn new` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::new(5_u128 * SCALE_FP_u128, false); // 5
    let b_fp = FixedPt::new(2_u128 * SCALE_FP_u128, true); // -2
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 8bi invalid');
    assert(c_fp.sign == false, 'result 8bii invalid');
    assert(c_fp.into() == 3 * SCALE_FP, 'result 8biii invalid');

    // // (-)(+)
    // let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    // let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    // let c_fp = a_fp + b_fp;
    // assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 9i invalid');
    // assert(c_fp.sign == true, 'result 9ii invalid');
    // assert(c_fp.into() == -3 * SCALE_FP, 'result 9iii invalid');

    // (-)(-)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 10i invalid');
    assert(c_fp.sign == true, 'result 10ii invalid');
    assert(c_fp.into() == -7 * SCALE_FP, 'result 10iii invalid');

    // (0)(-)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp + b_fp;
    assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 11i invalid');
    assert(c_fp.sign == true, 'result 11ii invalid');
    assert(c_fp.into() == -2 * SCALE_FP, 'result 11iii invalid');
// // (-)(0)
// let a_fp = FixedPt::from_felt(-2 * SCALE_FP);
// let b_fp = FixedPt::from_felt(0);
// let c_fp = a_fp + b_fp;
// assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 12i invalid');
// assert(c_fp.sign == true, 'result 12ii invalid');
// assert(c_fp.into() == -2 * SCALE_FP, 'result 12iii invalid');
}

#[test]
// #[available_gas(9999999)]
fn test_fixed_pt_sub() {
    // match gas::withdraw_gas() {
    //     Option::Some(_) => {},
    //     Option::None(_) => {
    //         let mut data = ArrayTrait::new();
    //         data.append('Out of gas');
    //         panic(data);
    //     },
    // }

    // (+)(+)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    // Tests `impl FixedPtSub of Sub::<FixedPtType>>`
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 1ai invalid');
    assert(c_fp.sign == false, 'result 1aii invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(c_fp.into() == 3 * SCALE_FP, 'result 1aiii invalid');
    //
    //Tests `fn new` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::new(5_u128 * SCALE_FP_u128, false);
    let b_fp = FixedPt::new(2_u128 * SCALE_FP_u128, false);
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 1bi invalid');
    assert(c_fp.sign == false, 'result 1bii invalid');
    assert(c_fp.into() == 3 * SCALE_FP, 'result 1biii invalid');
    //
    // let a_fp = FixedPt::from_felt(5000 * SCALE_FP);
    // let b_fp = FixedPt::from_felt(2000 * SCALE_FP);
    // let c_fp = a_fp - b_fp;
    // assert(c_fp.into() == 3000 * SCALE_FP, 'result 2 invalid');
    // //
    // let a_fp = FixedPt::from_felt(4000000000); // 0.4
    // let b_fp = FixedPt::from_felt(2000000000); // 0.2
    // let c_fp = a_fp - b_fp;
    // assert(c_fp.into() == 2000000000, 'result 4 invalid'); // 0.2
    // //
    // // max values before overflow
    // let a_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    // let b_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    // let c_fp = a_fp - b_fp;
    // assert(c_fp.mag == 0_u128, 'result 5i invalid'); // 0
    // assert(c_fp.sign == false, 'result 5ii invalid');
    // assert(c_fp.into() == 0, 'result 5iii invalid');

    // (0)(+)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 6i invalid');
    assert(c_fp.sign == true, 'result 6ii invalid');
    assert(c_fp.into() == -2 * SCALE_FP, 'result 6iii invalid');

    // // (+)(0)
    // let a_fp = FixedPt::from_felt(2 * SCALE_FP);
    // let b_fp = FixedPt::from_felt(0);
    // let c_fp = a_fp - b_fp;
    // assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 7i invalid');
    // assert(c_fp.sign == false, 'result 7ii invalid');
    // assert(c_fp.into() == 2 * SCALE_FP, 'result 7iii invalid');

    // (+)(-)
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 8i invalid');
    assert(c_fp.sign == false, 'result 8ii invalid');
    assert(c_fp.into() == 7 * SCALE_FP, 'result 8iii invalid');

    // (-)(+)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 7_u128 * SCALE_FP_u128, 'result 9i invalid');
    assert(c_fp.sign == true, 'result 9ii invalid');
    assert(c_fp.into() == -7 * SCALE_FP, 'result 9iii invalid');

    // (-)(-)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 3_u128 * SCALE_FP_u128, 'result 10ai invalid');
    assert(c_fp.sign == true, 'result 10aii invalid');
    assert(c_fp.into() == -3 * SCALE_FP, 'result 10aiii invalid');

    // (0)(-)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp - b_fp;
    assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 11i invalid');
    assert(c_fp.sign == false, 'result 11ii invalid');
    assert(c_fp.into() == 2 * SCALE_FP, 'result 11iii invalid');
// // (-)(0)
// let a_fp = FixedPt::from_felt(-2 * SCALE_FP);
// let b_fp = FixedPt::from_felt(0);
// let c_fp = a_fp - b_fp;
// assert(c_fp.mag == 2_u128 * SCALE_FP_u128, 'result 12i invalid');
// assert(c_fp.sign == true, 'result 12ii invalid');
// assert(c_fp.into() == -2 * SCALE_FP, 'result 12iii invalid');
}

#[test]
// #[available_gas(9999999)]
fn test_fixed_pt_mult() {
    // match gas::withdraw_gas() {
    //     Option::Some(_) => {},
    //     Option::None(_) => {
    //         let mut data = ArrayTrait::new();
    //         data.append('Out of gas');
    //         panic(data);
    //     },
    // }

    // (+)(+)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    // Tests `impl FixedPtMul of Mul::<FixedPtType>`
    let c_fp = a_fp * b_fp;
    assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 1i invalid');
    assert(c_fp.sign == false, 'result 1ii invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(c_fp.into() == 10 * SCALE_FP, 'result 1iii invalid');
    //
    let a_fp = FixedPt::from_felt(5000 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2000 * SCALE_FP);
    let c_fp = a_fp * b_fp;
    assert(c_fp.into() == 10000000 * SCALE_FP, 'result 2 invalid');
    //
    let a_fp = FixedPt::from_felt(4000000000); // 0.4
    let b_fp = FixedPt::from_felt(2000000000); // 0.2
    let c_fp = a_fp * b_fp;
    assert(c_fp.into() == 800000000, 'result 4 invalid'); // 0.08
    //
    // max values before overflow
    let a_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    let b_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    let c_fp = a_fp * b_fp;
    assert(c_fp.into() == 34028236692093846342648111928, 'result 5 invalid');
    // 3402823669209384634.2648111928

    // (0)(+)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp * b_fp;
    assert(c_fp.mag == 0_u128, 'result 6i invalid');
    assert(c_fp.sign == false, 'result 6ii invalid');
    assert(c_fp.into() == 0, 'result 6iii invalid');

    // // (+)(0)
    // let a_fp = FixedPt::from_felt(2 * SCALE_FP);
    // let b_fp = FixedPt::from_felt(0);
    // let c_fp = a_fp * b_fp;
    // assert(c_fp.mag == 0_u128, 'result 7i invalid');
    // assert(c_fp.sign == false, 'result 7ii invalid');
    // assert(c_fp.into() == 0, 'result 7iii invalid');

    // (+)(-)
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp * b_fp;
    assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 8i invalid');
    assert(c_fp.sign == true, 'result 8ii invalid');
    assert(c_fp.into() == -10 * SCALE_FP, 'result 8iii invalid');

    // (-)(+)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp * b_fp;
    assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 9i invalid');
    assert(c_fp.sign == true, 'result 9ii invalid');
    assert(c_fp.into() == -10 * SCALE_FP, 'result 9iii invalid');

    // (-)(-)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp * b_fp;
    assert(c_fp.mag == 10_u128 * SCALE_FP_u128, 'result 10i invalid');
    assert(c_fp.sign == false, 'result 10ii invalid');
    assert(c_fp.into() == 10 * SCALE_FP, 'result 10iii invalid');

    // (0)(-)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp * b_fp;
    assert(c_fp.mag == 0_u128, 'result 11i invalid');
    assert(c_fp.sign == false, 'result 11ii invalid');
    assert(c_fp.into() == 0, 'result 11iii invalid');
// // (-)(0)
// let a_fp = FixedPt::from_felt(-2 * SCALE_FP);
// let b_fp = FixedPt::from_felt(0);
// let c_fp = a_fp * b_fp;
// assert(c_fp.mag == 0_u128, 'result 12i invalid');
// assert(c_fp.sign == false, 'result 12ii invalid');
// assert(c_fp.into() == 0, 'result 12iii invalid');
}

#[test]
// #[available_gas(9999999)]
fn test_fixed_pt_div() {
    // match gas::withdraw_gas() {
    //     Option::Some(_) => {},
    //     Option::None(_) => {
    //         let mut data = ArrayTrait::new();
    //         data.append('Out of gas');
    //         panic(data);
    //     },
    // }

    // (+)(+)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    // Tests `impl FixedPtDiv of Div::<FixedPtType>`
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 25000000000_u128, 'result 1ai invalid'); // 2.5
    assert(c_fp.sign == false, 'result 1aii invalid');
    // Tests `impl FixedPtInto of Into::<FixedPtType, felt252>`
    assert(c_fp.into() == 25000000000, 'result 1aiii invalid'); // 2.5
    //
    //Tests `fn new` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::new(5_u128 * SCALE_FP_u128, false);
    let b_fp = FixedPt::new(2_u128 * SCALE_FP_u128, false);
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 25000000000_u128, 'result 1ai invalid'); // 2.5
    assert(c_fp.sign == false, 'result 1aii invalid');
    assert(c_fp.into() == 25000000000, 'result 1aiii invalid'); // 2.5
    //
    let a_fp = FixedPt::from_felt(2000 * SCALE_FP);
    let b_fp = FixedPt::from_felt(5000 * SCALE_FP);
    let c_fp = a_fp / b_fp;
    assert(c_fp.into() == 4000000000, 'result 2 invalid'); // 0.4
    //
    let a_fp = FixedPt::from_felt(4000000000); // 0.4
    let b_fp = FixedPt::from_felt(2000000000); // 0.2
    let c_fp = a_fp / b_fp;
    assert(c_fp.into() == 20000000000, 'result 4 invalid'); // 2
    //
    // max values before overflow
    let a_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    let b_fp = FixedPt::from_felt(18446744073709551615); // 2^64 - 1, 1844674407.3709551615
    let c_fp = a_fp / b_fp;
    assert(c_fp.into() == 10000000000, 'result 5 invalid'); // 1.0

    // (0)(+)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 0_u128, 'result 6i invalid');
    assert(c_fp.sign == false, 'result 6ii invalid');
    assert(c_fp.into() == 0, 'result 6iii invalid');

    // (+)(-)
    //Tests `fn from_felt` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::from_felt(5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 25000000000_u128, 'result 8ai invalid'); // 2.5
    assert(c_fp.sign == true, 'result 8aii invalid');
    assert(c_fp.into() == -25000000000, 'result 8aiii invalid'); // -2.5
    //
    //Tests `fn new` of `impl FixedPtImpl of FixedPt`
    let a_fp = FixedPt::new(5_u128 * SCALE_FP_u128, false); // 5
    let b_fp = FixedPt::new(2_u128 * SCALE_FP_u128, true); // -2
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 25000000000_u128, 'result 8bi invalid'); // 2.5
    assert(c_fp.sign == true, 'result 8bii invalid');
    assert(c_fp.into() == -25000000000, 'result 8biii invalid'); // -2.5

    // (-)(+)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(2 * SCALE_FP);
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 25000000000_u128, 'result 9i invalid'); // 2.5
    assert(c_fp.sign == true, 'result 9ii invalid');
    assert(c_fp.into() == -25000000000, 'result 9iii invalid'); // -2.5

    // (-)(-)
    let a_fp = FixedPt::from_felt(-5 * SCALE_FP);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 25000000000_u128, 'result 10i invalid'); // 2.5
    assert(c_fp.sign == false, 'result 10ii invalid');
    assert(c_fp.into() == 25000000000, 'result 10iii invalid'); // 2.5

    // (0)(-)
    let a_fp = FixedPt::from_felt(0);
    let b_fp = FixedPt::from_felt(-2 * SCALE_FP);
    let c_fp = a_fp / b_fp;
    assert(c_fp.mag == 0_u128, 'result 11i invalid');
    assert(c_fp.sign == false, 'result 11ii invalid');
    assert(c_fp.into() == 0, 'result 11iii invalid');
}

