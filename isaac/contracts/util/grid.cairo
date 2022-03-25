%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value)
from starkware.cairo.common.math_cmp import is_le, is_not_zero, is_nn_le
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    PLANET_DIM,
    FACE_0, FACE_1, FACE_2, FACE_3, FACE_4, FACE_5,
    EDGE_0, EDGE_1, EDGE_2, EDGE_3, EDGE_4, EDGE_5, EDGE_6, EDGE_7, EDGE_8, EDGE_9, EDGE_10)
from contracts.util.structs import (Vec2)

# The planet cube unfolds as follows:
#   ▢
#  ▢▢▢▢
#   ▢
# with grid system (0,0) at the bottom left corner.
# Face labels:
#   3
#  0245
#   1
# See README for illustration

#
# Check if a single given grid is valid i.e. falls on the cube; revert if not
#
func is_valid_grid {range_check_ptr} (
        grid : Vec2
    ) -> ():
    alloc_locals

    # grid should be in quadrant one
    assert_nn (grid.x)
    assert_nn (grid.y)

    # grid should not fall in square [0~D-1, 0~D-1]
    let (flag0) = is_le (grid.x, PLANET_DIM-1)
    let (flag1) = is_le (grid.y, PLANET_DIM-1)
    assert flag0 * flag1 = 0

    # grid should not fall in rectangle [2D~, 0~D-1]
    let (flag2) = is_le (2*PLANET_DIM, grid.x)
    assert flag2 * flag1 = 0

    # grid should not fall in rectangle [0~D-1, 2D~]
    let (flag3) = is_le (2*PLANET_DIM, grid.y)
    assert flag0 * flag3 = 0

    # grid should not fall in rectangle [2D~, 2D~]
    assert flag2 * flag3 = 0

    return ()
end

#
# Check if two grids are contiguous; revert if not
#
func are_contiguous_grids_given_valid_grids {range_check_ptr} (
        grid0 : Vec2, grid1 : Vec2
    ) -> ():
    alloc_locals

    let (face0, is_on_edge0, edge0, idx_on_edge0) = locate_face_and_edge_given_valid_grid (grid0)
    let (face1, is_on_edge1, edge1, idx_on_edge1) = locate_face_and_edge_given_valid_grid (grid1)

    #
    # If on the same face => simple check
    #
    if face0 == face1:
        are_contiguous_grids_given_valid_grids_on_same_face (grid0, grid1)
        return ()
    end

    #
    # On difference faces, both need to be on edge + on the same edge + have the same idx_on_edge
    #
    assert_not_zero (is_on_edge0 * is_on_edge1)
    assert edge0 - edge1 = 0
    assert idx_on_edge0 - idx_on_edge1 = 0

    return ()
end


func are_contiguous_grids_given_valid_grids_on_same_face {range_check_ptr} (
        grid0 : Vec2, grid1 : Vec2
    ) -> ():
    alloc_locals

    let (x_diff_abs) = abs_value (grid0.x - grid1.x)
    let (y_diff_abs) = abs_value (grid0.y - grid1.y)
    let sum_diff_abs = x_diff_abs + y_diff_abs

    assert sum_diff_abs = 1
    return ()
end


