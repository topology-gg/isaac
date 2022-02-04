%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (signed_div_rem, unsigned_div_rem, sign, assert_nn, abs_value, assert_not_zero, sqrt)
from starkware.cairo.common.math_cmp import (is_nn, is_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.default_dict import (default_dict_new, default_dict_finalize)
from starkware.cairo.common.dict import (dict_write, dict_read)
from starkware.cairo.common.dict_access import DictAccess

from contracts.core.physics_engine import (euler_step_single_circle_aabb_boundary, collision_pair_circles, friction_single_circle)
from contracts.lib.utility import (is_zero)
from contracts.lib.structs import (Vec2, BallState, GameState, PlayerStats, player_stats_add)
from contracts.lib.constants import (OBJ_COUNT, DT, FP, RANGE_CHECK_BOUND, CIRCLE_R, CIRCLE_R2_SQ, Y_MAX, Y_MIN, X_MAX, X_MIN, A_FRICTION)

@view
func recurse_euler_forward_capped {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        state : GameState,
        first : felt,
        iter : felt,
        cap : felt
    ) -> (
        state_end : GameState,
        p1_stats_end : PlayerStats,
        p2_stats_end : PlayerStats,
        p3_stats_end : PlayerStats
    ):
    alloc_locals

    #
    # return when iteration cap is reached
    #
    if iter == cap:
        return ( state, PlayerStats(0,0,0), PlayerStats(0,0,0), PlayerStats(0,0,0) )
    end

    #
    # forward game state by 1*DT
    #
    let (
        state_nxt : GameState,
        p1_stats : PlayerStats,
        p2_stats : PlayerStats,
        p3_stats : PlayerStats
    ) =  _euler_forward (
        state,
        first
    )

    #
    # tail recursion
    #
    let (
        state_end : GameState,
        p1_stats_rest : PlayerStats,
        p2_stats_rest : PlayerStats,
        p3_stats_rest : PlayerStats
    ) = recurse_euler_forward_capped (
        state = state_nxt,
        first = 0,
        iter = iter+1,
        cap = cap
    )

    let (p1_stats_end) = player_stats_add (p1_stats, p1_stats_rest)
    let (p2_stats_end) = player_stats_add (p2_stats, p2_stats_rest)
    let (p3_stats_end) = player_stats_add (p3_stats, p3_stats_rest)
    return (state_end, p1_stats_end, p2_stats_end, p3_stats_end)
end

func _euler_forward {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        state : GameState,
        first : felt
    ) -> (
        state_nxt : GameState,
        p1_stats : PlayerStats,
        p2_stats : PlayerStats,
        p3_stats : PlayerStats
    ):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    #
    # Creating dictionary from input state
    #
    let (dict) = default_dict_new (default_value = 0)
    dict_write {dict_ptr=dict} (key = 0, new_value = cast(&state.score0_ball, felt) )
    dict_write {dict_ptr=dict} (key = 1, new_value = cast(&state.score1_ball, felt) )
    dict_write {dict_ptr=dict} (key = 2, new_value = cast(&state.forbid_ball, felt) )
    dict_write {dict_ptr=dict} (key = 3, new_value = cast(&state.player1_ball, felt) )
    dict_write {dict_ptr=dict} (key = 4, new_value = cast(&state.player2_ball, felt) )
    dict_write {dict_ptr=dict} (key = 5, new_value = cast(&state.player3_ball, felt) )

    #
    # Creating an identical dictionary from input state
    #
    let (dict_copy) = default_dict_new (default_value = 0)
    dict_write {dict_ptr=dict_copy} (key = 0, new_value = cast(&state.score0_ball, felt) )
    dict_write {dict_ptr=dict_copy} (key = 1, new_value = cast(&state.score1_ball, felt) )
    dict_write {dict_ptr=dict_copy} (key = 2, new_value = cast(&state.forbid_ball, felt) )
    dict_write {dict_ptr=dict_copy} (key = 3, new_value = cast(&state.player1_ball, felt) )
    dict_write {dict_ptr=dict_copy} (key = 4, new_value = cast(&state.player2_ball, felt) )
    dict_write {dict_ptr=dict_copy} (key = 5, new_value = cast(&state.player3_ball, felt) )

    #
    # Euler step
    #
    let (arr_collision_boundary) = alloc()
    let (
        dict_euler : DictAccess*
    ) = _recurse_euler_step_single_circle_aabb_boundary (
        dict_obj = dict,
        arr_collision_boundary = arr_collision_boundary,
        len = OBJ_COUNT,
        idx = 0
    )

    #
    # Handle collision
    #
    let (dict_collision_count_init) = default_dict_new (default_value = 0)
    let (dict_collision_pairwise_init) = default_dict_new (default_value = 0)
    let (
        dict_collision : DictAccess*,
        dict_copy_ : DictAccess*,
        dict_collision_count : DictAccess*,
        dict_collision_pairwise : DictAccess*
    ) = _recurse_collision_handling_outer_loop (
        dict_obj_cand_before = dict_euler,
        dict_obj_ref_before = dict_copy,
        dict_collision_count_before = dict_collision_count_init,
        dict_collision_pairwise_before = dict_collision_pairwise_init,
        last = OBJ_COUNT,
        idx = 0
    )

    #
    # Handle friction
    #
    let (
        dict_obj_friction : DictAccess*,
        dict_collision_count_ : DictAccess*,
    ) = _recurse_handle_friction (
        dict_obj = dict_collision,
        dict_collision_count = dict_collision_count,
        arr_collision_boundary = arr_collision_boundary,
        is_first_euler_step = first,
        len = OBJ_COUNT,
        idx = 0
    )

    #
    # Pack state_nxt from dictionary
    #
    let (s0_ptr) = dict_read {dict_ptr = dict_obj_friction} (key = 0)
    let (s1_ptr) = dict_read {dict_ptr = dict_obj_friction} (key = 1)
    let (fb_ptr) = dict_read {dict_ptr = dict_obj_friction} (key = 2)
    let (p1_ptr) = dict_read {dict_ptr = dict_obj_friction} (key = 3)
    let (p2_ptr) = dict_read {dict_ptr = dict_obj_friction} (key = 4)
    let (p3_ptr) = dict_read {dict_ptr = dict_obj_friction} (key = 5)
    let state_nxt = GameState(
        score0_ball =  [ cast(s0_ptr, BallState*) ],
        score1_ball =  [ cast(s1_ptr, BallState*) ],
        forbid_ball =  [ cast(fb_ptr, BallState*) ],
        player1_ball = [ cast(p1_ptr, BallState*) ],
        player2_ball = [ cast(p2_ptr, BallState*) ],
        player3_ball = [ cast(p3_ptr, BallState*) ]
    )

    #
    # Summarize player stats for this iteration
    #
    let (bool_s0_p1_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 0*OBJ_COUNT+3) # 3
    let (bool_s1_p1_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 1*OBJ_COUNT+3) # 9
    let (bool_fb_p1_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 2*OBJ_COUNT+3) # 15
    let p1_stats : PlayerStats = PlayerStats(
        fb_count = bool_fb_p1_collided,
        s0_count = bool_s0_p1_collided,
        s1_count = bool_s1_p1_collided
    )

    let (bool_s0_p2_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 0*OBJ_COUNT+4) # 4
    let (bool_s1_p2_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 1*OBJ_COUNT+4) # 10
    let (bool_fb_p2_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 2*OBJ_COUNT+4) # 16
    let p2_stats : PlayerStats = PlayerStats(
        fb_count = bool_fb_p2_collided,
        s0_count = bool_s0_p2_collided,
        s1_count = bool_s1_p2_collided
    )

    let (bool_s0_p3_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 0*OBJ_COUNT+5) # 5
    let (bool_s1_p3_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 1*OBJ_COUNT+5) # 11
    let (bool_fb_p3_collided) = dict_read {dict_ptr = dict_collision_pairwise} (key = 2*OBJ_COUNT+5) # 17
    let p3_stats : PlayerStats = PlayerStats(
        fb_count = bool_fb_p3_collided,
        s0_count = bool_s0_p3_collided,
        s1_count = bool_s1_p3_collided
    )

    #
    # Finalize dictionaries
    #
    default_dict_finalize(dict_accesses_start = dict_obj_friction, dict_accesses_end = dict_obj_friction, default_value = 0)
    default_dict_finalize(dict_accesses_start = dict_collision_pairwise, dict_accesses_end = dict_collision_pairwise, default_value = 0)
    default_dict_finalize(dict_accesses_start = dict_collision_count_, dict_accesses_end = dict_collision_count_, default_value = 0)
    default_dict_finalize(dict_accesses_start = dict_copy_, dict_accesses_end = dict_copy_, default_value = 0)

    return (state_nxt, p1_stats, p2_stats, p3_stats)
end

################################

func _recurse_collision_handling_inner_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj_cand_before : DictAccess*,
        dict_obj_ref_before : DictAccess*,
        dict_collision_count_before : DictAccess*,
        dict_collision_pairwise_before : DictAccess*,
        first : felt,
        last : felt,
        idx : felt
    ) -> (
        dict_obj_cand_after : DictAccess*,
        dict_obj_ref_after : DictAccess*,
        dict_collision_count_after : DictAccess*,
        dict_collision_pairwise_after : DictAccess*
    ):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    if idx == last:
        return (
            dict_obj_cand_before,
            dict_obj_ref_before,
            dict_collision_count_before,
            dict_collision_pairwise_before
        )
    end

    #
    # Perform collision handling
    #
    let (obj_ptr_a_cand) = dict_read {dict_ptr = dict_obj_cand_before} (key = first)
    let (obj_ptr_b_cand) = dict_read {dict_ptr = dict_obj_cand_before} (key = idx)
    let (obj_ptr_a) = dict_read {dict_ptr = dict_obj_ref_before} (key = first)
    let (obj_ptr_b) = dict_read {dict_ptr = dict_obj_ref_before} (key = idx)
    let (params) = alloc()
    assert [params] = CIRCLE_R
    assert [params + 1] = CIRCLE_R2_SQ
    let (
        local obj_a_nxt : BallState,
        local obj_b_nxt : BallState,
        bool_has_collided
    ) = collision_pair_circles (
        [ cast(obj_ptr_a, BallState*) ],
        [ cast(obj_ptr_b, BallState*) ],
        [ cast(obj_ptr_a_cand, BallState*) ],
        [ cast(obj_ptr_b_cand, BallState*) ],
        2,
        params
    )

    #
    # Update object dictionary
    #
    dict_write {dict_ptr = dict_obj_cand_before} (key = first, new_value = cast(&obj_a_nxt, felt) )
    dict_write {dict_ptr = dict_obj_cand_before} (key = idx, new_value = cast(&obj_b_nxt, felt) )

    #
    # Update counter dictionary
    #
    let (obj_a_collision_count) = dict_read {dict_ptr = dict_collision_count_before} (key = first)
    dict_write {dict_ptr = dict_collision_count_before} (key = first, new_value = obj_a_collision_count + bool_has_collided)
    let (obj_b_collision_count) = dict_read {dict_ptr = dict_collision_count_before} (key = idx)
    dict_write {dict_ptr = dict_collision_count_before} (key = idx, new_value = obj_b_collision_count + bool_has_collided)

    #
    # Update flag dictionary
    # key encoding: <smaller index> * OBJ_COUNT + <larger index>
    #
    dict_write {dict_ptr = dict_collision_pairwise_before} (key = first*OBJ_COUNT+idx, new_value = bool_has_collided)

    #
    # Tail recursion
    #
    let (
        dict_obj_cand_after : DictAccess*,
        dict_obj_ref_after : DictAccess*,
        dict_collision_count_after : DictAccess*,
        dict_collision_pairwise_after : DictAccess*
    ) = _recurse_collision_handling_inner_loop (
        dict_obj_cand_before,
        dict_obj_ref_before,
        dict_collision_count_before,
        dict_collision_pairwise_before,
        first,
        last,
        idx+1
    )
    return (dict_obj_cand_after, dict_obj_ref_after, dict_collision_count_after, dict_collision_pairwise_after)
