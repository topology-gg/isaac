%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (signed_div_rem, unsigned_div_rem, sign, assert_nn, abs_value, assert_not_zero, sqrt)
from starkware.cairo.common.math_cmp import (is_nn, is_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from contracts.lib.structs import (Vec2, BallState, GameState, PlayerStats)
from contracts.lib.constants import (FP, RANGE_CHECK_BOUND, A_FRICTION)

func euler_step_single_circle_aabb_boundary {range_check_ptr} (
        dt : felt,
        c : BallState,
        params_len : felt,
        params : felt*
    ) -> (
        c_nxt : BallState,
        has_collided_with_boundary : felt
    ):
    alloc_locals

    #
    # Unpack parameters
    # params = [<circle radius>, <x_min>, <x_max>, <y_min>, <y_max>]
    #
    assert params_len = 5
    let x_min = [params + 1] + [params]
    let x_max = [params + 2] - [params]
    let y_min = [params + 3] + [params]
    let y_max = [params + 4] - [params]

    #
    # Calculate candidate nxt position and velocity
    #
    let (x_delta)    = mul_fp (c.vel.x, dt)
    local x_nxt_cand = c.pos.x + x_delta
    let (y_delta)    = mul_fp (c.vel.y, dt)
    local y_nxt_cand = c.pos.y + y_delta

    #
    # Check c <-> x boundary and y boundary and handle bounce
    #
    let (local b_xmax) = is_nn (x_nxt_cand - x_max)
    let (local b_xmin) = is_nn (x_min - x_nxt_cand)
    local x_nxt  = (1-b_xmax-b_xmin) * x_nxt_cand + b_xmax * x_max + b_xmin * x_min
    local vx_nxt = (1-b_xmax-b_xmin) * c.vel.x + b_xmax * (-c.vel.x) + b_xmin * (-c.vel.x)

    let (local b_ymin) = is_nn (y_min - y_nxt_cand)
    let (local b_ymax) = is_nn (y_nxt_cand - y_max)
    local y_nxt  = (1-b_ymin-b_ymax) * y_nxt_cand + b_ymin * y_min + b_ymax * y_max
    local vy_nxt = (1-b_ymin-b_ymax) * c.vel.y + b_ymin * (-c.vel.y) + b_ymax * (-c.vel.y)

    #
    # Summarizing the bools
    #
    tempvar bool_sum = b_xmax + b_xmin + b_ymin + b_ymax
    let (has_collided_with_boundary) = is_not_zero (bool_sum)
    let c_nxt = BallState (
        pos = Vec2 (x_nxt, y_nxt),
        vel = Vec2 (vx_nxt, vy_nxt),
        acc = c.acc
    )

    return (c_nxt, has_collided_with_boundary)
end

#################################

func collision_pair_circles {range_check_ptr} (
        c1 : BallState,
        c2 : BallState,
        c1_cand : BallState,
        c2_cand : BallState,
        params_len : felt,
        params : felt*
    ) -> (
        c1_nxt : BallState,
        c2_nxt : BallState,
        has_collided : felt
    ):
    alloc_locals

    #
    # Unpack parameters
    # params: [<circle radius>, <precomputed square of circle radius>]
    #
    assert params_len = 2
    let circle_r = [params]
    let circle_r2_sq = [params + 1]

    ## Algorithm for each circle:
    ##   if line-intersect with another cirlce's line => snap to impact position and exchange vx & vy
    ##   using cheap solution now: run circle-test at candidate position. Assumption: dt is small enough relatively to radius such that
    ##                             it is impossible for collision to happen without failing the circle-test at candidate positions
    ##   bettter solution: also check for *tunneling* i.e. collision that would have occurred inbetween frames, and handle it
    ##                     skipping this for now to focus on improving performance + vectorization

    ## Check whether candidate c1 collides with candidate c2
    tempvar x1mx2 = c1_cand.pos.x - c2_cand.pos.x
    let (local x1mx2_sq) = mul_fp (x1mx2, x1mx2)
    tempvar y1my2 = c1_cand.pos.y - c2_cand.pos.y
    let (y1my2_sq) = mul_fp (y1my2, y1my2)
    tempvar d12_sq = x1mx2_sq + y1my2_sq
    let (local bool_c1_c2_cand_collided) = is_le (d12_sq, circle_r2_sq)

    local range_check_ptr = range_check_ptr
    local x1_nxt
    local y1_nxt
    local x2_nxt
    local y2_nxt
    local vx1_nxt
    local vy1_nxt
    local vx2_nxt
    local vy2_nxt

    if bool_c1_c2_cand_collided == 0:
        #
        # Not colliding => finalize with candidate
        #
        assert x1_nxt  = c1_cand.pos.x
        assert y1_nxt  = c1_cand.pos.y
        assert x2_nxt  = c2_cand.pos.x
        assert y2_nxt  = c2_cand.pos.y
        assert vx1_nxt = c1_cand.vel.x
        assert vy1_nxt = c1_cand.vel.y
        assert vx2_nxt = c2_cand.vel.x
        assert vy2_nxt = c2_cand.vel.y

        tempvar range_check_ptr = range_check_ptr
    else:
        #
        # Handle c1 <-> c2 collision: back each off to the calculated impact point
        # TODO: add note on how to calculate
        #
        let (local d_cand) = distance_2pt (c1_cand.pos, c2_cand.pos)
        local nom = 2*circle_r - d_cand
        let (d) = distance_2pt (c1.pos, c2.pos)
        local denom = d - d_cand

        let (nom_x1) = mul_fp (nom, c1_cand.pos.x - c1.pos.x)
        let (x1_delta) = div_fp (nom_x1,denom)
        assert x1_nxt = c1_cand.pos.x - x1_delta

        let (nom_y1) = mul_fp (nom, c1_cand.pos.y - c1.pos.y)
        let (y1_delta) = div_fp (nom_y1,denom)
        assert y1_nxt = c1_cand.pos.y - y1_delta

        let (nom_x2) = mul_fp (nom, c2_cand.pos.x - c2.pos.x)
        let (x2_delta) = div_fp(nom_x2,denom)
        assert x2_nxt = c2_cand.pos.x - x2_delta

        let (nom_y2) = mul_fp (nom, c2_cand.pos.y - c2.pos.y)
        let (y2_delta) = div_fp (nom_y2,denom)
        assert y2_nxt = c2_cand.pos.y - y2_delta

        let (local alpha_nom1) = mul_fp ( c2.vel.x-c1.vel.x, x2_nxt-x1_nxt )
        let (local alpha_nom2) = mul_fp ( c2.vel.y-c1.vel.y, y2_nxt-y1_nxt )
        let (local alpha_denom1) = mul_fp ( x2_nxt-x1_nxt, x2_nxt-x1_nxt )
        let (alpha_denom2) = mul_fp ( y2_nxt-y1_nxt, y2_nxt-y1_nxt )
        let (local alpha) = div_fp ( alpha_nom1+alpha_nom2, alpha_denom1+alpha_denom2 )

        let (vx1_delta) = mul_fp ( alpha, x1_nxt-x2_nxt )
        assert vx1_nxt = c1.vel.x - vx1_delta

        let (vy1_delta) = mul_fp ( alpha, y1_nxt-y2_nxt )
        assert vy1_nxt = c1.vel.y - vy1_delta

        let (vx2_delta) = mul_fp ( alpha, x2_nxt-x1_nxt )
        assert vx2_nxt = c2.vel.x - vx2_delta

        let (vy2_delta) = mul_fp ( alpha, y2_nxt-y1_nxt )
        assert vy2_nxt = c2.vel.y - vy2_delta

        tempvar range_check_ptr = range_check_ptr
    end

    #
    # Pack to Vec2
    #
    let c1_nxt = BallState (
        pos = Vec2 (x1_nxt, y1_nxt),
        vel = Vec2 (vx1_nxt, vy1_nxt),
        acc = c1.acc
    )

    let c2_nxt = BallState (
        pos = Vec2 (x2_nxt, y2_nxt),
        vel = Vec2 (vx2_nxt, vy2_nxt),
        acc = c2.acc
    )

    tempvar has_collided = bool_c1_c2_cand_collided

    return (c1_nxt, c2_nxt, has_collided)
end

#################################

func friction_single_circle {range_check_ptr} (
        dt : felt,
        c : BallState,
        should_recalc : felt,
        a_friction : felt
    ) -> (
        c_nxt : BallState
    ):
    alloc_locals

    local vx_nxt_friction
    local vy_nxt_friction
    local ax_nxt
    local ay_nxt

    if should_recalc == 1:
        #
        # Recalc: calculate v, then if v!=0 calculate ax and ay
        #
        tempvar v_2 = c.vel.x * c.vel.x + c.vel.y * c.vel.y
        let (local v) = sqrt (v_2)

        local ax_dt
        local ay_dt
        if v == 0:
            assert ax_dt = 0
            assert ay_dt = 0
            assert ax_nxt = 0
            assert ay_nxt = 0

            tempvar range_check_ptr = range_check_ptr
        else:
            let (a_mul_vx) = mul_fp (a_friction, -1*c.vel.x)
            let (ax) = div_fp (a_mul_vx, v)
            assert ax_nxt = ax # recalc
            let (axdt) = mul_fp (ax, dt)
            assert ax_dt = axdt # for friction application

            let (a_mul_vy) = mul_fp (a_friction, -1*c.vel.y)
            let (ay) = div_fp (a_mul_vy, v)
            assert ay_nxt = ay # recalc
            let (aydt) = mul_fp (ay, dt)
            assert ay_dt = aydt # for friction application

            tempvar range_check_ptr = range_check_ptr
        end

        #
        # Apply with clipping to 0
        #
        let (local vx_abs) = abs_value (c.vel.x)
        let (ax_dt_abs) = abs_value (ax_dt)
        let (local bool_x_stopped) = is_le (vx_abs, ax_dt_abs)
        let (local vy_abs) = abs_value (c.vel.y)
        let (ay_dt_abs) = abs_value (ay_dt)
        let (local bool_y_stopped) = is_le (vy_abs, ay_dt_abs)

        if bool_x_stopped == 1:
            assert vx_nxt_friction = 0
            # TODO: also zero out ax!
            tempvar range_check_ptr = range_check_ptr
        else:
            assert vx_nxt_friction = c.vel.x + ax_dt
            tempvar range_check_ptr = range_check_ptr
        end

        if bool_y_stopped == 1:
            assert vy_nxt_friction = 0
            # TODO: also zero out ay!
            tempvar range_check_ptr = range_check_ptr
        else:
            assert vy_nxt_friction = c.vel.y + ay_dt
            tempvar range_check_ptr = range_check_ptr
        end

        tempvar range_check_ptr = range_check_ptr
    else:
        #
        # Apply with clipping to 0
        #
        let (local ax_dt) = mul_fp (c.acc.x, dt)
        let (local vx_abs) = abs_value (c.vel.x)
        let (ax_dt_abs) = abs_value(ax_dt)
        let (bool_x_stopped) = is_le (vx_abs, ax_dt_abs)
        if bool_x_stopped == 1:
            assert vx_nxt_friction = 0
            assert ax_nxt = 0

            tempvar range_check_ptr = range_check_ptr
        else:
            assert vx_nxt_friction = c.vel.x + ax_dt
            assert ax_nxt = c.acc.x

            tempvar range_check_ptr = range_check_ptr
        end

        let (local ay_dt) = mul_fp (c.acc.y, dt)
        let (local vy_abs) = abs_value (c.vel.y)
        let (ay_dt_abs) = abs_value (ay_dt)
        let (bool_y_stopped) = is_le (vy_abs, ay_dt_abs)
        if bool_y_stopped == 1:
            assert vy_nxt_friction = 0
            assert ay_nxt = 0

            tempvar range_check_ptr = range_check_ptr
        else:
            assert vy_nxt_friction = c.vel.y + ay_dt
            assert ay_nxt = c.acc.y

            tempvar range_check_ptr = range_check_ptr
        end
    end

    #
    # Pack
    #
    let c_nxt = BallState (
        pos = c.pos,
        vel = Vec2 (vx_nxt_friction, vy_nxt_friction),
        acc = Vec2 (ax_nxt, ay_nxt)
    )

    return (c_nxt)
end

#################################

### Utility functions for fixed-point arithmetic
func mul_fp {range_check_ptr} (
        a : felt,
        b : felt
    ) -> (
        c : felt
    ):
    # signed_div_rem by FP after multiplication
    let (c, _) = signed_div_rem(a * b, FP, RANGE_CHECK_BOUND)
    return (c)
end

func div_fp {range_check_ptr} (
        a : felt,
        b : felt
    ) -> (
        c : felt
    ):
    #
    # multiply by FP before signed_div_rem
    #
    let (c, _) = signed_div_rem(a * FP, b, RANGE_CHECK_BOUND)
    return (c)
end

func distance_2pt {range_check_ptr} (
        pt1 : Vec2,
        pt2 : Vec2
    ) -> (
        distance : felt
    ):

    tempvar distance_2 = (pt2.x-pt1.x) * (pt2.x-pt1.x) + (pt2.y-pt1.y) * (pt2.y-pt1.y)
    let (distance) = sqrt (distance_2)

    return (distance)
end

@view
func test_circle_intersect {range_check_ptr} (
        c1 : Vec2,
        r1 : felt,
        c2 : Vec2,
        r2 : felt
    ) -> (bool_intersect : felt):

    #
    # Check if distance between c1 and c2 <= r1+r2
    #
    let (distance) = distance_2pt (c1, c2)
    let (bool_intersect) = is_le(distance, r1+r2)
    return (bool_intersect)
end
