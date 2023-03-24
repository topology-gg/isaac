use array::ArrayTrait;
use debug::PrintTrait;
use array::ArrayTCloneImpl;
use array::SpanTrait;
use clone::Clone;
use traits::Into;
use traits::TryInto;
// use option::OptionTrait;
use projectile::constants;

//
// Just figuring out input/output
fn main(
    NUM_PTS: usize, theta_0_deg: felt252, v_0: felt252
) -> (Array::<felt252>, Array::<felt252>) {
    let num_pts_felt = NUM_PTS.into();
    let scale_fp_felt = constants::SCALE_FP.into();
    let theta_0_deg_fp = theta_0_deg * scale_fp_felt;
    let v_0_fp = v_0 * scale_fp_felt;

    let mut x_s = ArrayTrait::<felt252>::new();
    x_s.append(num_pts_felt);
    x_s.append(theta_0_deg_fp);
    let mut y_s: Array<felt252> = ArrayTrait::new();
    y_s.append(v_0);
    y_s.append(v_0_fp);

    (x_s, y_s)
}
//
//
// fn main(a: felt252) -> (Array::<felt252>, Array::<felt252>) {
//     let mut x_s = ArrayTrait::<felt252>::new();
//     x_s.append(a);
//     x_s.append(2 * a);
//     let mut y_s: Array<felt252> = ArrayTrait::new();
//     y_s.append(3 * a);
//     y_s.append(4 * a);
//     (x_s, y_s)
// }
//
//
// fn main(a: felt252) -> Array<felt252> {
//     let mut x_s = ArrayTrait::<felt252>::new();
//     x_s.append(2 * a);
//     x_s
// }
//
//
// fn main(a: felt252) -> felt252 {
//     2 * a
// }


