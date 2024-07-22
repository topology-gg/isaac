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
struct FixedType {
    mag: u128,
    sign: bool
}

// Traits for fixed-point type
trait Fixed {
    // Constructors
    fn new(mag: u128, sign: bool) -> FixedType;
    fn from_felt(val: felt252) -> FixedType;
    //
    // Math
    fn fp_sqrt(self_fp: FixedType) -> FixedType;
    fn fp_to_radians(theta_deg_fp: FixedType) -> FixedType;
}

// Implement traits

impl FixedImpl of Fixed {
    // mag must already be scaled up by SCALE_FP_u128
    fn new(mag: u128, sign: bool) -> FixedType {
        return FixedType { mag: mag, sign: sign };
    }

    // mag must already be scaled up by SCALE_FP
    fn from_felt(val: felt252) -> FixedType {
        let mag = integer::u128_try_from_felt252(_felt_abs(val)).unwrap();
        return Fixed::new(mag, _felt_sign(val));
    }

    // Calculates the square root of a Fixed point value
    // sign must be positive (`false`)
    fn fp_sqrt(self_fp: FixedType) -> FixedType {
        assert(self_fp.sign == false, 'must be positive');
        let root = integer::u128_sqrt(self_fp.mag);
        let res_u128 = root * SCALE_FP_SQRT_u128; // compensate for sqrt
        Fixed::new(res_u128, false)
    }

    // Converts fixed-pointangle in degrees to radians
    fn fp_to_radians(theta_deg_fp: FixedType) -> FixedType {
        let pi_fp = Fixed::from_felt(PI); // PI is already scaled up
        let one_eighty_fp = Fixed::from_felt(180 * SCALE_FP);
        theta_deg_fp * pi_fp / one_eighty_fp
    }
}

// converts FixedType to felt252
impl FixedInto of Into<FixedType, felt252> {
    fn into(self: FixedType) -> felt252 {
        let mag_felt = self.mag.into();
        if (self.sign == true) {
            return mag_felt * -1;
        } else {
            return mag_felt;
        }
    }
}

impl FixedAdd of Add<FixedType> {
    fn add(a: FixedType, b: FixedType) -> FixedType {
        // to felt, add, then back to fixed pt
        Fixed::from_felt(a.into() + b.into())
    }
}

impl FixedSub of Sub<FixedType> {
    fn sub(a: FixedType, b: FixedType) -> FixedType {
        // to felt, subtract, then back to fixed pt
        let res = Fixed::from_felt(a.into() - b.into());
        if (res.mag == 0_u128) {
            Fixed::new(0_u128, false) // force sign=false if mag=0
        } else {
            res
        }
    }
}

impl FixedMul of Mul<FixedType> {
    fn mul(a: FixedType, b: FixedType) -> FixedType {
        if (a.mag == 0_u128 | b.mag == 0_u128) {
            Fixed::new(0_u128, false) // force sign=false if mag=0
        } else {
            let res_sign = a.sign ^ b.sign; // ^ is XOR operator
            // Mul for u128 uses `u128_checked_mul`
            let res_u128 = a.mag * b.mag / SCALE_FP_u128;
            Fixed::new(res_u128, res_sign)
        }
    }
}

impl FixedDiv of Div<FixedType> {
    fn div(a: FixedType, b: FixedType) -> FixedType {
        if (a.mag == 0_u128) {
            Fixed::new(0_u128, false) // force sign=false if mag=0
        } else {
            let res_sign = a.sign ^ b.sign; // ^ is XOR operator
            let a_scaled_mag_u128 = a.mag * SCALE_FP_u128;
            // DIV for u128 uses `u128_safe_divmod`
            let res_u128 = a_scaled_mag_u128 / b.mag;
            Fixed::new(res_u128, res_sign)
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
