%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem, unsigned_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    ns_perlin
)
from contracts.util.perlin import (
    get_perlin_value
)
from contracts.util.grid import (
    locate_face_and_edge_given_valid_grid
)

func get_concentration_at_grid_given_element_type {syscall_ptr : felt*, range_check_ptr} (
        grid : Vec2,
        element_type : felt
    ) -> (
        res : felt
    ):

    let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)



end