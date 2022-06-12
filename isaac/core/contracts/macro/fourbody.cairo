%lang starknet
# %builtins pedersen range_check

# from starkware.starknet.common.storage import Storage
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import signed_div_rem, sign, assert_nn, assert_not_zero, unsigned_div_rem, sqrt
from starkware.cairo.common.math_cmp import is_le

const RANGE_CHECK_BOUND = 2 ** 120 # 2 ** 64
const SCALE_FP = 10**20
const SCALE_FP_SQRT = 10**10

############################################################################
### Sqrt algorithm by @cecco_#0181 on Discord ##############################
### Src: https://gist.github.com/fracek/d06d0791b320cbab7539de3ec6fb97ba ###
############################################################################
# Compute square root of `x`.
func sqrt_fp {range_check_ptr}(x : felt) -> (y : felt):
    # 17 * 17 = 289
    # 17_fp * 17_fp = 289_fp
    # yet, sqrt(289_fp) = sqrt(289 * SCALE_FP) = sqrt(289) * sqrt(SCALE_FP) = 17 * sqrt(SCALE_FP) != 17_fp
    # solution: compensate by multiplying sqrt(SCALE_FP) at the end

    let (x_) = sqrt(x)
    let y = x * SCALE_FP_SQRT # compensate for the square root operation
    return (y)
end

# func sqrt{range_check_ptr}(x : felt) -> (y : felt):
#     alloc_locals

#     assert_nn(x)

#     if x == 0:
#         return (y=0)
#     else:
#         # start at x, maximum 200 iterations (gas on StarkNet is cheap)
#         let (y) = _sqrt_loop(x, x, 200)

#         return (y=y)
#     end
# end

# # Compute square root of `x` using Newton/babylonian method.
# func _sqrt_loop{range_check_ptr}(x : felt, xn : felt, iter : felt) -> (y : felt):
#     alloc_locals

#     if iter == 0:
#         return (y=xn)
#     end

#     # best guess is arithmetic mean of `xn` and `x/xn`.
#     let (local x_over_xn, _) = unsigned_div_rem(x, xn)
#     let (local xn_, _) = unsigned_div_rem(xn + x_over_xn, 2)

#     let (should_continue) = is_le(xn_, xn)

#     if should_continue != 0:
#         return _sqrt_loop(x, xn_, iter - 1)
#     else:
#         # return previous iteration since we want a lower bounding result.
#         return (y=xn)
#     end
# end

# Generated problem-specific struct for holding the coordinates for dynamics (all in fixed-point representation)
struct Dynamics:
    member q1  : felt
    member q1d : felt
    member q2  : felt
    member q2d : felt
    member q3  : felt
    member q3d : felt
    member q4  : felt
    member q4d : felt
    member q5  : felt
    member q5d : felt
    member q6  : felt
    member q6d : felt
    member q7  : felt
    member q7d : felt
    member q8  : felt
    member q8d : felt
end

# Generated function to compute the sum of two Dynamics structs
func dynamics_add {range_check_ptr} (
        state_a : Dynamics,
        state_b : Dynamics
    ) -> (
        state_z : Dynamics
    ):
    alloc_locals
    local q1_  = state_a.q1  + state_b.q1
    local q1d_ = state_a.q1d + state_b.q1d
    local q2_  = state_a.q2  + state_b.q2
    local q2d_ = state_a.q2d + state_b.q2d
    local q3_  = state_a.q3  + state_b.q3
    local q3d_ = state_a.q3d + state_b.q3d
    local q4_  = state_a.q4  + state_b.q4
    local q4d_ = state_a.q4d + state_b.q4d
    local q5_  = state_a.q5  + state_b.q5
    local q5d_ = state_a.q5d + state_b.q5d
    local q6_  = state_a.q6  + state_b.q6
    local q6d_ = state_a.q6d + state_b.q6d
    local q7_  = state_a.q7  + state_b.q7
    local q7d_ = state_a.q7d + state_b.q7d
    local q8_  = state_a.q8  + state_b.q8
    local q8d_ = state_a.q8d + state_b.q8d
    local state_z : Dynamics = Dynamics(q1=q1_, q1d=q1d_, q2=q2_, q2d=q2d_, q3=q3_, q3d=q3d_, q4=q4_, q4d=q4d_, q5=q5_, q5d=q5d_, q6=q6_, q6d=q6d_, q7=q7_, q7d=q7d_, q8=q8_, q8d=q8d_)
    return (state_z)
