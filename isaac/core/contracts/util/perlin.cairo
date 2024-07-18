%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem, unsigned_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    PLANET_DIM, SCALE_FP, SCALE_FP_DIV_100, RANGE_CHECK_BOUND, SCALE_FP_DIV_PLANET_DIM,
    ns_perlin
)
from contracts.util.structs import (Vec2)
from contracts.util.numerics import (div_fp, mul_fp)

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
        face : felt,
        element_type : felt
    ) -> (
        rv_bottom_left : Vec2,
        rv_top_left : Vec2,
        rv_bottom_right : Vec2,
        rv_top_right : Vec2
    ):
    alloc_locals

    if face == 0:
        # 0,1,3,0
        let (rv_bottom_left)  = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_top_left)     = ns_perlin.random_vector_lookup (element_type, 1)
        let (rv_bottom_right) = ns_perlin.random_vector_lookup (element_type, 3)
        let (rv_top_right)    = ns_perlin.random_vector_lookup (element_type, 0)
        return (
            rv_bottom_left, rv_top_left, rv_bottom_right, rv_top_right
        )
    end

    if face == 1:
        # 0,3,2,3
        let (rv_bottom_left)  = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_top_left)     = ns_perlin.random_vector_lookup (element_type, 3)
        let (rv_bottom_right) = ns_perlin.random_vector_lookup (element_type, 2)
        let (rv_top_right)    = ns_perlin.random_vector_lookup (element_type, 3)
        return (
            rv_bottom_left, rv_top_left, rv_bottom_right, rv_top_right
        )
    end

    if face == 2:
        # 3,0,3,0
        let (rv_bottom_left)  = ns_perlin.random_vector_lookup (element_type, 3)
        let (rv_top_left)     = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_bottom_right) = ns_perlin.random_vector_lookup (element_type, 3)
        let (rv_top_right)    = ns_perlin.random_vector_lookup (element_type, 0)
        return (
            rv_bottom_left, rv_top_left, rv_bottom_right, rv_top_right
        )
    end

    if face == 3:
        # 0,1,0,2
        let (rv_bottom_left)  = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_top_left)     = ns_perlin.random_vector_lookup (element_type, 1)
        let (rv_bottom_right) = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_top_right)    = ns_perlin.random_vector_lookup (element_type, 2)
        return (
            rv_bottom_left, rv_top_left, rv_bottom_right, rv_top_right
        )
    end

    if face == 4:
        # 3,0,2,2
        let (rv_bottom_left)  = ns_perlin.random_vector_lookup (element_type, 3)
        let (rv_top_left)     = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_bottom_right) = ns_perlin.random_vector_lookup (element_type, 2)
        let (rv_top_right)    = ns_perlin.random_vector_lookup (element_type, 2)
        return (
            rv_bottom_left, rv_top_left, rv_bottom_right, rv_top_right
        )
    end

    if face == 5:
        # 2,2,0,1
        let (rv_bottom_left)  = ns_perlin.random_vector_lookup (element_type, 2)
        let (rv_top_left)     = ns_perlin.random_vector_lookup (element_type, 2)
        let (rv_bottom_right) = ns_perlin.random_vector_lookup (element_type, 0)
        let (rv_top_right)    = ns_perlin.random_vector_lookup (element_type, 1)
        return (
            rv_bottom_left, rv_top_left, rv_bottom_right, rv_top_right
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
    let (prod) = mul_fp (t, b-a)
    let res = a + prod

    return (res)
end

@event
func debug_emit_vec2 (vec : Vec2):
end

@event
func debug_emit_felt (x : felt):
end

func get_perlin_value {syscall_ptr : felt*, range_check_ptr} (
        face : felt,
        grid : Vec2,
        element_type : felt
    ) -> (
        res : felt
    ):
    alloc_locals

    #
    # Normalize grid[0] and grid[1] into range [0,PLANET_DIM) by subtracting values from corner grid
    #
    let (pos : Vec2) = normalize_grid (face, grid)

    #
    # Compute four positional vectors - from corners to pos - in fixed-point range
    #
    let S = SCALE_FP_DIV_PLANET_DIM
    let pv_bottom_left_fp = Vec2 (
        pos.x * S,
        pos.y * S
    )
    let pv_top_left_fp = Vec2 (
        pos.x * S,
        (pos.y - (PLANET_DIM - 1)) * S
    )
    let pv_bottom_right_fp = Vec2 (
        (pos.x - (PLANET_DIM - 1)) * S,
        pos.y * S
    )
    let pv_top_right_fp = Vec2 (
        (pos.x - (PLANET_DIM - 1)) * S,
        (pos.y - (PLANET_DIM - 1)) * S
    )
    debug_emit_vec2.emit (pv_bottom_left_fp)
    debug_emit_vec2.emit (pv_top_left_fp)
    debug_emit_vec2.emit (pv_bottom_right_fp)
    debug_emit_vec2.emit (pv_top_right_fp)

    #
    # Retrieve four random vectors given face
    #
    let (
        rv_bottom_left : Vec2,
        rv_top_left : Vec2,
        rv_bottom_right : Vec2,
        rv_top_right : Vec2
    ) = get_random_vecs (face, element_type)

    debug_emit_vec2.emit (rv_bottom_left)
    debug_emit_vec2.emit (rv_top_left)
    debug_emit_vec2.emit (rv_bottom_right)
    debug_emit_vec2.emit (rv_top_right)

    #
    # Compute dot products
    #
    let (prod_bottom_left_fp)  = dot (pv_bottom_left_fp,  rv_bottom_left)
    let (prod_top_left_fp)     = dot (pv_top_left_fp,     rv_top_left)
    let (prod_bottom_right_fp) = dot (pv_bottom_right_fp, rv_bottom_right)
    let (prod_top_right_fp)    = dot (pv_top_right_fp,    rv_top_right)

    # debug_emit_felt.emit (prod_bottom_left)
    # debug_emit_felt.emit (prod_top_left)
    # debug_emit_felt.emit (prod_bottom_right)
    # debug_emit_felt.emit (prod_top_right)

    #
    # Compute u,v from fade()
    #
    let (u) = fade (pos.x * SCALE_FP_DIV_PLANET_DIM)
    let (v) = fade (pos.y * SCALE_FP_DIV_PLANET_DIM)
    debug_emit_felt.emit (u)
    debug_emit_felt.emit (v)

    #
    # Perform lerp
    #
    let (lerp_left_fp)  = lerp (v, prod_bottom_left_fp, prod_top_left_fp)
    let (lerp_right_fp) = lerp (v, prod_bottom_right_fp, prod_top_right_fp)
    let (lerp_final_fp) = lerp (u, lerp_left_fp, lerp_right_fp)

    # debug_emit_felt.emit (lerp_left_fp)
    # debug_emit_felt.emit (lerp_right_fp)
    debug_emit_felt.emit (lerp_final_fp)

    return (lerp_final_fp)
end
