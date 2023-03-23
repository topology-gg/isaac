use array::ArrayTrait;
use debug::PrintTrait;
use array::ArrayTCloneImpl;
use array::SpanTrait;
use clone::Clone;
// use option::OptionTrait;
// use projectile::constants;

// MESS BELOW IS TO FIGURE OUT HOW TO RETURN & PRINT ARRAYS
// SYNTAX CHANGED SINCE starklings VERSION SO SOME THINGS NO LONGER WORK
//
//
// Trying 3 ways to  print array by printing from another fn, 
//              AND  then use array again in main
// // 1) pass value (print in called fn), return new array, append, print
// fn main() {
//     let mut a = ArrayTrait::<felt252>::new();
//     a.append(1);
//     let mut b = pass_by_value(a); // value passed, 
//     // `a` moves to `passed_by_value`, `a` dropped here
//     b.append(2);
//     b.print();
// }
// fn pass_by_value(arr: Array<felt252>) -> Array<felt252> {
//     arr.span().snapshot.clone().print(); // causes error...
//     // Error: Failed setting up runner.
//     // Caused by:
//     //     #95: Expected variable data for statement not found.
//     arr
// }
//
// // 2) pass reference (print in called fn), append again, print
// fn main() {
//     let mut a = ArrayTrait::<felt252>::new();
//     a.append(1);
//     pass_by_ref(ref a); // reference is passed, `a` remains here
//     a.append(2);
//     a.print();
// }
// fn pass_by_ref(ref arr: Array<felt252>) {
//     arr.span().snapshot.clone().print(); // causes error...
//     // Error: Failed setting up runner.
//     // Caused by:
//     //     #97: Expected variable data for statement not found.
//     // maybe related to https://github.com/starkware-libs/cairo/pull/2449
//     arr.print(); // causes error for `arr` in function arg...
// // Variable was previously moved. Trait has no implementation in context: core::traits::Copy::<core::array::Array::<core::felt252>>
// }
//
// // 3) pass snapshot (print in called fn), append again, print
// fn main() {
//     let mut a = ArrayTrait::<felt252>::new();
//     a.append(1);
//     // makes snapshot, or immutable type `@Array` version of `a`
//     // pass_by_snapshot(@a); // snapshot is passed, `a` remains here
//     a.append(2);
//     a.print();
// }
// fn pass_by_snapshot(arr: @Array<felt252>) {
//     arr.clone().print(); // causes error...
//     // Error: Failed setting up runner.
//     // Caused by:
//     //     #74: Expected variable data for statement not found.

//     *arr.print(); // causes error...
//     // Type: <missing>
//     // Desnap operator can only be applied on snapshots