end

# Generated function to compute a Dynamics struct multiplied by a fixed-point value
func dynamics_mul_fp {range_check_ptr} (
        state_a : Dynamics,
        multiplier_fp  : felt
    ) -> (
        state_z : Dynamics
    ):
    alloc_locals
    local q1  = state_a.q1
    local q1d = state_a.q1d
    local q2  = state_a.q2
    local q2d = state_a.q2d
    local q3  = state_a.q3
    local q3d = state_a.q3d
    local q4  = state_a.q4
    local q4d = state_a.q4d
    local q5  = state_a.q5
    local q5d = state_a.q5d
    local q6  = state_a.q6
    local q6d = state_a.q6d
    local q7  = state_a.q7
    local q7d = state_a.q7d
    local q8  = state_a.q8
    local q8d = state_a.q8d
    let (local q1_)  = mul_fp (q1,  multiplier_fp)
    let (local q1d_) = mul_fp (q1d, multiplier_fp)
    let (local q2_)  = mul_fp (q2,  multiplier_fp)
    let (local q2d_) = mul_fp (q2d, multiplier_fp)
    let (local q3_)  = mul_fp (q3,  multiplier_fp)
    let (local q3d_) = mul_fp (q3d, multiplier_fp)
    let (local q4_)  = mul_fp (q4,  multiplier_fp)
    let (local q4d_) = mul_fp (q4d, multiplier_fp)
    let (local q5_)  = mul_fp (q5,  multiplier_fp)
    let (local q5d_) = mul_fp (q5d, multiplier_fp)
    let (local q6_)  = mul_fp (q6,  multiplier_fp)
    let (local q6d_) = mul_fp (q6d, multiplier_fp)
    let (local q7_)  = mul_fp (q7,  multiplier_fp)
    let (local q7d_) = mul_fp (q7d, multiplier_fp)
    let (local q8_)  = mul_fp (q8,  multiplier_fp)
    let (local q8d_) = mul_fp (q8d, multiplier_fp)
    local state_z : Dynamics = Dynamics(q1=q1_, q1d=q1d_, q2=q2_, q2d=q2d_, q3=q3_, q3d=q3d_, q4=q4_, q4d=q4d_, q5=q5_, q5d=q5d_, q6=q6_, q6d=q6d_, q7=q7_, q7d=q7d_, q8=q8_, q8d=q8d_)
    return (state_z)
end

# Generated function to compute a Dynamics struct multiplied by a unit-less value
func dynamics_mul_fp_ul {range_check_ptr} (
        state_a : Dynamics,
        multiplier_ul  : felt
    ) -> (
        state_z : Dynamics
    ):
    alloc_locals
    local q1  = state_a.q1
    local q1d = state_a.q1d
    local q2  = state_a.q2
    local q2d = state_a.q2d
    local q3  = state_a.q3
    local q3d = state_a.q3d
    local q4  = state_a.q4
    local q4d = state_a.q4d
    local q5  = state_a.q5
    local q5d = state_a.q5d
    local q6  = state_a.q6
    local q6d = state_a.q6d
    local q7  = state_a.q7
    local q7d = state_a.q7d
    local q8  = state_a.q8
    local q8d = state_a.q8d
    let (local q1_)  = mul_fp_ul (q1,  multiplier_ul)
    let (local q1d_) = mul_fp_ul (q1d, multiplier_ul)
    let (local q2_)  = mul_fp_ul (q2,  multiplier_ul)
    let (local q2d_) = mul_fp_ul (q2d, multiplier_ul)
    let (local q3_)  = mul_fp_ul (q3,  multiplier_ul)
    let (local q3d_) = mul_fp_ul (q3d, multiplier_ul)
    let (local q4_)  = mul_fp_ul (q4,  multiplier_ul)
    let (local q4d_) = mul_fp_ul (q4d, multiplier_ul)
    let (local q5_)  = mul_fp_ul (q5,  multiplier_ul)
    let (local q5d_) = mul_fp_ul (q5d, multiplier_ul)
    let (local q6_)  = mul_fp_ul (q6,  multiplier_ul)
    let (local q6d_) = mul_fp_ul (q6d, multiplier_ul)
    let (local q7_)  = mul_fp_ul (q7,  multiplier_ul)
    let (local q7d_) = mul_fp_ul (q7d, multiplier_ul)
    let (local q8_)  = mul_fp_ul (q8,  multiplier_ul)
    let (local q8d_) = mul_fp_ul (q8d, multiplier_ul)
    local state_z : Dynamics = Dynamics(q1=q1_, q1d=q1d_, q2=q2_, q2d=q2d_, q3=q3_, q3d=q3d_, q4=q4_, q4d=q4d_, q5=q5_, q5d=q5d_, q6=q6_, q6d=q6d_, q7=q7_, q7d=q7d_, q8=q8_, q8d=q8d_)
    return (state_z)
