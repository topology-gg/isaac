%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem, unsigned_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    PLANET_DIM, SCALE_FP, SCALE_FP_DIV_100, RANGE_CHECK_BOUND,
    ns_perlin
)
from contracts.util.structs import (Vec2)
from contracts.macro import (div_fp, mul_fp)

# See README for illustration of the coordinate system and face/edge indexing scheme

func normalize_grid {range_check_ptr} (
        face : felt, grid : Vec2
    ) -> (pos : Vec2):

    if face == 0:
        return (Vec2 (grid.x - 0, grid.y - PLANET_DIM))
    end

    if face == 1:
        return (Vec2 (grid.x - PLANET_DIM, grid.y - 0))
    end

    if face == 2:
        return (Vec2 (grid.x - PLANET_DIM, grid.y - PLANET_DIM))
    end

    if face == 3:
        return (Vec2 (grid.x - PLANET_DIM, grid.y - 2*PLANET_DIM))
    end

    if face == 4:
        return (Vec2 (grid.x - 2*PLANET_DIM, grid.y - PLANET_DIM))
    end

    if face == 5:
        return (Vec2 (grid.x - 3*PLANET_DIM, grid.y - PLANET_DIM))
    end

    with_attr error_message ("invalid face"):
        assert 1 = 0
    end
    return (Vec2(0,0))
end

func get_random_vecs {range_check_ptr} (
        face : felt
    ) -> (
        rv_bottom_left : Vec2,
        rv_top_left : Vec2,
        rv_bottom_right : Vec2,
        rv_top_right : Vec2
    ):

    if face == 0:
        # (-1.0, 1.0), (-1.0, 1.0), (-1.0, 1.0), (-1.0, -1.0)
        return (
            Vec2 (-1, 1), Vec2 (-1, 1), Vec2 (-1, 1), Vec2 (-1, -1)
        )
    end

    if face == 1:
        # (1.0, 1.0), (-1.0, 1.0), (1.0, -1.0), (-1.0, -1.0)
        return (
            Vec2 (1, 1), Vec2 (-1, 1), Vec2 (1, -1), Vec2 (-1, -1)
        )
    end

    if face == 2:
        # (-1.0, 1.0), (-1.0, -1.0), (-1.0, -1.0), (1.0, -1.0)
        return (
            Vec2 (-1, 1), Vec2 (-1, -1), Vec2 (-1, -1), Vec2 (1, -1)
        )
    end

    if face == 3:
        # (-1.0, -1.0), (1.0, -1.0), (1.0, -1.0), (1.0, 1.0)
        return (
            Vec2 (-1, -1), Vec2 (1, -1), Vec2 (1, -1), Vec2 (1, 1)
        )
    end

    if face == 4:
        # (-1.0, -1.0), (1.0, -1.0), (1.0, 1.0), (-1.0, -1.0)
        return (
            Vec2 (-1, -1), Vec2 (1, -1), Vec2 (1, 1), Vec2 (-1, -1)
        )
    end

    if face == 5:
        # (1.0, 1.0), (-1.0, -1.0), (1.0, 1.0), (-1.0, 1.0)
        return (
            Vec2 (1, 1), Vec2 (-1, -1), Vec2 (1, 1), Vec2 (-1, 1)
        )
    end

    with_attr error_message ("invalid face"):
        assert 1 = 0
    end

    return (
        Vec2 (0,0), Vec2 (0,0), Vec2 (0,0), Vec2 (0,0)
    )

end

func dot {range_check_ptr} (
        v1 : Vec2, v2 : Vec2
    ) -> (res : felt):

    return (v1.x * v2.x + v1.y * v2.y)

end

func fade {range_check_ptr} (
    t : felt) -> (res : felt):

    #
    # fade = lambda t : ((6*t - 15)*t + 10)*t*t*t
    #
    let a   = 6 * t - 15*SCALE_FP
    let (b) = mul_fp (a, t)
    let c   = b + 10*SCALE_FP
    let (d) = mul_fp (c, t)
    let (e) = mul_fp (d, t)
    let (f) = mul_fp (e, t)

    return (f)
