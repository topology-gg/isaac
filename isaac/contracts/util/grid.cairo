%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value)
from starkware.cairo.common.math_cmp import is_le, is_not_zero, is_nn_le
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    PLANET_DIM
)
from contracts.util.structs import (Vec2)

# See README for illustration of the coordinate system and face/edge indexing scheme

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

    #
    # Compute L1 norm
    #
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

    #
    # Make flags for bounding x-range
    #
    let (flag_xrg0) = is_nn_le (grid.x, PLANET_DIM-1)
    let (flag_xrg1) = is_nn_le (grid.x - (PLANET_DIM), PLANET_DIM-1)
    let (flag_xrg2) = is_nn_le (grid.x - (2*PLANET_DIM), PLANET_DIM-1)
    let (flag_xrg3) = is_nn_le (grid.x - (3*PLANET_DIM), PLANET_DIM-1)

    #
    # Make flags for bounding y-range
    #
    let (flag_yrg0) = is_nn_le (grid.y, PLANET_DIM-1)
    let (flag_yrg1) = is_nn_le (grid.y - (PLANET_DIM), PLANET_DIM-1)
    let (flag_yrg2) = is_nn_le (grid.y - (2*PLANET_DIM), PLANET_DIM-1)

    #
    # Locate face
    #
    local face
    if flag_xrg0 * flag_yrg1 == 1:
        assert face = 0
        jmp face_determined
    end
    if flag_xrg1 * flag_yrg0 == 1:
        assert face = 1
        jmp face_determined
    end
    if flag_xrg1 * flag_yrg1 == 1:
        assert face = 2
        jmp face_determined
    end
    if flag_xrg1 * flag_yrg2 == 1:
        assert face = 3
        jmp face_determined
    end
    if flag_xrg2 * flag_yrg1 == 1:
        assert face = 4
        jmp face_determined
    end
    assert face = 5

    face_determined:
    #
    # Make flags for pinpointing x-value
    #
    let (flag_xval0)  = is_zero (grid.x)
    let (flag_xval1)  = is_zero (grid.x - (PLANET_DIM-1))
    let (flag_xval2)  = is_zero (grid.x - PLANET_DIM)
    let (flag_xval3)  = is_zero (grid.x - (2*PLANET_DIM-1))
    let (flag_xval4)  = is_zero (grid.x - 2*PLANET_DIM)
    let (flag_xval5)  = is_zero (grid.x - (3*PLANET_DIM-1))
    let (flag_xval6)  = is_zero (grid.x - 3*PLANET_DIM)
    let (flag_xval7) = is_zero (grid.x - (4*PLANET_DIM-1))

    #
    # Make flags for pinpointing y-value
    #
    let (flag_yval0)  = is_zero (grid.y)
    let (flag_yval1)  = is_zero (grid.y - (PLANET_DIM-1))
    let (flag_yval2)  = is_zero (grid.y - PLANET_DIM)
    let (flag_yval3)  = is_zero (grid.y - (2*PLANET_DIM-1))
    let (flag_yval4)  = is_zero (grid.y - 2*PLANET_DIM)
    let (flag_yval5)  = is_zero (grid.y - (3*PLANET_DIM-1))


    local is_on_edge
    local edge
    local idx_on_edge
    ## Deal with special edges first (12-19)
    #
    # Edge 12
    #
    if flag_xval3 * flag_yval5 + (flag_xval5 + flag_xval6) * flag_yval3 == 1:
        assert is_on_edge = 1
        assert edge = 12
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 13
    #
    if flag_xval3 * flag_yval0 + (flag_xval5 + flag_xval6) * flag_yval2 == 1:
        assert is_on_edge = 1
        assert edge = 13
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 14
    #
    if flag_xval0 * flag_yval3 + flag_xval2 * flag_yval5 + flag_xval7 * flag_yval3 == 1:
        assert is_on_edge = 1
        assert edge = 14
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 15
    #
    if flag_xval0 * flag_yval2 + flag_xval2 * flag_yval0 + flag_xval7 * flag_yval2 == 1:
        assert is_on_edge = 1
        assert edge = 15
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 16
    #
    if flag_xval1 * flag_yval2 + flag_xval2 * (flag_yval1 + flag_yval2) == 1:
        assert is_on_edge = 1
        assert edge = 16
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 17
    #
    if flag_xval1 * flag_yval3 + flag_xval2 * (flag_yval3 + flag_yval4) == 1:
        assert is_on_edge = 1
        assert edge = 17
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 18
    #
    if flag_xval3 * (flag_yval3 + flag_yval4) + flag_xval4 * flag_yval3 == 1:
        assert is_on_edge = 1
        assert edge = 18
        assert idx_on_edge = 0
        jmp edge_determined
    end

    #
    # Edge 19
    #
    if flag_xval3 * (flag_yval1 + flag_yval2) + flag_xval4 * flag_yval2 == 1:
        assert is_on_edge = 1
        assert edge = 19
        assert idx_on_edge = 0
        jmp edge_determined
    end


    ## Deal with normal edges (0-11)
    # Edge 0,0
    if flag_xrg0 * flag_yval2 == 1:
        ## (1 -> D-2, D)
        assert is_on_edge = 1
        assert edge = 0
        assert idx_on_edge = grid.x - 1
        jmp edge_determined
    end
    # Edge 0,1
    if flag_yrg0 * flag_xval2 == 1:
        ## (D, 1 -> D-2)
        assert is_on_edge = 1
        assert edge = 0
        assert idx_on_edge = grid.y - 1
        jmp edge_determined
    end

    # Edge 1,0
    if flag_xrg0 * flag_yval3 == 1:
        ## (1 -> D-2, 2D-1)
        assert is_on_edge = 1
        assert edge = 1
        assert idx_on_edge = grid.x - 1
        jmp edge_determined
    end
    # Edge 1,3
    if flag_yrg2 * flag_xval2 == 1:
        ## (D, 3D-2 -> 2D+1)
        assert is_on_edge = 1
        assert edge = 1
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.y
        jmp edge_determined
    end

    # Edge 2,4
    if flag_xrg2 * flag_yval3 == 1:
        ## (3D-2 -> 2D+1, 2D-1)
        assert is_on_edge = 1
        assert edge = 2
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end
    if flag_yrg2 * flag_xval3 == 1:
        ## (2D-1, 3D-2 -> 2D+1)
        assert is_on_edge = 1
        assert edge = 2
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.y
        jmp edge_determined
    end

    # Edge 3,4
    if flag_xrg2 * flag_yval2 == 1:
        ## (3D-2 -> 2D+1, D)
        assert is_on_edge = 1
        assert edge = 3
        assert idx_on_edge = 3*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end
    # Edge 3,1
    if flag_yrg0 * flag_xval3 == 1:
        ## (2D-1, 1 -> D-2)
        assert is_on_edge = 1
        assert edge = 3
        assert idx_on_edge = grid.y - 1
        jmp edge_determined
    end

    # Edge 4,3
    if flag_xrg1 * flag_yval5 == 1:
        ## (2D-2 -> D+1, 3D-1)
        assert is_on_edge = 1
        assert edge = 4
        assert idx_on_edge = 2*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end
    # Edge 4,5
    if flag_xrg3 * flag_yval3 == 1:
        ## (3D+1 -> 4D-2, 2D-1)
        assert is_on_edge = 1
        assert edge = 4
        assert idx_on_edge = grid.x - (3*PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 5,1
    if flag_xrg1 * flag_yval0 == 1:
        ## (2D-2 -> D+1, 0)
        assert is_on_edge = 1
        assert edge = 5
        assert idx_on_edge = 2*PLANET_DIM-2 - grid.x
        jmp edge_determined
    end
    # Edge 5,5
    if flag_xrg3 * flag_yval2 == 1:
        ## (3D+1 -> 4D-2, D)
        assert is_on_edge = 1
        assert edge = 5
        assert idx_on_edge = grid.x - (3*PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 6,0
    if flag_yrg1 * flag_xval0 == 1:
        ## (0, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 6
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end
    # Edge 6,5
    if flag_yrg1 * flag_xval7 == 1:
        ## (4D-1, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 6
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 7,0
    if flag_yrg1 * flag_xval1 == 1:
        ## (D-1, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 7
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end
    # Edge 7,2
    if flag_yrg1 * flag_xval2 == 1:
        ## (D, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 7
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 8,1
    if flag_xrg1 * flag_yval1 == 1:
        ## (D+1 -> 2D-2, D-1)
        assert is_on_edge = 1
        assert edge = 8
        assert idx_on_edge = grid.x - (PLANET_DIM+1)
        jmp edge_determined
    end
    # Edge 8,2
    if flag_xrg1 * flag_yval2 == 1:
        ## (D+1 -> 2D-2, D)
        assert is_on_edge = 1
        assert edge = 8
        assert idx_on_edge = grid.x - (PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 9,2
    if flag_yrg1 * flag_xval3 == 1:
        ## (2D-1, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 9
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end
    # Edge 9,4
    if flag_yrg1 * flag_xval4 == 1:
        ## (2D, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 9
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 10,2
    if flag_xrg1 * flag_yval3 == 1:
        ## (D+1 -> 2D-2, 2D-1)
        assert is_on_edge = 1
        assert edge = 10
        assert idx_on_edge = grid.x - (PLANET_DIM+1)
        jmp edge_determined
    end
    # Edge 10,3
    if flag_xrg1 * flag_yval4 == 1:
        ## (D+1 -> 2D-2, 2D)
        assert is_on_edge = 1
        assert edge = 10
        assert idx_on_edge = grid.x - (PLANET_DIM+1)
        jmp edge_determined
    end

    # Edge 11,4
    if flag_yrg1 * flag_xval5 == 1:
        ## (3D-1, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 11
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end
    # Edge 11,5
    if flag_yrg1 * flag_xval6 == 1:
        ## (3D, D+1 -> 2D-2)
        assert is_on_edge = 1
        assert edge = 11
        assert idx_on_edge = grid.y - (PLANET_DIM+1)
        jmp edge_determined
    end

    # Not on edge
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
