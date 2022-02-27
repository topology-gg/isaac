%lang starknet

from contracts.structs import (Vec2, ObjectState)
from contracts.physics_engine import (
    euler_step_single_circle_aabb_boundary,
    collision_pair_circles,
    friction_single_circle,
    test_circle_intersect
)

@view
func mock_euler_step_single_circle_aabb_boundary {range_check_ptr} (
        dt : felt,
        c : ObjectState,
        params_len : felt,
        params : felt*
    ) -> (
        c_nxt : ObjectState,
        collided_with_boundary : felt
    ):

    let (
        c_nxt : ObjectState,
        collided_with_boundary : felt
    ) = euler_step_single_circle_aabb_boundary (
        dt,
        c,
        params_len,
        params
    )

    return (c_nxt, collided_with_boundary)
end


@view
func mock_collision_pair_circles {range_check_ptr} (
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

    let (
        c1_nxt : ObjectState,
        c2_nxt : ObjectState,
        has_collided : felt
    ) = collision_pair_circles (
        c1,
        c2,
        c1_cand,
        c2_cand,
        params_len,
        params
    )

    return (c1_nxt, c2_nxt, has_collided)
end


@view
func mock_friction_single_circle {range_check_ptr} (
        dt : felt,
        c : ObjectState,
        should_recalc : felt,
        a_friction : felt
    ) -> (
        c_nxt : ObjectState
    ):

    let (
        c_nxt : ObjectState
    ) = friction_single_circle (
        dt,
        c,
        should_recalc,
        a_friction
    )

    return (c_nxt)
end

@view
func mock_test_circle_intersect {range_check_ptr} (
        c1 : Vec2,
        r1 : felt,
        c2 : Vec2,
        r2 : felt
    ) -> (bool_intersect : felt):

    let (bool_intersect : felt) = test_circle_intersect (
        c1,
        r1,
        c2,
        r2
    )

    return (bool_intersect)
end
