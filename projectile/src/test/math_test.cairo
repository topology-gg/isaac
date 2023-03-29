// use option::OptionTrait;
use traits::Into;

use gas::withdraw_gas;
use gas::withdraw_gas_all;

use projectile::constants;
use projectile::fixed_point::FixedPt;
// use projectile::fixed_point::FixedPtInto;
use projectile::fixed_point::FixedPtType;
use projectile::math;
// #[inline(always)]
// fn check_gas() {
//     match gas::withdraw_gas_all(get_builtin_costs()) {
//         Option::Some(_) => {},
//         Option::None(_) => {
//             let mut data = ArrayTrait::new();
//             data.append('Out of gas');
//             panic(data);
//         }
//     }
// }
// #[test]
// #[available_gas(9999999)]
// fn test_mul_bool() {
//     match gas::withdraw_gas() {
//         Option::Some(_) => {},
//         Option::None(_) => {
//             let mut data = ArrayTrait::new();
//             data.append('Out of gas');
//             panic(data);
//         },
//     }
//     assert(math::mul_bool(true, true) == false, 'true ^ true == false');
//     assert(math::mul_bool(false, false) == false, 'false ^ false == false');
//     assert(math::mul_bool(true, false) == true, 'true ^ false == true');
//     assert(math::mul_bool(false, true) == true, 'false ^ true == true');
// }


