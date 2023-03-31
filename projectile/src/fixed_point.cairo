use option::OptionTrait;
use traits::Into;

use projectile::constants::SCALE_FP;
use projectile::constants::SCALE_FP_u128;
use projectile::constants::SCALE_FP_SQRT_u128;
use projectile::constants::HALF_PRIME;
use projectile::constants::PI;

// Struct for fixed-point type
// `mag` is a fixed-point value, scaled up by `SCALE_FP_u128`
// `sign` is `false` if +, `true` if -
#[derive(Copy, Drop)]
struct FixedPtType {
    mag: u128,
    sign: bool
}

// Traits for fixed-point type
trait FixedPt {
    // Constructors
    fn new(mag: u128, sign: bool) -> FixedPtType;
    fn from_felt(val: felt252) -> FixedPtType;
    //
    // Math
    fn fp_sqrt(self_fp: FixedPtType) -> FixedPtType;
    fn fp_to_radians(theta_deg_fp: FixedPtType) -> FixedPtType;
}

// Implement traits

impl FixedPtImpl of FixedPt {
    // mag must already be scaled up by SCALE_FP_u128
    fn new(mag: u128, sign: bool) -> FixedPtType {
        return FixedPtType { mag: mag, sign: sign };
    }

    // mag must already be scaled up by SCALE_FP
    fn from_felt(val: felt252) -> FixedPtType {
        let mag = integer::u128_try_from_felt252(_felt_abs(val)).unwrap();
        return FixedPt::new(mag, _felt_sign(val));
    }

    // Calculates the square root of a FixedPt point value
    // sign must be positive (`false`)
    fn fp_sqrt(self_fp: FixedPtType) -> FixedPtType {
        assert(self_fp.sign == false, 'must be positive');
        let root = integer::u128_sqrt(self_fp.mag);
        let res_u128 = root * SCALE_FP_SQRT_u128; // compensate for sqrt
        FixedPt::new(res_u128, false)
    }

    // Converts fixed-pointangle in degrees to radians
    fn fp_to_radians(theta_deg_fp: FixedPtType) -> FixedPtType {
        let pi_fp = FixedPt::from_felt(PI); // PI is already scaled up
        let one_eighty_fp = FixedPt::from_felt(180 * SCALE_FP);
        theta_deg_fp * pi_fp / one_eighty_fp
    }
}

// converts FixedPtType to felt252
impl FixedPtInto of Into::<FixedPtType, felt252> {
    fn into(self: FixedPtType) -> felt252 {
        let mag_felt = self.mag.into();
        if (self.sign == true) {
            return mag_felt * -1;
        } else {
            return mag_felt;
        }
    }
}

impl FixedPtAdd of Add::<FixedPtType> {
    fn add(a: FixedPtType, b: FixedPtType) -> FixedPtType {
        // to felt, add, then back to fixed pt
        FixedPt::from_felt(a.into() + b.into())
    }
}

impl FixedPtSub of Sub::<FixedPtType> {
    fn sub(a: FixedPtType, b: FixedPtType) -> FixedPtType {
        // to felt, subtract, then back to fixed pt
        let res = FixedPt::from_felt(a.into() - b.into());
        if (res.mag == 0_u128) {
            FixedPt::new(0_u128, false) // force sign=false if mag=0
        } else {
            res
        }
    }
}

impl FixedPtMul of Mul::<FixedPtType> {
    fn mul(a: FixedPtType, b: FixedPtType) -> FixedPtType {
        if (a.mag == 0_u128 | b.mag == 0_u128) {
            FixedPt::new(0_u128, false) // force sign=false if mag=0
        } else {
            let res_sign = a.sign ^ b.sign; // ^ is XOR operator
            // Mul for u128 uses `u128_checked_mul`
            let res_u128 = a.mag * b.mag / SCALE_FP_u128;
            FixedPt::new(res_u128, res_sign)
        }
    }
}

impl FixedPtDiv of Div::<FixedPtType> {
    fn div(a: FixedPtType, b: FixedPtType) -> FixedPtType {
        if (a.mag == 0_u128) {
            FixedPt::new(0_u128, false) // force sign=false if mag=0
        } else {
            let res_sign = a.sign ^ b.sign; // ^ is XOR operator
            let a_scaled_mag_u128 = a.mag * SCALE_FP_u128;
            // DIV for u128 uses `u128_safe_divmod`
            let res_u128 = a_scaled_mag_u128 / b.mag;
            FixedPt::new(res_u128, res_sign)
        }
    }
}

// Internal functions

// Returns the sign of a signed `felt252` as with signed magnitude representation
// true = negative
// false = positive
fn _felt_sign(a: felt252) -> bool {
    integer::u256_from_felt252(a) > integer::u256_from_felt252(HALF_PRIME)
}

// Returns the absolute value of a signed `felt252`
fn _felt_abs(a: felt252) -> felt252 {
    let a_sign = _felt_sign(a);

    if (a_sign == true) {
        return a * -1;
    } else {
        return a;
    }
}