end

# Generated function to compute a Dynamics struct divided by a unit-less value
func dynamics_div_fp_ul {range_check_ptr} (
        state_a : Dynamics,
        divisor_ul  : felt
    ) -> (
        state_z : Dynamics
    ):
    alloc_locals
    local q1  = state_a.q1
    local q1d = state_a.q1d
    local q2  = state_a.q2
    local q2d = state_a.q2d
    local q3  = state_a.q3
    local q3d = state_a.q3d
    local q4  = state_a.q4
    local q4d = state_a.q4d
    local q5  = state_a.q5
    local q5d = state_a.q5d
    local q6  = state_a.q6
    local q6d = state_a.q6d
    local q7  = state_a.q7
    local q7d = state_a.q7d
    local q8  = state_a.q8
    local q8d = state_a.q8d
    let (local q1_)  = div_fp_ul (q1,  divisor_ul)
    let (local q1d_) = div_fp_ul (q1d, divisor_ul)
    let (local q2_)  = div_fp_ul (q2,  divisor_ul)
    let (local q2d_) = div_fp_ul (q2d, divisor_ul)
    let (local q3_)  = div_fp_ul (q3,  divisor_ul)
    let (local q3d_) = div_fp_ul (q3d, divisor_ul)
    let (local q4_)  = div_fp_ul (q4,  divisor_ul)
    let (local q4d_) = div_fp_ul (q4d, divisor_ul)
    let (local q5_)  = div_fp_ul (q5,  divisor_ul)
    let (local q5d_) = div_fp_ul (q5d, divisor_ul)
    let (local q6_)  = div_fp_ul (q6,  divisor_ul)
    let (local q6d_) = div_fp_ul (q6d, divisor_ul)
    let (local q7_)  = div_fp_ul (q7,  divisor_ul)
    let (local q7d_) = div_fp_ul (q7d, divisor_ul)
    let (local q8_)  = div_fp_ul (q8,  divisor_ul)
    let (local q8d_) = div_fp_ul (q8d, divisor_ul)
    local state_z : Dynamics = Dynamics(q1=q1_, q1d=q1d_, q2=q2_, q2d=q2d_, q3=q3_, q3d=q3d_, q4=q4_, q4d=q4d_, q5=q5_, q5d=q5d_, q6=q6_, q6d=q6d_, q7=q7_, q7d=q7d_, q8=q8_, q8d=q8d_)
    return (state_z)
end

### Utility functions for fixed-point arithmetic

func mul_fp {range_check_ptr} (
        a : felt,
        b : felt
    ) -> (
        c : felt
    ):
    # signed_div_rem by SCALE_FP after multiplication
    tempvar product = a * b
    let (c, _) = signed_div_rem(product, SCALE_FP, RANGE_CHECK_BOUND)
    return (c)
end

func div_fp {range_check_ptr} (
        a : felt,
        b : felt
    ) -> (
        c : felt
    ):
    # multiply by SCALE_FP before signed_div_rem
    tempvar a_scaled = a * SCALE_FP
    let (c, _) = signed_div_rem(a_scaled, b, RANGE_CHECK_BOUND)
    return (c)
end

func mul_fp_ul {range_check_ptr} (
        a : felt,
        b_ul : felt
    ) -> (
        c : felt
    ):
    let c = a * b_ul
    return (c)
end

func div_fp_ul {range_check_ptr} (
        a : felt,
        b_ul : felt
    ) -> (
        c : felt
    ):
    let (c, _) = signed_div_rem(a, b_ul, RANGE_CHECK_BOUND)
    return (c)
end

