use array::ArrayTrait;
use array::SpanTrait;

use projectile::projectile_plot::main;
//
// Just figuring out input/output
#[test]
fn test_main() {
    let (arr0, arr1) = main(20_usize, 65, 100);
    assert(*arr0.at(0_usize) == 20, 'arr0[0] == 20');
    assert(*arr0.at(1_usize) == 6500000000000000000000, 'arr0[1]=6500000000000000000000');
    assert(*arr1.at(0_usize) == 100, 'arr1[0] == 100');
    assert(*arr1.at(1_usize) == 10000000000000000000000, 'arr1[1]=10000000000000000000000');
}
//
//
// #[test]
// fn test_main() {
//     let arr = main(1);
//     assert(*arr.at(0_usize) == 2, 'arr[0] == 2');
// }
//
//
// #[test]
// fn test_main() {
//     assert(main(1) == 2, 'invalid');
// }


