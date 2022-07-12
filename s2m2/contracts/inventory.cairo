%lang starknet

from starkware.cairo.common.alloc import alloc

const PUZZLE_COUNT = 1
const PUZZLE_DIM = 8
const BLACK = 1
const WHITE = 2

#
# Circle.type: {BLACK, WHITE}
#
struct Circle:
    member cell_index : felt
    member type : felt
end

func _get_puzzle {range_check_ptr} (
        puzzle_id : felt
    ) -> (
        arr_circles_len : felt,
        arr_circles : Circle*
    ):

    let (arr_circles : Circle*) = alloc ()

    if puzzle_id == 0:
        # white: 3, 8, 12, 28, 44, 47, 49, 61
        # black: 11, 20, 22, 29, 31, 33, 35, 40,
        # assert arr_circles[0] = Circle (3, WHITE)
        # assert arr_circles[1] = Circle (8, WHITE)
        # assert arr_circles[2] = Circle (12, WHITE)
        # assert arr_circles[3] = Circle (28, WHITE)
        # assert arr_circles[4] = Circle (44, WHITE)
        # assert arr_circles[5] = Circle (47, WHITE)
        # assert arr_circles[6] = Circle (49, WHITE)
        # assert arr_circles[7] = Circle (61, WHITE)

        # assert arr_circles[8]  = Circle (11, BLACK)
        # assert arr_circles[9]  = Circle (20, BLACK)
        # assert arr_circles[10] = Circle (22, BLACK)
        # assert arr_circles[11] = Circle (29, BLACK)
        # assert arr_circles[12] = Circle (31, BLACK)
        # assert arr_circles[13] = Circle (33, BLACK)
        # assert arr_circles[14] = Circle (35, BLACK)
        # assert arr_circles[15] = Circle (40, BLACK)

        # ref: https://cairo-lang.org/docs/how_cairo_works/object_allocation.html#the-new-operator
        tempvar arr_circles : Circle* = cast(new(
            Circle(3,WHITE), Circle(8,WHITE), Circle(12,WHITE), Circle (28, WHITE), Circle (44, WHITE), Circle (47, WHITE), Circle (49, WHITE), Circle (61, WHITE),
            Circle (11, BLACK), Circle (20, BLACK), Circle (22, BLACK), Circle (29, BLACK), Circle (31, BLACK), Circle (33, BLACK), Circle (35, BLACK), Circle (40, BLACK)
        ), Circle*)

        return (16, arr_circles)
    end

    with_attr error_message ("invalid puzzle_id"):
        assert 1 = 0
    end
    return (0, arr_circles)

end