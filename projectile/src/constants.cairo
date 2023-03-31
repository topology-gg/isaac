// Only literal constants are currently supported

//
// Fixed point math constants
//
// To be sure multiplication of 2 values will not overflow, max allowed u128
//   value is ~ 2^64 - 1 = 18446744073709551615 ~= 1.84 x 10^19 (see below)
//   which would be ~ 1.84 x 10^9 x SCALE_FP, if SCALE_FP = 10^10
//   Projectile values should be well below this max.
const SCALE_FP: felt252 = 10000000000; // 10^10
const SCALE_FP_u128: u128 = 10000000000_u128;
const SCALE_FP_SQRT: felt252 = 100000; // 10^5
const SCALE_FP_SQRT_u128: u128 = 100000_u128;
// const RNG_CHK_BND: felt252 = 1329227995784915872903807060280344576; // 2^120
// const RNG_CHK_BND_u128: u128 = 1329227995784915872903807060280344576_u128;

// u128 math constants
//
// value used for wide multiplication, but not needed if values remain <= MAX (see below)
// const WIDE_SHIFT_u128: u128 = 18446744073709551616_u128; // 2^64
//
// value not used for now
// const MAX: felt252 = 18446744073709551615;
// const MAX_u128: u128 = 18446744073709551615_u128; // 2^64 - 1

//
// Constants for felts
//
// too large for felt252 (max is PRIME-1)
// const PRIME: felt252 = 3618502788666131213697322783095070105623107215331596699973092056135872020481;
const HALF_PRIME: felt252 =
    1809251394333065606848661391547535052811553607665798349986546028067936010240;

//
// Math constants
//
const PI: felt252 = 31415926536;
const PI_u128: u128 = 31415926536_u128;
const HALF_PI: felt252 = 15707963268;
const HALF_PI_u128: u128 = 15707963268_u128;
// const TWO_PI: felt252 = 62831853072;
// const TWO_PI_u128: u128 = 62831853072_u128;


