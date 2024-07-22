// use array::ArrayTrait;
// use array::SpanTrait;

// use gas::withdraw_gas;
// use gas::withdraw_gas_all;

// use projectile::projectile_plot::main;

// // #[inline(always)]
// // fn check_gas() {
// //     match gas::withdraw_gas_all(get_builtin_costs()) {
// //         Option::Some(_) => {},
// //         Option::None(_) => {
// //             let mut data = ArrayTrait::new();
// //             data.append('Out of gas');
// //             panic(data);
// //         }
// //     }
// // }
// //
// // Just figuring out input/output
// #[test]
// // #[available_gas(9999999)]
// fn test_main() {
//     // match gas::withdraw_gas() {
//     //     Option::Some(_) => {},
//     //     Option::None(_) => {
//     //         let mut data = ArrayTrait::new();
//     //         data.append('Out of gas');
//     //         panic(data);
//     //     },
//     // }
//     let (arr0, arr1) = main(20_usize, 65, 100);
//     assert(*arr0.at(0_usize) == 20, 'arr0[0] == 20');
//     assert(*arr0.at(1_usize) == 650000000000, 'arr0[1]=650000000000');
//     assert(*arr1.at(0_usize) == 100, 'arr1[0] == 100');
//     assert(*arr1.at(1_usize) == 1000000000000, 'arr1[1]=1000000000000');
// }
// //
// //
// // Just figuring out input/output
// // #[test]
// // fn test_main() {
// //     let (arr0, arr1) = main(20_usize, 65, 100);
// //     assert(*arr0.at(0_usize) == 20, 'arr0[0] == 20');
// //     assert(*arr0.at(1_usize) == 650000000000, 'arr0[1]=650000000000');
// //     assert(*arr1.at(0_usize) == 100, 'arr1[0] == 100');
// //     assert(*arr1.at(1_usize) == 1000000000000, 'arr1[1]=1000000000000');
// // }
// //
// //
// // #[test]
// // fn test_main() {
// //     let arr = main(1);
// //     assert(*arr.at(0_usize) == 2, 'arr[0] == 2');
// // }
// //
// //
// // #[test]
// // fn test_main() {
// //     assert(main(1) == 2, 'invalid');
// // }