# Generated Runge-Kutta 4th-order method for Dynamics state
@external
func rk4 {range_check_ptr} (
        dt : felt,
        state : Dynamics
    ) -> (
        state_nxt : Dynamics
    ):
    alloc_locals
    # k1 stage
    let k1_state : Dynamics        = state
    let (k1_state_diff : Dynamics) = eval (k1_state)
    let (local k1 : Dynamics)      = dynamics_mul_fp (k1_state_diff, dt)

    # k2 stage
    let (k1_half : Dynamics)       = dynamics_div_fp_ul (k1, 2)
    let (k2_state : Dynamics)      = dynamics_add(state, k1_half)
    let (k2_state_diff : Dynamics) = eval (k2_state)
    let (local k2 : Dynamics)      = dynamics_mul_fp (k2_state_diff, dt)

    # k3 stage
    let (k2_half : Dynamics)       = dynamics_div_fp_ul (k2, 2)
    let (k3_state : Dynamics)      = dynamics_add(state, k2_half)
    let (k3_state_diff : Dynamics) = eval (k3_state)
    let (local k3 : Dynamics)      = dynamics_mul_fp (k3_state_diff, dt)

    # k4 stage
    let (k4_state : Dynamics)      = dynamics_add(state, k3)
    let (k4_state_diff : Dynamics) = eval (k4_state)
    let (local k4 : Dynamics)      = dynamics_mul_fp (k4_state_diff, dt)

    # sum k, mul dt, div 6, obtain state_nxt
    let (k2_2)              = dynamics_mul_fp_ul (k2, 2)
    let (local sum_k1_2k2)  = dynamics_add (k1, k2_2) # wish we could overload operators..
    let (k3_2)              = dynamics_mul_fp_ul (k3, 2)
    let (sum_2k3_k4)        = dynamics_add (k3_2, k4)
    let (k_sum)             = dynamics_add (sum_k1_2k2, sum_2k3_k4)
    let (state_delta)       = dynamics_div_fp_ul (k_sum, 6)
    let (state_nxt)         = dynamics_add (state, state_delta)

    return (state_nxt)
end