end

func _recurse_collision_handling_outer_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj_cand_before : DictAccess*,
        dict_obj_ref_before : DictAccess*,
        dict_collision_count_before : DictAccess*,
        dict_collision_pairwise_before : DictAccess*,
        last : felt,
        idx : felt
    ) -> (
        dict_obj_cand : DictAccess*,
        dict_obj_ref : DictAccess*,
        dict_collision_count : DictAccess*,
        dict_collision_pairwise : DictAccess*
    ):

    if idx == last-1:
        return (
            dict_obj_cand_before,
            dict_obj_ref_before,
            dict_collision_count_before,
            dict_collision_pairwise_before
        )
    end

    #
    # inner loop
    #
    let (
        dict_obj_cand_after : DictAccess*,
        dict_obj_ref_after : DictAccess*,
        dict_collision_count_after : DictAccess*,
        dict_collision_pairwise_after : DictAccess*
    ) = _recurse_collision_handling_inner_loop (
        dict_obj_cand_before,
        dict_obj_ref_before,
        dict_collision_count_before,
        dict_collision_pairwise_before,
        idx,
        last,
        idx+1
    )

    #
    # tail recursion
    #
    let (
        dict_obj_cand : DictAccess*,
        dict_obj_ref : DictAccess*,
        dict_collision_count : DictAccess*,
        dict_collision_pairwise : DictAccess*
    ) = _recurse_collision_handling_outer_loop (
        dict_obj_cand_after,
        dict_obj_ref_after,
        dict_collision_count_after,
        dict_collision_pairwise_after,
        last,
        idx+1
    )

    return (dict_obj_cand, dict_obj_ref, dict_collision_count, dict_collision_pairwise)
