%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.util.structs import (Vec2)
from contracts.util.grid import (
    is_valid_grid,
    are_contiguous_grids_given_valid_grids,
    are_contiguous_grids_given_valid_grids_on_same_face,
    locate_face_and_edge_given_valid_grid
)

@view
func mock_is_valid_grid {range_check_ptr} (
        grid : Vec2
    ) -> ():

    is_valid_grid (grid)

    return ()
end

@view
func mock_are_contiguous_grids_given_valid_grids {range_check_ptr} (
        grid0 : Vec2, grid1 : Vec2
    ) -> ():

    are_contiguous_grids_given_valid_grids (grid0, grid1)

    return ()
end

@view
func mock_are_contiguous_grids_given_valid_grids_on_same_face {range_check_ptr} (
        grid0 : Vec2, grid1 : Vec2
    ) -> ():

    are_contiguous_grids_given_valid_grids_on_same_face (grid0, grid1)

    return ()
end

@view
func mock_locate_face_and_edge_given_valid_grid {range_check_ptr} (
        grid : Vec2
    ) -> (
        face : felt,
        is_on_edge : felt,
        edge : felt,
        idx_on_edge : felt
    ):

    let (
        face : felt,
        is_on_edge : felt,
        edge : felt,
        idx_on_edge : felt
    ) = locate_face_and_edge_given_valid_grid (grid)

    return (
        face,
        is_on_edge,
        edge,
        idx_on_edge
    )
end