# Problem-specific evaluation function for first-order derivative of state
@external
func eval {range_check_ptr} (
        state : Dynamics
    ) -> (
        state_diff : Dynamics
    ):
    alloc_locals

    # Unpack state struct
    local x1  = state.q1
    local y1  = state.q2
    local x2  = state.q3
    local y2  = state.q4
    local x3  = state.q5
    local y3  = state.q6
    local x4  = state.q7
    local y4  = state.q8

    # Scene setup - unit mass; set gravitational constant to 1
    const G  = 4 * SCALE_FP
    const M1 = 4 * SCALE_FP
    const M2 = 4 * SCALE_FP
    const M3 = 4 * SCALE_FP

    # Calculate distance^3 between Sun1 and Sun2
    tempvar x2mx1 = x2-x1
    let (local x2mx1_sq) = mul_fp (x2mx1, x2mx1)
    tempvar y2my1 = y2-y1
    let (y2my1_sq) = mul_fp (y2my1, y2my1)
    local R12_2 = x2mx1_sq + y2my1_sq
    let (R12_) = sqrt(R12_2)
    tempvar R12 = R12_ * SCALE_FP_SQRT # compensate for the square root operation
    let (local R12_3) = mul_fp (R12_2, R12)

    # Calculate distance^3 between Sun1 and Sun3
    tempvar x3mx1 = x3-x1
    let (local x3mx1_sq) = mul_fp (x3mx1, x3mx1)
    tempvar y3my1 = y3-y1
    let (y3my1_sq) = mul_fp (y3my1, y3my1)
    local R13_2 = x3mx1_sq + y3my1_sq
    let (R13_) = sqrt(R13_2)
    tempvar R13 = R13_ * SCALE_FP_SQRT # compensate for the square root operation
    let (local R13_3) = mul_fp (R13_2, R13)

    # Calculate distance^3 between Sun2 and Sun3
    tempvar x3mx2 = x3-x2
    let (local x3mx2_sq) = mul_fp (x3mx2, x3mx2)
    tempvar y3my2 = y3-y2
    let (y3my2_sq) = mul_fp (y3my2, y3my2)
    local R23_2 = x3mx2_sq + y3my2_sq
    let (R23_) = sqrt(R23_2)
    tempvar R23 = R23_ * SCALE_FP_SQRT # compensate for the square root operation
    let (local R23_3) = mul_fp (R23_2, R23)

    # Calculate distance^3 between Sun1 and Mass4 (small-mass planet)
    tempvar x4mx1 = x4-x1
    let (local x4mx1_sq) = mul_fp (x4mx1, x4mx1)
    tempvar y4my1 = y4-y1
    let (y4my1_sq) = mul_fp (y4my1, y4my1)
    local R14_2 = x4mx1_sq + y4my1_sq
    assert_not_zero (R14_2)
    let (R14_) = sqrt(R14_2)
    tempvar R14 = R14_ * SCALE_FP_SQRT # compensate for the square root operation
    let (local R14_3) = mul_fp (R14_2, R14)

    # Calculate distance^3 between Sun2 and Mass4 (small-mass planet)
    tempvar x4mx2 = x4-x2
    let (local x4mx2_sq) = mul_fp (x4mx2, x4mx2)
    tempvar y4my2 = y4-y2
    let (y4my2_sq) = mul_fp (y4my2, y4my2)
    local R24_2 = x4mx2_sq + y4my2_sq
    assert_not_zero (R24_2)
    let (R24_) = sqrt(R24_2)
    tempvar R24 = R24_ * SCALE_FP_SQRT # compensate for the square root operation
    let (local R24_3) = mul_fp (R24_2, R24)

    # Calculate distance^3 between Sun3 and Mass4 (small-mass planet)
    tempvar x4mx3 = x4-x3
    let (local x4mx3_sq) = mul_fp (x4mx3, x4mx3)
    tempvar y4my3 = y4-y3
    let (y4my3_sq) = mul_fp (y4my3, y4my3)
    local R34_2 = x4mx3_sq + y4my3_sq
    assert_not_zero (R34_2)
    let (R34_) = sqrt(R34_2)
    tempvar R34 = R34_ * SCALE_FP_SQRT # compensate for the square root operation
    let (local R34_3) = mul_fp (R34_2, R34)

    let (local G_R12_3) = div_fp (G, R12_3)
    let (local G_R13_3) = div_fp (G, R13_3)
    let (local G_R23_3) = div_fp (G, R23_3)

    let (local G_R14_3) = div_fp (G, R14_3)
    let (local G_R24_3) = div_fp (G, R24_3)
    let (local G_R34_3) = div_fp (G, R34_3)

    let (local G_R12_3_M2) = mul_fp (G_R12_3, M2)
    let (local G_R13_3_M3) = mul_fp (G_R13_3, M3)
    let (local G_R12_3_M1) = mul_fp (G_R12_3, M1)
    let (local G_R23_3_M3) = mul_fp (G_R23_3, M3)
    let (local G_R13_3_M1) = mul_fp (G_R13_3, M1)
    let (local G_R23_3_M2) = mul_fp (G_R23_3, M2)

    let (local G_R14_3_M1) = mul_fp (G_R14_3, M1)
    let (local G_R24_3_M2) = mul_fp (G_R24_3, M2)
    let (local G_R34_3_M3) = mul_fp (G_R34_3, M3)

    # assemble ax1
    tempvar x2mx1 = x2-x1 # recreating this tempvar here to reduce local var count
    let (local ax1_12) = mul_fp (G_R12_3_M2, x2mx1)
    tempvar x3mx1 = x3-x1
    let (local ax1_13) = mul_fp (G_R13_3_M3, x3mx1)
    local ax1 = ax1_12 + ax1_13

    # assemble ay1
    tempvar y2my1 = y2-y1
    let (local ay1_12) = mul_fp (G_R12_3_M2, y2my1)
    tempvar y3my1 = y3-y1
    let (local ay1_13) = mul_fp (G_R13_3_M3, y3my1)
    local ay1 = ay1_12 + ay1_13

    # assemble ax2
    tempvar x1mx2 = x1-x2
    let (local ax2_12) = mul_fp (G_R12_3_M1, x1mx2)
    tempvar x3mx2 = x3-x2
    let (local ax2_23) = mul_fp (G_R23_3_M3, x3mx2)
    local ax2 = ax2_12 + ax2_23

    # assemble ay2
    tempvar y1my2 = y1-y2
    let (local ay2_12) = mul_fp (G_R12_3_M1, y1my2)
    tempvar y3my2 = y3-y2
    let (local ay2_23) = mul_fp (G_R23_3_M3, y3my2)
    local ay2 = ay2_12 + ay2_23

    # assemble ax3
    tempvar x1mx3 = x1-x3
    let (local ax3_13) = mul_fp (G_R13_3_M1, x1mx3)
    tempvar x2mx3 = x2-x3
    let (local ax3_23) = mul_fp (G_R23_3_M2, x2mx3)
    local ax3 = ax3_13 + ax3_23

    # assemble ay3
    tempvar y1my3 = y1-y3
    let (local ay3_13) = mul_fp (G_R13_3_M1, y1my3)
    tempvar y2my3 = y2-y3
    let (local ay3_23) = mul_fp (G_R23_3_M2, y2my3)
    local ay3 = ay3_13 + ay3_23

    # assemble ax4
    tempvar x1mx4 = x1-x4
    let (local ax4_14) = mul_fp (G_R14_3_M1, x1mx4)
    tempvar x2mx4 = x2-x4
    let (local ax4_24) = mul_fp (G_R24_3_M2, x2mx4)
    tempvar x3mx4 = x3-x4
    let (local ax4_34) = mul_fp (G_R34_3_M3, x3mx4)
    local ax4 = ax4_14 + ax4_24 + ax4_34

    # assemble ay4
    tempvar y1my4 = y1-y4
    let (local ay4_14) = mul_fp (G_R14_3_M1, y1my4)
    tempvar y2my4 = y2-y4
    let (local ay4_24) = mul_fp (G_R24_3_M2, y2my4)
    tempvar y3my4 = y3-y4
    let (local ay4_34) = mul_fp (G_R34_3_M3, y3my4)
    local ay4 = ay4_14 + ay4_24 + ay4_34

    # packing up
    local state_diff : Dynamics = Dynamics(
        q1  = state.q1d, # q1 diff
        q1d = ax1,
        q2  = state.q2d, # q2 diff
        q2d = ay1,
        q3  = state.q3d, # q3 diff
        q3d = ax2,
        q4  = state.q4d, # q4 diff
        q4d = ay2,
        q5  = state.q5d, # q5 diff
        q5d = ax3,
        q6  = state.q6d, # q6 diff
        q6d = ay3,
        q7  = state.q7d,
        q7d = ax4,
        q8  = state.q8d,
        q8d = ay4
    )
    return (state_diff)
