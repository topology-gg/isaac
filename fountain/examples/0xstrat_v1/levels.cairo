%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (unsigned_div_rem, assert_le, abs_value)
from starkware.cairo.common.bitwise import (bitwise_or, bitwise_and, bitwise_xor)
from contracts.lib.structs import (Vec2, LevelState, Level)
from contracts.lib.constants import (FP)

#########################

## TODO: refactor this to allow cleaner level management
## need to invoke this, because stored seed will be modified
@external
func pull_random_level {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*
    } () -> (
        level : Level
    ):
    alloc_locals

    let (id_) = _get_pseudorandom()
    let (_, id) = unsigned_div_rem(id_, 2) ## <== mod <number of levels in inventory>

    local level : Level
    if id == 0:
        assert level = Level(
            level_state = LevelState(
                score0_ball = Vec2(300*FP, 250*FP),
                score1_ball = Vec2(200*FP, 250*FP),
                forbid_ball = Vec2(200*FP, 350*FP)
            ),
            level_id = 0
        )
    else:
        assert level = Level(
            level_state = LevelState(
                score0_ball = Vec2(80*FP , 130*FP),
                score1_ball = Vec2(140*FP, 340*FP),
                forbid_ball = Vec2(230*FP, 150*FP)
            ),
            level_id = 1
        )
    end

    return (level)
end

## TODO: allow different level to have different position & velocity constraints
@view
func assert_legal_position_velocity {
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr
    } (position : Vec2, velocity : Vec2) -> ():

    ## 50*FP <= x <= 350*FP
    ## 40*FP <= y <= 80*FP
    ## vx^2 + vy^2 <= 2* (200*FP)^2
    tempvar x_shifted = position.x - 50*FP
    assert_le (x_shifted, 300*FP)

    tempvar y_shifted = position.y - 40*FP
    assert_le (y_shifted, 40*FP)

    tempvar v_sq = velocity.x * velocity.x + velocity.y * velocity.y
    assert_le (v_sq, 2*200*FP*200*FP)

    return ()
end

#########################

@storage_var
func entropy_seed() -> (value : felt):
end

@constructor
func constructor{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (seed : felt):
    entropy_seed.write(seed)
    return ()
end

## PRBS-7; ref: https://en.wikipedia.org/wiki/Pseudorandom_binary_sequence
func _get_pseudorandom{
        syscall_ptr : felt*,
        pedersen_ptr : HashBuiltin*,
        range_check_ptr,
        bitwise_ptr : BitwiseBuiltin*
    }() -> (new_rand : felt):
    alloc_locals

    let (local a) = entropy_seed.read()

    let (local a_rightshift_6, _) = unsigned_div_rem(a, 64)
    let (local a_rightshift_5, _) = unsigned_div_rem(a, 32)
    local a_leftshirt_1 = a * 2

    ## new_rand = ((a >> 6) ^ (a >> 5))
    ## random bit = new_rand & 1
    let (new_rand) = bitwise_xor(a_rightshift_6, a_rightshift_5)
    let (local newbit) = bitwise_and(new_rand, 1)

    ## next a = ((a << 1) | newbit) & 0x7f
    let (a_next_) = bitwise_or(a_leftshirt_1, newbit)
    let (a_next) = bitwise_and(a_next_, 127)
    entropy_seed.write(a_next)

    return (new_rand)
end