func locate_face_and_edge_given_valid_grid {range_check_ptr} (
        grid : Vec2
    ) -> (
        face : felt,
        is_on_edge : felt,
        edge : felt,
        idx_on_edge : felt
    ):
    alloc_locals

    let (flag0) = is_nn_le (grid.x, PLANET_DIM-1)
    let (flag1) = is_nn_le (grid.x - (PLANET_DIM), PLANET_DIM-1)
    let (flag2) = is_nn_le (grid.x - (2*PLANET_DIM), PLANET_DIM-1)
    let (flag3) = is_nn_le (grid.x - (3*PLANET_DIM), PLANET_DIM-1)
    let (flag4) = is_nn_le (grid.y, PLANET_DIM-1)
    let (flag5) = is_nn_le (grid.y - (PLANET_DIM), PLANET_DIM-1)
    let (flag6) = is_nn_le (grid.y - (2*PLANET_DIM), PLANET_DIM-1)

    #
    # Locate face
    #
    local face
    if flag0 * flag5 == 1:
        assert face = FACE_0
        jmp face_determined
    end
    if flag1 * flag4 == 1:
        assert face = FACE_1
        jmp face_determined
    end
    if flag1 * flag5 == 1:
        assert face = FACE_2
        jmp face_determined
    end
    if flag1 * flag6 == 1:
        assert face = FACE_3
        jmp face_determined
    end
    if flag2 * flag5 == 1:
        assert face = FACE_4
        jmp face_determined
    end
    assert face = FACE_5

    face_determined:
    #
    # Check if on edge
    #
    let (flag7)  = is_zero (grid.x)
    let (flag8)  = is_zero (grid.x - PLANET_DIM)
    let (flag9)  = is_zero (grid.x - (2*PLANET_DIM-1))
    let (flag10) = is_zero (grid.x - (4*PLANET_DIM-1))
    let (flag11) = is_zero (grid.y)
    let (flag12) = is_zero (grid.y - (PLANET_DIM))
    let (flag13) = is_zero (grid.y - (2*PLANET_DIM-1))
    let (flag14) = is_zero (grid.y - (3*PLANET_DIM-1))

    local is_on_edge
    local edge
    local idx_on_edge


    ## Deal with special edges first (7-10)
    #
    # Edge 7
    #
    let (flag15) = is_zero (grid.x - (3*PLANET_DIM-1))
    let (flag16) = is_zero (grid.x - 3*PLANET_DIM)
    if flag9 * flag14 + flag15 * flag13 + flag16 * flag13 == 1:
        assert is_on_edge = 1
        assert edge = EDGE_7
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 8
    #
    if flag9 * flag11 + flag15 * flag12 + flag16 * flag12 == 1:
        assert is_on_edge = 1
        assert edge = EDGE_8
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 9
    #
    if flag10 * flag13 + flag8 * flag14 + flag7 * flag13 == 1:
        assert is_on_edge = 1
        assert edge = EDGE_9
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 10
    #
    if flag10 * flag12 + flag8 * flag11 + flag7 * flag12 == 1:
        assert is_on_edge = 1
        assert edge = EDGE_10
        assert idx_on_edge = 0
        jmp edge_determined
    end

    ## Deal with normal edges (0-6)
    #
    # Edge 0
    #
    if flag4*flag8 == 1:
        ## (D, 1 -> D-1)
        assert is_on_edge = 1
        assert edge = EDGE_0
        assert idx_on_edge = grid.y - 1
        jmp edge_determined
    end
    if flag0*flag12 == 1:
        ## (1 -> D-1, D)
        assert is_on_edge = 1
        assert edge = EDGE_0
        assert idx_on_edge = grid.x - 1
        jmp edge_determined
    end

    #
    # Edge 1
    #
    if flag6*flag8 == 1:
        ## (D, 3D-2 -> 2D)
        assert is_on_edge = 1
        assert edge = EDGE_1
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.y
        jmp edge_determined
    end
    if flag0*flag13 == 1:
        ## (1 -> D-1, 2D-1)
        assert is_on_edge = 1
        assert edge = EDGE_1
        assert idx_on_edge = grid.x - 1
        jmp edge_determined
    end

    #
    # Edge 2
    #
    if flag6*flag9 == 1:
        ## (2D-1, 3D-2 -> 2D)
        assert is_on_edge = 1
        assert edge = EDGE_2
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.y
        jmp edge_determined
    end
    if flag2*flag13 == 1:
        ## (3D-2 -> 2D, 2D-1)
        assert is_on_edge = 1
        assert edge = EDGE_2
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end

    #
    # Edge 3
    #
    if flag4*flag9 == 1:
        ## (2D-1, 1 -> D-1)
        assert is_on_edge = 1
        assert edge = EDGE_3
        assert idx_on_edge = grid.y - 1
        jmp edge_determined
    end
    if flag2*flag12 == 1:
        ## (3D-2 -> 2D, D)
        assert is_on_edge = 1
        assert edge = EDGE_3
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end

    #
    # Edge 4
    #
    if flag1*flag14 == 1:
        ## (2D-2 -> D+1, 3D-1)
        assert is_on_edge = 1
        assert edge = EDGE_4
        assert idx_on_edge = 2*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end
    if flag3*flag13 == 1:
        ## (3D+1 -> 4D-2, 2D-1)
        assert is_on_edge = 1
        assert edge = EDGE_4
        assert idx_on_edge = grid.x - (3*PLANET_DIM+1)
        jmp edge_determined
    end

    #
    # Edge 5
    #
    if flag1*flag11 == 1:
        ## (2D-2 -> D+1, 0)
        assert is_on_edge = 1
        assert edge = EDGE_5
        assert idx_on_edge = 2*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end
    if flag3*flag12 == 1:
        ## (3D+1 -> 4D-2, D)
        assert is_on_edge = 1
        assert edge = EDGE_5
        assert idx_on_edge = grid.x - (3*PLANET_DIM+1)
        jmp edge_determined
    end

    #
    # Edge 6
    #
    if flag5*flag7 == 1:
        ## (0, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = EDGE_6
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end
    if flag5*flag10 == 1:
        ## (4D-1, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = EDGE_6
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end

    assert is_on_edge = 0
    assert edge = 0
    assert idx_on_edge = 0

    edge_determined:
    return (face, is_on_edge, edge, idx_on_edge)
end

func is_zero {range_check_ptr} (x) -> (bool):
    let (inz) = is_not_zero (x)
    if inz == 0:
        return (1)
    end
    return (0)
end
