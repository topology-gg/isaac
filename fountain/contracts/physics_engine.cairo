%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (signed_div_rem, unsigned_div_rem, sign, assert_nn, abs_value, assert_not_zero, sqrt)
from starkware.cairo.common.math_cmp import (is_nn, is_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from contracts.structs import (Vec2, ObjectState)
from contracts.constants import (FP, RANGE_CHECK_BOUND)

# @notice Forward the position and velocity of one circle by one step with Euler method,
#         where the circle is bounded by an axis-aligned box
# @dev This function will be amended to handle only state forwarding with Euler method,
#      leaving general collision handling to other functions
# @dev All numerical values are fixed-point values obtained from the original values
#      scaled by FP and rounded to integer; FP is specified in constants.cairo
# @dev ObjectState struct type is used, which is specified in structs.cairo
# @param dt Delta time associated with one Euler step
# @param c State of the circle object before the Euler step;
#        an instance of ObjectState struct
# @param params_len Length of the params array following
# @param params Array containing in order: circle radius, minimum x value of the box space,
#        maximum x value of the box space, minimum y value of the box space,
#        maximum y value of the box space
# @return c_nxt State of the circle object after the Euler step;
#         an ObjectState struct instance
# @return bool_has_collided_with_boundary 1/2/3/4 if the circle object has collided with xmin/xmax/ymin/ymax boundary;
#         0 otherwise
@view
func euler_step_single_circle_aabb_boundary {range_check_ptr} (
        dt : felt,
        c : ObjectState,
        params_len : felt,
        params : felt*
    ) -> (
        c_nxt : ObjectState,
        collided_with_boundary : felt
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
    # Calculate candidate nxt position
    #
    let (x_delta)    = mul_fp (c.vel.x, dt)
    local x_nxt_cand = c.pos.x + x_delta
    let (y_delta)    = mul_fp (c.vel.y, dt)
    local y_nxt_cand = c.pos.y + y_delta

    #
    # Check c <-> x boundary and y boundary;
    # handle bounce to produce next position and candidate velocities
    #
    let (local b_xmax) = is_nn (x_nxt_cand - x_max)
    let (local b_xmin) = is_nn (x_min - x_nxt_cand)
    local x_nxt  = (1-b_xmax-b_xmin) * x_nxt_cand + b_xmax * x_max + b_xmin * x_min
    local vx_nxt_cand = (1-b_xmax-b_xmin) * c.vel.x + b_xmax * (-c.vel.x) + b_xmin * (-c.vel.x)

    let (local b_ymin) = is_nn (y_min - y_nxt_cand)
    let (local b_ymax) = is_nn (y_nxt_cand - y_max)
    local y_nxt  = (1-b_ymin-b_ymax) * y_nxt_cand + b_ymin * y_min + b_ymax * y_max
    local vy_nxt_cand = (1-b_ymin-b_ymax) * c.vel.y + b_ymin * (-c.vel.y) + b_ymax * (-c.vel.y)

    #
    # Determine if object is stopping
    #
    let (ax_dt) = mul_fp (c.acc.x, dt)
    let (ax_dt_abs) = abs_value (ax_dt)
    let (ay_dt) = mul_fp (c.acc.y, dt)
    let (ay_dt_abs) = abs_value (ay_dt)
    let (local vx_nxt_cand_abs) = abs_value (vx_nxt_cand)
    let (local vy_nxt_cand_abs) = abs_value (vy_nxt_cand)
    let (local bool_x_stopped) = is_le (vx_nxt_cand_abs, ax_dt_abs)
    let (local bool_y_stopped) = is_le (vy_nxt_cand_abs, ay_dt_abs)

    #
    # Apply acceleration to candidate velocities;
    # does *not* recalculate acceleration
    #
    local vx_nxt
    local vy_nxt
    if bool_x_stopped == 1:
        assert vx_nxt = 0
        tempvar range_check_ptr = range_check_ptr
    else:
        assert vx_nxt = vx_nxt_cand + ax_dt
        tempvar range_check_ptr = range_check_ptr
    end

    if bool_y_stopped == 1:
        assert vy_nxt = 0
        tempvar range_check_ptr = range_check_ptr
    else:
        assert vy_nxt = vy_nxt_cand + ay_dt
        tempvar range_check_ptr = range_check_ptr
    end

    #
    # Summarizing the bools
    #
    #tempvar bool_sum = b_xmax + b_xmin + b_ymin + b_ymax
    #let (bool_has_collided_with_boundary) = is_not_zero (bool_sum)
    let collided_with_boundary = b_xmin + b_xmax*2 + b_ymin*3 + b_ymax*4
    let c_nxt = ObjectState (
        pos = Vec2 (x_nxt, y_nxt),
        vel = Vec2 (vx_nxt, vy_nxt),
        acc = c.acc
    )

    return (c_nxt, collided_with_boundary)
end


# @notice For two circle objects, given their current positions and next candidate positions,
#         which come from Euler forward function, detect if they would have collided, and
#         handle the collision by snapping them to the point of impact, and set their velocities
#         assuming fully elastic collision; formula provided by:
#         https://en.wikipedia.org/wiki/Elastic_collision
# @dev This function assumes two circle objects share the same radius value
# @dev This function does not handle potentiall tunneling effect yet
# @dev All numerical values are fixed-point values obtained from the original values
#      scaled by FP and rounded to integer; FP is specified in constants.cairo
# @dev ObjectState struct type is used, which is specified in structs.cairo
# @param c1 Current state of the first circle object; an instance of ObjectState struct
# @param c2 Current state of the second circle object; an instance of ObjectState struct
# @param c1_cand Candidate state of the first circle object from Euler forward function;
#        an instance of ObjectState struct
# @param c2_cand Candidate state of the second circle object from Euler forward function;
#        an instance of ObjectState struct
# @param params_len Length of the params aray following
# @param params Array containing in order: circle radius, square of 2*circle radius
# @param c1_nxt State of the first circle object after collision is handled;
#        an instance of ObjectState struct
# @param c2_nxt State of the second circle object after collision is handled;
#        an instance of ObjectState struct
# @param has_collided 1 if two circle objects collided; 0 otherwise
@view
func collision_pair_circles {range_check_ptr} (
        c1 : ObjectState,
        c2 : ObjectState,
        c1_cand : ObjectState,
        c2_cand : ObjectState,
        params_len : felt,
        params : felt*
    ) -> (
        c1_nxt : ObjectState,
        c2_nxt : ObjectState,
        has_collided : felt
    ):
    alloc_locals

    #
    # Unpack parameters
    # params: [<circle radius>, <precomputed square of circle radius*2>]
    #
    assert params_len = 2
    let circle_r = [params]
    let circle_r2_sq = [params + 1]

    #
    # Check whether candidate c1 collides with candidate c2
    #
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
        # Handle c1 <-> c2 collision: back each off to the point of impact
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
    let c1_nxt = ObjectState (
        pos = Vec2 (x1_nxt, y1_nxt),
        vel = Vec2 (vx1_nxt, vy1_nxt),
        acc = c1.acc
    )

    let c2_nxt = ObjectState (
        pos = Vec2 (x2_nxt, y2_nxt),
        vel = Vec2 (vx2_nxt, vy2_nxt),
        acc = c2.acc
    )

    tempvar has_collided = bool_c1_c2_cand_collided

    return (c1_nxt, c2_nxt, has_collided)
end


# @notice Handle acceleration recalculation with kinetic friction
# @dev Take a bool as input args to determine if friction should be recalculated;
#      only if the object has changed direction would acceleration
#      need to be recalculated
# @dev All numerical values are fixed-point values obtained from the original values
#      scaled by FP and rounded to integer; FP is specified in constants.cairo
# @dev ObjectState struct type is used, which is specified in structs.cairo
# @param dt Delta time associated with one Euler step
# @param c State of the circle object before acceleration recalculation;
#        an instance of ObjectState struct
# @param should_recalc 1 if acceleration should be recalculated; 0 otherwise
# @param a_friction Absolute magnitude of friction-based acceleration
# @return c_nxt State of the circle object after acceleration recalculation;
#         an instance of ObjectState struct
@view
func friction_single_circle {range_check_ptr} (
        dt : felt,
        c : ObjectState,
        should_recalc : felt,
        a_friction : felt
    ) -> (
        c_nxt : ObjectState
    ):
    alloc_locals

    local ax_nxt
    local ay_nxt

    if should_recalc == 1:
        #
        # Check if object has stopped
        #
        tempvar v_2 = c.vel.x * c.vel.x + c.vel.y * c.vel.y
        let (local v) = sqrt (v_2)

        if v == 0:
            #
            # Stopped -> zero out acceleration
            #
            assert ax_nxt = 0
            assert ay_nxt = 0

            tempvar range_check_ptr = range_check_ptr
        else:
            #
            # Recalculate acceleration
            #
            let (a_mul_vx) = mul_fp (a_friction, -1*c.vel.x)
            let (ax) = div_fp (a_mul_vx, v)
            assert ax_nxt = ax

            let (a_mul_vy) = mul_fp (a_friction, -1*c.vel.y)
            let (ay) = div_fp (a_mul_vy, v)
            assert ay_nxt = ay

            tempvar range_check_ptr = range_check_ptr
        end
    else:
        #
        # If object has stopped - zero out acceleration; otherwise retain value
        #
        if c.vel.x == 0:
            assert ax_nxt = 0
            tempvar range_check_ptr = range_check_ptr
        else:
            assert ax_nxt = c.acc.x
            tempvar range_check_ptr = range_check_ptr
        end

        if c.vel.y == 0:
            assert ay_nxt = 0
            tempvar range_check_ptr = range_check_ptr
        else:
            assert ay_nxt = c.acc.y
            tempvar range_check_ptr = range_check_ptr
        end

        # #
        # # Check if object would have stopped along x
        # #
        # let (ax_dt) = mul_fp (c.acc.x, dt)
        # let (ax_dt_abs) = abs_value(ax_dt)
        # let (vx_abs) = abs_value (c.vel.x)
        # let (bool_x_stopped) = is_le (vx_abs, ax_dt_abs)

        # if bool_x_stopped == 1:
        #     assert ax_nxt = 0

        #     tempvar range_check_ptr = range_check_ptr
        # else:
        #     assert ax_nxt = c.acc.x

        #     tempvar range_check_ptr = range_check_ptr
        # end

        # #
        # # Check if object would have stopped along y
        # #
        # let (ay_dt) = mul_fp (c.acc.y, dt)
        # let (ay_dt_abs) = abs_value (ay_dt)
        # let (vy_abs) = abs_value (c.vel.y)
        # let (bool_y_stopped) = is_le (vy_abs, ay_dt_abs)
        # if bool_y_stopped == 1:
        #     assert ay_nxt = 0

        #     tempvar range_check_ptr = range_check_ptr
        # else:
        #     assert ay_nxt = c.acc.y

        #     tempvar range_check_ptr = range_check_ptr
        # end
    end

    #
    # Pack
    #
    let c_nxt = ObjectState (
        pos = c.pos,
        vel = c.vel,
        acc = Vec2 (ax_nxt, ay_nxt)
    )

    return (c_nxt)
end


# @notice Circle-circle intersection test
# @param c1 Center of the first circle object; an instance of Vec2 struct
# @param r1 Radius of the first circle object
# @param c2 Center of the second circle object; an instance of Vec2 struct
# @param r2 Radius of the second circle object
# @return bool_intersect 1 if two circles are intersecting; 0 otherwise
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
    tempvar distance_2 = (c2.x-c1.x) * (c2.x-c1.x) + (c2.y-c1.y) * (c2.y-c1.y)
    let (bool_intersect) = is_le(distance_2, (r1+r2)*(r1+r2))
    return (bool_intersect)
end

#
# Utility functions for fixed-point arithmetic
# TODO use an establiahsed fixed-point arithmetic library through submoduling
#
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