end

@view
func query_next_given_coordinates {
        # storage_ptr : Storage*,
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    }(
        dt : felt,
        x1 : felt, x1d : felt, y1 : felt, y1d : felt,
        x2 : felt, x2d : felt, y2 : felt, y2d : felt,
        x3 : felt, x3d : felt, y3 : felt, y3d : felt,
        x4 : felt, x4d : felt, y4 : felt, y4d : felt
    ) -> (
        x1_nxt : felt, x1d_nxt : felt, y1_nxt : felt, y1d_nxt : felt,
        x2_nxt : felt, x2d_nxt : felt, y2_nxt : felt, y2d_nxt : felt,
        x3_nxt : felt, x3d_nxt : felt, y3_nxt : felt, y3d_nxt : felt,
        x4_nxt : felt, x4d_nxt : felt, y4_nxt : felt, y4d_nxt : felt
    ):

    # Algorithm
    #   use t, state to calculate next state at t+dt
    #   return next state

    let state : Dynamics = Dynamics(
        q1=x1, q1d=x1d, q2=y1, q2d=y1d,
        q3=x2, q3d=x2d, q4=y2, q4d=y2d,
        q5=x3, q5d=x3d, q6=y3, q6d=y3d,
        q7=x4, q7d=x4d, q8=y4, q8d=y4d
    ) # packing

    let (state_nxt) = rk4 (dt=dt, state=state)

    let x1_nxt  = state_nxt.q1 # unpacking (until testing framework accepts struct return)
    let x1d_nxt = state_nxt.q1d
    let y1_nxt  = state_nxt.q2
    let y1d_nxt = state_nxt.q2d
    let x2_nxt  = state_nxt.q3
    let x2d_nxt = state_nxt.q3d
    let y2_nxt  = state_nxt.q4
    let y2d_nxt = state_nxt.q4d
    let x3_nxt  = state_nxt.q5
    let x3d_nxt = state_nxt.q5d
    let y3_nxt  = state_nxt.q6
    let y3d_nxt = state_nxt.q6d
    let x4_nxt  = state_nxt.q7
    let x4d_nxt = state_nxt.q7d
    let y4_nxt  = state_nxt.q8
    let y4d_nxt = state_nxt.q8d

    return (x1_nxt, x1d_nxt, y1_nxt, y1d_nxt,
            x2_nxt, x2d_nxt, y2_nxt, y2d_nxt,
            x3_nxt, x3d_nxt, y3_nxt, y3d_nxt,
            x4_nxt, x4d_nxt, y4_nxt, y4d_nxt)
end