end

func _recurse_handle_friction{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj : DictAccess*,
        dict_collision_count : DictAccess*,
        arr_collision_boundary : felt*,
        is_first_euler_step : felt,
        len : felt,
        idx : felt
    ) -> (
        dict_obj_friction : DictAccess*,
        dict_collision_count_ : DictAccess*
    ):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    if idx == len:
        return (
            dict_obj,
            dict_collision_count
        )
    end

    #
    # determine if friction should be recalculated
    #
    let (count) = dict_read {dict_ptr = dict_collision_count} (key = idx)
    let bool = arr_collision_boundary[idx]
    tempvar has_collided = is_first_euler_step + count + bool
    let (should_recalc_friction) = is_not_zero (has_collided)

    #
    # apply friction
    #
    let (obj_ptr) = dict_read {dict_ptr = dict_obj} (key = idx)
    let (
        local obj_after_friction : BallState
    ) = friction_single_circle (
        dt = DT,
        c = [ cast(obj_ptr, BallState*) ],
        should_recalc = should_recalc_friction,
        a_friction = A_FRICTION
    )
    dict_write {dict_ptr = dict_obj} (key = idx, new_value = cast(&obj_after_friction, felt) )

    #
    # tail recursion
    #
    let (
        dict_obj_friction : DictAccess*,
        dict_collision_count_ : DictAccess*
    ) = _recurse_handle_friction (
        dict_obj,
        dict_collision_count,
        arr_collision_boundary,
        is_first_euler_step,
        len,
        idx + 1
    )

    return (
        dict_obj_friction,
        dict_collision_count_
    )
