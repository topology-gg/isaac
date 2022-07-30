%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

const PUZZLE_COUNT = 50
const PUZZLE_DIM = 8
const CR = 1
const ST = 2

struct Cir:
    member cell_index : felt
    member type : felt
end

@view
func get_puzzle {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        puzzle_id : felt
    ) -> (
        arr_circles_len : felt,
        arr_circles : Cir*
    ):

    let (arr_circles : Cir*) = alloc ()

    if puzzle_id == 0:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(8,ST), Cir(12,ST), Cir(28,ST), Cir(44,ST), Cir(47,ST), Cir(49,ST), Cir(61,ST),
            Cir(11,CR), Cir(20,CR), Cir(22,CR), Cir(29,CR), Cir(31,CR), Cir(33,CR), Cir(35,CR), Cir(40,CR)
        ), Cir*)
        return (16, arr_circles)
    end

    if puzzle_id == 1:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(17,ST), Cir(25,ST), Cir(27,ST), Cir(31,ST), Cir(35,ST), Cir(41,ST), Cir(43,ST), Cir(45,ST), Cir(60,ST),
            Cir(4,CR), Cir(7,CR), Cir(20,CR), Cir(33,CR), Cir(42,CR), Cir(58,CR), Cir(63,CR)
        ), Cir*)
        return (17, arr_circles)
    end

    if puzzle_id == 2:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(3,ST), Cir(17,ST), Cir(21,ST), Cir(31,ST), Cir(33,ST), Cir(57,ST),
            Cir(7,CR), Cir(45,CR), Cir(47,CR), Cir(52,CR), Cir(59,CR)
        ), Cir*)
        return (12, arr_circles)
    end

    if puzzle_id == 3:
        tempvar arr_circles : Cir* = cast(new(
            Cir(5,ST), Cir(9,ST), Cir(25,ST), Cir(46,ST), Cir(47,ST),
            Cir(3,CR), Cir(7,CR), Cir(29,CR), Cir(42,CR), Cir(44,CR), Cir(58,CR), Cir(63,CR)
        ), Cir*)
        return (12, arr_circles)
    end

    if puzzle_id == 4:
        tempvar arr_circles : Cir* = cast(new(
            Cir(8,ST), Cir(12,ST), Cir(19,ST), Cir(28,ST), Cir(41,ST), Cir(45,ST), Cir(59,ST),
            Cir(15,CR), Cir(24,CR), Cir(39,CR), Cir(63,CR)
        ), Cir*)
        return (11, arr_circles)
    end

    if puzzle_id == 5:
        tempvar arr_circles : Cir* = cast(new(
            Cir(6,ST), Cir(9,ST), Cir(20,ST), Cir(31,ST), Cir(38,ST), Cir(54,ST), Cir(62,ST),
            Cir(3,CR), Cir(16,CR), Cir(32,CR), Cir(34,CR), Cir(45,CR), Cir(56,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 6:
        tempvar arr_circles : Cir* = cast(new(
            Cir(4,ST), Cir(9,ST), Cir(17,ST), Cir(28,ST), Cir(39,ST), Cir(52,ST), Cir(59,ST),
            Cir(12,CR), Cir(21,CR), Cir(23,CR), Cir(32,CR), Cir(40,CR), Cir(46,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 7:
        tempvar arr_circles : Cir* = cast(new(
            Cir(2,ST), Cir(6,ST), Cir(14,ST), Cir(30,ST), Cir(35,ST), Cir(36,ST), Cir(49,ST),
            Cir(24,CR), Cir(32,CR), Cir(39,CR), Cir(58,CR), Cir(61,CR), Cir(63,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 8:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(17,ST), Cir(25,ST), Cir(26,ST), Cir(39,ST), Cir(59,ST),
            Cir(3,CR), Cir(5,CR), Cir(7,CR), Cir(21,CR), Cir(32,CR), Cir(38,CR), Cir(41,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 9:
        tempvar arr_circles : Cir* = cast(new(
            Cir(2,ST), Cir(10,ST), Cir(22,ST), Cir(38,ST), Cir(46,ST), Cir(53,ST), Cir(59,ST),
            Cir(12,CR), Cir(19,CR), Cir(32,CR), Cir(41,CR)
        ), Cir*)
        return (11, arr_circles)
    end

    if puzzle_id == 10:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(6,ST), Cir(19,ST), Cir(21,ST), Cir(24,ST), Cir(37,ST), Cir(39,ST), Cir(49,ST), Cir(50,ST), Cir(61,ST),
            Cir(18,CR), Cir(27,CR), Cir(29,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 11:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(20,ST), Cir(27,ST), Cir(35,ST), Cir(48,ST), Cir(51,ST), Cir(55,ST),
            Cir(0,CR), Cir(16,CR), Cir(22,CR), Cir(31,CR), Cir(39,CR)
        ), Cir*)
        return (12, arr_circles)
    end

    if puzzle_id == 12:
        tempvar arr_circles : Cir* = cast(new(
            Cir(21,ST), Cir(22,ST), Cir(29,ST), Cir(35,ST), Cir(41,ST), Cir(44,ST), Cir(49,ST), Cir(59,ST),
            Cir(4,CR), Cir(7,CR), Cir(26,CR), Cir(37,CR), Cir(63,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 13:
        tempvar arr_circles : Cir* = cast(new(
            Cir(9,ST), Cir(17,ST), Cir(20,ST), Cir(36,ST), Cir(40,ST), Cir(59,ST),
            Cir(22,CR), Cir(26,CR), Cir(39,CR), Cir(45,CR), Cir(56,CR), Cir(61,CR)
        ), Cir*)
        return (12, arr_circles)
    end

    if puzzle_id == 14:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(41,ST), Cir(43,ST), Cir(57,ST),
            Cir(0,CR), Cir(7,CR), Cir(18,CR), Cir(30,CR), Cir(34,CR), Cir(39,CR), Cir(47,CR), Cir(59,CR)
        ), Cir*)
        return (12, arr_circles)
    end

    if puzzle_id == 15:
        tempvar arr_circles : Cir* = cast(new(
            Cir(4,ST), Cir(9,ST), Cir(15,ST), Cir(24,ST), Cir(29,ST), Cir(31,ST), Cir(43,ST), Cir(51,ST), Cir(60,ST),
            Cir(12,CR), Cir(41,CR), Cir(45,CR), Cir(47,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 16:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(24,ST), Cir(25,ST), Cir(26,ST), Cir(33,ST), Cir(48,ST), Cir(55,ST), Cir(60,ST),
            Cir(12,CR), Cir(13,CR), Cir(29,CR), Cir(31,CR), Cir(36,CR), Cir(38,CR), Cir(41,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 17:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(5,ST), Cir(33,ST), Cir(35,ST), Cir(49,ST), Cir(50,ST), Cir(59,ST),
            Cir(8,CR), Cir(12,CR), Cir(17,CR), Cir(28,CR), Cir(39,CR), Cir(47,CR), Cir(63,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 18:
        tempvar arr_circles : Cir* = cast(new(
            Cir(6,ST), Cir(8,ST), Cir(18,ST), Cir(22,ST), Cir(26,ST), Cir(28,ST), Cir(44,ST), Cir(49,ST),
            Cir(4,CR), Cir(32,CR), Cir(35,CR), Cir(36,CR), Cir(47,CR), Cir(51,CR), Cir(63,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 19:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(13,ST), Cir(15,ST), Cir(18,ST), Cir(20,ST), Cir(23,ST), Cir(28,ST), Cir(46,ST), Cir(49,ST), Cir(61,ST),
            Cir(0,CR), Cir(34,CR), Cir(42,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 20:
        tempvar arr_circles : Cir* = cast(new(
            Cir(8,ST), Cir(49,ST), Cir(51,ST), Cir(54,ST),
            Cir(4,CR), Cir(5,CR), Cir(17,CR), Cir(30,CR), Cir(39,CR), Cir(40,CR), Cir(42,CR), Cir(61,CR)
        ), Cir*)
        return (12, arr_circles)
    end

    if puzzle_id == 21:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(4,ST), Cir(15,ST), Cir(24,ST), Cir(54,ST), Cir(59,ST),
            Cir(12,CR), Cir(17,CR), Cir(21,CR), Cir(23,CR), Cir(40,CR), Cir(42,CR), Cir(47,CR), Cir(51,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 22:
        tempvar arr_circles : Cir* = cast(new(
            Cir(4,ST), Cir(12,ST), Cir(14,ST), Cir(28,ST), Cir(36,ST), Cir(39,ST), Cir(52,ST),
            Cir(16,CR), Cir(24,CR), Cir(38,CR), Cir(41,CR), Cir(43,CR), Cir(61,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 23:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(8,ST), Cir(27,ST), Cir(32,ST), Cir(34,ST), Cir(39,ST), Cir(44,ST), Cir(57,ST), Cir(61,ST),
            Cir(2,CR), Cir(7,CR), Cir(14,CR), Cir(21,CR), Cir(40,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 24:
        tempvar arr_circles : Cir* = cast(new(
            Cir(4,ST), Cir(14,ST), Cir(15,ST), Cir(20,ST), Cir(22,ST), Cir(24,ST), Cir(32,ST), Cir(36,ST), Cir(39,ST),
            Cir(10,CR), Cir(50,CR), Cir(53,CR), Cir(59,CR), Cir(60,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 25:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(24,ST), Cir(32,ST), Cir(35,ST), Cir(39,ST), Cir(53,ST),
            Cir(7,CR), Cir(10,CR), Cir(21,CR), Cir(23,CR), Cir(44,CR), Cir(50,CR), Cir(59,CR), Cir(63,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 26:
        tempvar arr_circles : Cir* = cast(new(
            Cir(23,ST), Cir(29,ST), Cir(35,ST), Cir(36,ST), Cir(37,ST), Cir(47,ST), Cir(60,ST),
            Cir(3,CR), Cir(4,CR), Cir(7,CR), Cir(10,CR), Cir(32,CR), Cir(40,CR), Cir(56,CR), Cir(63,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 27:
        tempvar arr_circles : Cir* = cast(new(
            Cir(24,ST), Cir(27,ST), Cir(32,ST), Cir(35,ST), Cir(43,ST), Cir(47,ST), Cir(49,ST), Cir(60,ST),
            Cir(2,CR), Cir(3,CR), Cir(22,CR), Cir(25,CR), Cir(29,CR), Cir(31,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 28:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(2,ST), Cir(6,ST), Cir(22,ST), Cir(24,ST), Cir(30,ST), Cir(57,ST),
            Cir(4,CR), Cir(20,CR), Cir(26,CR), Cir(39,CR), Cir(40,CR), Cir(42,CR), Cir(44,CR), Cir(51,CR), Cir(60,CR), Cir(63,CR)
        ), Cir*)
        return (17, arr_circles)
    end

    if puzzle_id == 29:
        tempvar arr_circles : Cir* = cast(new(
            Cir(5,ST), Cir(8,ST), Cir(9,ST), Cir(10,ST), Cir(18,ST), Cir(32,ST), Cir(43,ST), Cir(45,ST), Cir(57,ST), Cir(59,ST),
            Cir(7,CR), Cir(20,CR), Cir(31,CR), Cir(39,CR), Cir(63,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 30:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(6,ST), Cir(11,ST), Cir(14,ST), Cir(17,ST), Cir(20,ST), Cir(28,ST), Cir(36,ST), Cir(39,ST), Cir(60,ST),
            Cir(32,CR), Cir(43,CR), Cir(54,CR), Cir(56,CR), Cir(59,CR), Cir(63,CR)
        ), Cir*)
        return (16, arr_circles)
    end

    if puzzle_id == 31:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(17,ST), Cir(25,ST), Cir(26,ST), Cir(39,ST), Cir(48,ST), Cir(49,ST), Cir(54,ST),
            Cir(7,CR), Cir(12,CR), Cir(21,CR), Cir(23,CR), Cir(41,CR), Cir(52,CR), Cir(61,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 32:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(2,ST), Cir(24,ST), Cir(33,ST), Cir(35,ST), Cir(36,ST), Cir(48,ST), Cir(49,ST), Cir(51,ST), Cir(61,ST),
            Cir(4,CR), Cir(7,CR), Cir(20,CR), Cir(29,CR), Cir(31,CR), Cir(54,CR), Cir(63,CR)
        ), Cir*)
        return (17, arr_circles)
    end

    if puzzle_id == 33:
        tempvar arr_circles : Cir* = cast(new(
            Cir(9,ST), Cir(13,ST), Cir(27,ST), Cir(28,ST), Cir(29,ST), Cir(34,ST), Cir(35,ST), Cir(41,ST), Cir(51,ST), Cir(54,ST), Cir(57,ST), Cir(61,ST),
            Cir(7,CR), Cir(16,CR), Cir(18,CR), Cir(47,CR)
        ), Cir*)
        return (16, arr_circles)
    end

    if puzzle_id == 34:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(9,ST), Cir(15,ST), Cir(16,ST), Cir(27,ST), Cir(31,ST), Cir(35,ST), Cir(37,ST), Cir(41,ST), Cir(49,ST), Cir(50,ST), Cir(53,ST), Cir(57,ST),
            Cir(5,CR), Cir(12,CR), Cir(28,CR), Cir(45,CR), Cir(47,CR)
        ), Cir*)
        return (18, arr_circles)
    end

    if puzzle_id == 35:
        tempvar arr_circles : Cir* = cast(new(
            Cir(2,ST), Cir(5,ST), Cir(18,ST), Cir(26,ST), Cir(31,ST), Cir(36,ST), Cir(37,ST), Cir(40,ST), Cir(50,ST), Cir(55,ST),
            Cir(0,CR), Cir(13,CR), Cir(16,CR), Cir(56,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 36:
        tempvar arr_circles : Cir* = cast(new(
            Cir(8,ST), Cir(10,ST), Cir(13,ST), Cir(14,ST), Cir(22,ST), Cir(33,ST), Cir(37,ST), Cir(39,ST), Cir(53,ST), Cir(54,ST), Cir(59,ST), Cir(62,ST),
            Cir(16,CR), Cir(29,CR), Cir(40,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 37:
        tempvar arr_circles : Cir* = cast(new(
            Cir(10,ST), Cir(16,ST), Cir(29,ST), Cir(38,ST), Cir(41,ST), Cir(46,ST), Cir(49,ST), Cir(54,ST), Cir(60,ST),
            Cir(3,CR), Cir(22,CR), Cir(27,CR), Cir(31,CR), Cir(42,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 38:
        tempvar arr_circles : Cir* = cast(new(
            Cir(13,ST), Cir(21,ST), Cir(31,ST), Cir(37,ST), Cir(49,ST), Cir(53,ST),
            Cir(7,CR), Cir(16,CR), Cir(18,CR), Cir(34,CR), Cir(40,CR), Cir(45,CR), Cir(63,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 39:
        tempvar arr_circles : Cir* = cast(new(
            Cir(9,ST), Cir(10,ST), Cir(12,ST), Cir(13,ST), Cir(15,ST), Cir(16,ST), Cir(31,ST), Cir(43,ST), Cir(48,ST), Cir(51,ST),
            Cir(36,CR), Cir(41,CR), Cir(45,CR), Cir(47,CR), Cir(63,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 40:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(12,ST), Cir(17,ST), Cir(20,ST), Cir(25,ST), Cir(28,ST), Cir(30,ST), Cir(42,ST), Cir(58,ST),
            Cir(6,CR), Cir(32,CR), Cir(38,CR), Cir(45,CR), Cir(56,CR), Cir(61,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 41:
        tempvar arr_circles : Cir* = cast(new(
            Cir(4,ST), Cir(9,ST), Cir(22,ST), Cir(34,ST), Cir(38,ST), Cir(42,ST), Cir(43,ST),
            Cir(5,CR), Cir(16,CR), Cir(27,CR), Cir(29,CR), Cir(56,CR), Cir(59,CR), Cir(60,CR), Cir(63,CR)
        ), Cir*)
        return (15, arr_circles)
    end

    if puzzle_id == 42:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(9,ST), Cir(25,ST), Cir(33,ST), Cir(46,ST), Cir(60,ST),
            Cir(7,CR), Cir(14,CR), Cir(21,CR), Cir(34,CR), Cir(42,CR), Cir(56,CR), Cir(58,CR), Cir(63,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 43:
        tempvar arr_circles : Cir* = cast(new(
            Cir(3,ST), Cir(8,ST), Cir(14,ST), Cir(36,ST), Cir(51,ST), Cir(61,ST),
            Cir(12,CR), Cir(23,CR), Cir(34,CR), Cir(41,CR), Cir(46,CR), Cir(56,CR), Cir(63,CR)
        ), Cir*)
        return (13, arr_circles)
    end

    if puzzle_id == 44:
        tempvar arr_circles : Cir* = cast(new(
            Cir(47,ST), Cir(53,ST), Cir(59,ST),
            Cir(0,CR), Cir(4,CR), Cir(5,CR), Cir(7,CR), Cir(16,CR), Cir(27,CR), Cir(28,CR), Cir(34,CR), Cir(35,CR), Cir(37,CR), Cir(56,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 45:
        tempvar arr_circles : Cir* = cast(new(
            Cir(1,ST), Cir(4,ST), Cir(9,ST), Cir(11,ST), Cir(18,ST), Cir(34,ST), Cir(37,ST), Cir(39,ST), Cir(42,ST), Cir(59,ST),
            Cir(23,CR), Cir(32,CR), Cir(56,CR), Cir(63,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 46:
        tempvar arr_circles : Cir* = cast(new(
            Cir(6,ST), Cir(10,ST), Cir(31,ST), Cir(32,ST), Cir(34,ST), Cir(37,ST), Cir(57,ST), Cir(60,ST),
            Cir(0,CR), Cir(13,CR), Cir(20,CR), Cir(36,CR), Cir(40,CR), Cir(46,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 47:
        tempvar arr_circles : Cir* = cast(new(
            Cir(10,ST), Cir(18,ST), Cir(20,ST), Cir(24,ST), Cir(26,ST), Cir(31,ST), Cir(58,ST),
            Cir(0,CR), Cir(38,CR), Cir(40,CR), Cir(43,CR), Cir(56,CR), Cir(59,CR), Cir(62,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 48:
        tempvar arr_circles : Cir* = cast(new(
            Cir(9,ST), Cir(10,ST), Cir(11,ST), Cir(24,ST), Cir(34,ST), Cir(42,ST),
            Cir(7,CR), Cir(20,CR), Cir(30,CR), Cir(37,CR), Cir(53,CR), Cir(56,CR), Cir(59,CR), Cir(60,CR)
        ), Cir*)
        return (14, arr_circles)
    end

    if puzzle_id == 49:
        tempvar arr_circles : Cir* = cast(new(
            Cir(6,ST), Cir(14,ST), Cir(22,ST), Cir(29,ST), Cir(32,ST), Cir(37,ST), Cir(45,ST), Cir(46,ST), Cir(54,ST),
            Cir(0,CR), Cir(9,CR), Cir(19,CR), Cir(33,CR), Cir(35,CR), Cir(58,CR), Cir(59,CR)
        ), Cir*)
        return (16, arr_circles)
    end

    with_attr error_message ("invalid puzzle_id"):
        assert 1 = 0
    end
    return (0, arr_circles)
end
