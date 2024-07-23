%lang starknet

//
// Fixed point math constants
//
const SCALE_FP = 10**20;
const SCALE_FP_SQRT = 10**10;
const RANGE_CHECK_BOUND = 2 ** 120;

//
// Constants for felts, not used yet
//
// const PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481;
// const HALF_PRIME = 1809251394333065606848661391547535052811553607665798349986546028067936010240;

//
// Math constants
//
const PI_fp = 3141592654 * SCALE_FP / 1000000000;
const HALF_PI_fp = 1570796327 * SCALE_FP / 1000000000;

//
// Physical parameters
//
// Gravitational acceleration magnitude
const g_fp = 98 * SCALE_FP / 10;
// Initial position
const x_0_fp = 0 * SCALE_FP;
const y_0_fp = 0 * SCALE_FP;

//
// Plot parameters
//
// Min and max values for axes.
const x_max_fp = 1000 * SCALE_FP;
const x_min_fp = -x_max_fp;
const y_max_fp = 500 * SCALE_FP;
const y_min_fp = -y_max_fp;