//     let arr1 = *arr; // causes error...
//     arr1.print();
//     // Cannot desnap a non copyable type. Trait has no implementation in context: core::traits::Copy::<core::array::Array::<core::felt252>>
// }
//
//
//
// Try getting array from other function like starklings below
// fn main() {
//     let mut x_s = ArrayTrait::new();
//     x_s.append(1);
//     x_s.append(2);
//     print_array_reference(ref x_s);
// // print_array_snapshot(@x_s); // causes error below
// // x_s.span().snapshot.clone().print();
// // error: #20->#21: Got 'Unknown ap change' error while moving [10].
// // error: could not compile `projectile` due to previous error
// // make: *** [Makefile:2: build] Error 1
// // x_s
// }
// currently getting error here for `x` Variable was previously moved. Trait has no implementation in context: core::traits::Copy::<core::array::Array::<core::felt252>>
// fn print_array_reference(ref x: Array<felt252>) {
//     x.print();
// // // causes error 
// // // Error: Failed setting up runner.
// // // Caused by:
// // //     #92: Expected variable data for statement not found.
// // //https://github.com/starkware-libs/cairo/blob/9c190561ce1e8323665857f1a77082925c817b4c/crates/cairo-lang-sierra-to-casm/src/invocations/mod.rs#L76
// }
// fn print_array_snapshot(x_s: @Array<felt252>) {
//     x_s.clone().print(); // must clone first to print snapshot type @T
// // let x_s_clone = x_s.clone();
// // x_s_clone.print(); // must clone first to print snapshot type @T
// // both versions above cause error 
// // Error: Failed setting up runner.
// // Caused by:
// //     #92: Expected variable data for statement not found.
// //https://github.com/starkware-libs/cairo/blob/9c190561ce1e8323665857f1a77082925c817b4c/crates/cairo-lang-sierra-to-casm/src/invocations/mod.rs#L76
// }
//
//
fn main() {
    let mut arr = ArrayTrait::<felt252>::new();
    arr.append(1);
    arr.append(2);
    arr.append(3);
    arr.span().snapshot.clone().print(); // causes error... 
    // Error: Failed setting up runner.
    // Caused by:
    //     #91: Expected variable data for statement not found.
    arr.append(4);
    // arr.span().snapshot.clone().print(); // used here causes error...
    // Error: Failed setting up runner.
    // Caused by:
    //     #25->#26: Got 'Unknown ap change' error while moving [7].
    //
    // If BOTH print() above are used, error...
    // Error: Failed setting up runner.
    // Caused by:
    //     [3] is dangling at #47.
    arr.print(); // this works
}
//
//
// Below has error , but this works 
// fn main() {
//     let mut x_s = ArrayTrait::new();
//     x_s.append(1);
//     x_s.append(2);
//     x_s.print();
// // x_s.span().snapshot.clone().print();
// }
//
//
// Try array functions from starklings move_semantics4.cairo
// fn main() {
//     let mut arr1 = fill_arr(); // no arg passed, `arr1` returned
//     arr1.span().snapshot.clone().print(); // causes error... 
//     // Error: Failed setting up runner.
//     // Caused by:
//     //     #91: Expected variable data for statement not found.
//     arr1.append(88);
//     arr1.span().snapshot.clone().print(); // used here causes error...
//     // Error: Failed setting up runner.
//     // Caused by:
//     //     #15->#16: Got 'Unknown ap change' error while moving [7].
//     //
//     // If BOTH print() above are used, error...
//     // Error: Failed setting up runner.
//     // Caused by:
//     //     [3] is dangling at #47.
//     arr1.print(); // this works
// }
// fn fill_arr() -> Array<felt252> {
//     let mut arr = ArrayTrait::<felt252>::new();
//     arr.append(22);
//     arr.append(44);
//     arr.append(66);
//     arr // `arr` moves to `fn main` as `arr1`, dropped here
// }
//
//
// fn main() {
//     let mut x_s = ArrayTrait::new();
//     x_s.append(1);
//     x_s.append(2);
//     // x_s.print();
//     // x_s.span().snapshot.clone().print();
//     // x_s.append(3);
// }
//
//
// fn main() -> (Array::<felt252>, Array::<felt252>) {
//     let mut x_s = ArrayTrait::<felt252>::new();
//     x_s.append(1);
//     x_s.append(2);
//     // x_s.span().snapshot.clone().print(); // causes error...
//     // Error: Failed setting up runner.
//     // Caused by:
//     //    #20->#21: Got 'Unknown ap change' error while moving [10].

//     let mut y_s: Array<felt252> = ArrayTrait::new();
//     y_s.append(3);
//     y_s.append(4);
//     (x_s, y_s)
// } // With no prints, this returns...
// Run completed successfully, returning [51, 53, 53, 55]
// BUT I DON'T UNDERSTAND values in array?????
//
//
// fn main() -> (Array::<u128>, Array::<u128>) {
//     let mut x_s = ArrayTrait::new();
//     x_s.append(1_u128);
//     x_s.append(2_u128);
//     // x_s.span().snapshot.clone().print(); 
//     // print doesnt work bc u128? try felt252?
//     let mut y_s = ArrayTrait::new();
//     y_s.append(3_u128);
//     y_s.append(4_u128);
//     (x_s, y_s)
// }
//
//
// fn main(NUM_PTS: usize, theta_0_deg: u128, v_0: u128) -> Array<u128> {
//     let theta_0_deg_fp = theta_0_deg * constants::SCALE_FP;
//     let v_0_fp = v_0 * constants::SCALE_FP;

//     let mut x_s = ArrayTrait::new();
//     // let mut y_s = ArrayTrait::new();
//     x_s.append(theta_0_deg_fp);
//     x_s.append(2_u128 * theta_0_deg_fp);
//     x_s
// }