end

func _recurse_euler_step_single_circle_aabb_boundary{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj : DictAccess*,
        arr_collision_boundary : felt*,
        len : felt,
        idx : felt
    ) -> (
        dict_obj_after : DictAccess*
    ):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    if idx == len:
        return (dict_obj)
    end

    #
    # Forward object state by one step by Euler method
    #
    let (params) = alloc()
    assert [params] = CIRCLE_R
    assert [params + 1] = X_MIN
    assert [params + 2] = X_MAX
    assert [params + 3] = Y_MIN
    assert [params + 4] = Y_MAX
    let (ball_state_ptr_felt : felt) = dict_read {dict_ptr=dict_obj} (key = idx)
    let (
        local state_cand : BallState,
        bool_collided_with_boundary
    ) = euler_step_single_circle_aabb_boundary (
        DT,
        [ cast(ball_state_ptr_felt, BallState*) ],
        5,
        params
    )

    #
    # Update dictionaries
    #
    dict_write {dict_ptr=dict_obj} (key = idx, new_value = cast(&state_cand, felt) )
    assert arr_collision_boundary[idx] = bool_collided_with_boundary

    #
    # Tail recursion
    #
    let (
        dict_obj_after
    ) = _recurse_euler_step_single_circle_aabb_boundary (
        dict_obj,
        arr_collision_boundary,
        len,
        idx + 1
    )

    return (dict_obj_after)
end