end

func lerp {range_check_ptr} (
        t : felt,
        a : felt,
        b : felt
    ) -> (res : felt):

    #
    # lerp = lambda t,a,b : a + t * (b-a)
    #
    let (c) = mul_fp (t, b-a)
    let d = a + c

    return (d)
end

@event
func debug_emit_vec2 (vec : Vec2):
end

@event
func debug_emit_felt (x : felt):
end

func get_perlin_value {syscall_ptr : felt*, range_check_ptr} (
        face : felt, permuted_face : felt, grid : Vec2
    ) -> (res : felt):
    alloc_locals

    #
    # Normalize grid[0] and grid[1] into range [0,99] by subtracting values from corner grid
    #
    let (pos : Vec2) = normalize_grid (face, grid)

    #
    # Compute four positional vectors - from corners to pos - in fixed-point range
    #
    let pv_bottom_left = Vec2 (pos.x * SCALE_FP_DIV_100, pos.y * SCALE_FP_DIV_100)
    let pv_top_left = Vec2 (pos.x * SCALE_FP_DIV_100, pos.y * SCALE_FP_DIV_100 - 99 * SCALE_FP_DIV_100)
    let pv_bottom_right = Vec2 (pos.x * SCALE_FP_DIV_100 - 99 * SCALE_FP_DIV_100, pos.y * SCALE_FP_DIV_100)
    let pv_top_right = Vec2 (pos.x * SCALE_FP_DIV_100 - 99 * SCALE_FP_DIV_100, pos.y * SCALE_FP_DIV_100 - 99 * SCALE_FP_DIV_100)

    # debug_emit_vec2.emit (pv_bottom_left)
    # debug_emit_vec2.emit (pv_top_left)
    # debug_emit_vec2.emit (pv_bottom_right)
    # debug_emit_vec2.emit (pv_top_right)

    #
    # Retrieve four random vectors given face
    #
    let (
        rv_bottom_left : Vec2,
        rv_top_left : Vec2,
        rv_bottom_right : Vec2,
        rv_top_right : Vec2
    ) = get_random_vecs (permuted_face)

    # debug_emit_vec2.emit (rv_bottom_left)
    # debug_emit_vec2.emit (rv_top_left)
    # debug_emit_vec2.emit (rv_bottom_right)
    # debug_emit_vec2.emit (rv_top_right)

    #
    # Compute dot products
    #
    let (prod_bottom_left)  = dot (pv_bottom_left,  rv_bottom_left)
    let (prod_top_left)     = dot (pv_top_left,     rv_top_left)
    let (prod_bottom_right) = dot (pv_bottom_right, rv_bottom_right)
    let (prod_top_right)    = dot (pv_top_right,    rv_top_right)

    # debug_emit_felt.emit (prod_bottom_left)
    # debug_emit_felt.emit (prod_top_left)
    # debug_emit_felt.emit (prod_bottom_right)
    # debug_emit_felt.emit (prod_top_right)

    #
    # Compute u,v from fade()
    #
    let (u) = fade (pos.x * SCALE_FP_DIV_100)
    let (v) = fade (pos.y * SCALE_FP_DIV_100)

    # debug_emit_felt.emit (u)
    # debug_emit_felt.emit (v)

    #
    # Perform lerp
    #
    let (lerp_left)  = lerp (v, prod_bottom_left, prod_top_left)
    let (lerp_right) = lerp (v, prod_bottom_right, prod_top_right)
    let (lerp_final) = lerp (u, lerp_left, lerp_right)

    # debug_emit_felt.emit (lerp_left)
    # debug_emit_felt.emit (lerp_right)
    # debug_emit_felt.emit (lerp_final)

    return (lerp_final)
end
