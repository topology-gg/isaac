%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (signed_div_rem, unsigned_div_rem, sign, assert_nn, abs_value, assert_not_zero, sqrt)
from starkware.cairo.common.math_cmp import (is_nn, is_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.registers import get_fp_and_pc
from starkware.cairo.common.default_dict import (default_dict_new, default_dict_finalize)
from starkware.cairo.common.dict import (dict_write, dict_read)
from starkware.cairo.common.dict_access import DictAccess
from starkware.cairo.common.memcpy import memcpy

from contracts.physics_engine import (euler_step_single_circle_aabb_boundary, collision_pair_circles, friction_single_circle)
from contracts.structs import (Vec2, ObjectState)
from contracts.constants import (FP, RANGE_CHECK_BOUND)


# @notice Forward a scene of circle objects by cap number of steps, where each step
#         involves forwarding each object with Euler method, handling all possible
#         collisions, and recalculate acceleration based on friction; the function keeps
#         count of collision occurences between all pairs of objects
# @dev The `cap` input arg should be decided considering the 250k/1M step limit for
#      StarkNet testnet/mainnet as well as associated cost
# @dev All numerical values are fixed-point values obtained from the original values
#      scaled by FP and rounded to integer; FP is specified in constants.cairo
# @dev ObjectState struct type is used, which is specified in structs.cairo
# @param arr_obj_len Length of the object array following
# @param arr_obj Pointer to the object array containing all objects of the scene
#        before the forwarding; each object is an instance of ObjectState struct
# @param cap Number of Euler steps to be forwarded by one call to this function
# @param dt Delta time associated with one Euler step
# @param params_len Length of the params array following
# @param params Array containing in order: circle radius, square of 2*circle radius,
#        minimum x value of the box space, maximum x value of the box space,
#        minimum y value of the box space, maximum y value of the box space,
#        Absolute magnitude of friction-based acceleration
# @param arr_obj_final_len Length of the object array following
# @param arr_obj_final Pointer to the object array containing all objects of the scene
#        after the forwarding; each object is an instance of ObjectState struct
# @param arr_collision_record_len Length of the felt array following
# @param arr_collision_record Pointer to the felt array containing the collision records, where each record is a felt value:
#        if record < arr_obj_len * 4 => an collision occurred between an object and a wall, where
#          record = object index * 4 + wall index; wall index = {xmin:0, xmax:1, ymin:0, ymax:1};
#        else => an collision occurred between two objects, where
#          record = smaller object index * total object count + larger object index
@view
func forward_scene_capped_counting_collision {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_obj_len : felt,
        arr_obj : ObjectState*,
        cap : felt,
        dt : felt,
        params_len : felt,
        params : felt*
    ) -> (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*
    ):
    alloc_locals

    #
    # Initialize an array for recording all collision occurrences (circle-to-circle and circle-to-boundary)
    #
    let (arr_collision_record) = alloc()

    #
    # Recursively forward scene by cap iterations
    #
    let (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_record_final_len : felt,
        arr_collision_record_final : felt*
    ) = _recurse_euler_forward_scene_capped (
        arr_obj_len = arr_obj_len,
        arr_obj = arr_obj,
        arr_collision_record_len = 0,
        arr_collision_record = arr_collision_record,
        first = 1,
        iter = 0,
        cap = cap,
        dt = dt,
        params_len = params_len,
        params = params
    )

    return (
        arr_obj_final_len,
        arr_obj_final,
        arr_collision_record_final_len,
        arr_collision_record_final
    )
end


#
# Internal / utility functions
#

func _recurse_euler_forward_scene_capped {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_obj_len : felt,
        arr_obj : ObjectState*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*,
        first : felt,
        iter : felt,
        cap : felt,
        dt : felt,
        params_len : felt,
        params : felt*
    ) -> (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_record_final_len : felt,
        arr_collision_record_final : felt*
    ):
    alloc_locals

    #
    # Return when iteration cap is reached
    #
    if iter == cap:
        return (
            arr_obj_len,
            arr_obj,
            arr_collision_record_len,
            arr_collision_record
        )
    end

    #
    # Forward scene by one dt
    #
    let (
        arr_obj_nxt_len : felt,
        arr_obj_nxt : ObjectState*,
        arr_collision_record_one_step_len : felt,
        arr_collision_record_one_step : felt*
    ) =  _euler_forward_scene_one_step (
        arr_obj_len,
        arr_obj,
        first,
        dt,
        params_len,
        params
    )

    #
    # Emit event on new positions
    #
    position.emit (iter, arr_obj_nxt_len, arr_obj_nxt)

    #
    # Update collision record array
    #
    let (
        arr_collision_record_nxt_len : felt,
        arr_collision_record_nxt : felt*
    ) = array_concat (
        arr_collision_record_len,
        arr_collision_record,
        arr_collision_record_one_step_len,
        arr_collision_record_one_step
    )


    #
    # Tail recursion
    #
    let (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_record_final_len : felt,
        arr_collision_record_final : felt*
    ) = _recurse_euler_forward_scene_capped (
        arr_obj_len = arr_obj_nxt_len,
        arr_obj = arr_obj_nxt,
        arr_collision_record_len = arr_collision_record_nxt_len,
        arr_collision_record = arr_collision_record_nxt,
        first = 0,
        iter = iter+1,
        cap = cap,
        dt = dt,
        params_len = params_len,
        params = params
    )

    return (arr_obj_final_len, arr_obj_final, arr_collision_record_final_len, arr_collision_record_final)
end


func _euler_forward_scene_one_step {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_obj_len : felt,
        arr_obj : ObjectState*,
        first : felt,
        dt : felt,
        params_len : felt,
        params : felt*
    ) -> (
        arr_obj_nxt_len : felt,
        arr_obj_nxt : ObjectState*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*
    ):
    alloc_locals

    #
    # Create dictionary from input state
    #
    let (dict_init) = default_dict_new (default_value = 0)
    let (dict) = _recurse_populate_dict_from_obj_array (arr_obj_len, arr_obj, dict_init, 0)

    #
    # Create an identical dictionary from input state
    #
    let (dict_copy_init) = default_dict_new (default_value = 0)
    let (dict_copy) = _recurse_populate_dict_from_obj_array (arr_obj_len, arr_obj, dict_copy_init, 0)

    #
    # Create an empty array for recording collision occurences
    #
    let (arr_collision_record) = alloc()

    #
    # Euler step
    #
    let params_euler_len = 5
    let (params_euler) = alloc()
    assert [params_euler    ] = [params]
    assert [params_euler + 1] = [params + 2]
    assert [params_euler + 2] = [params + 3]
    assert [params_euler + 3] = [params + 4]
    assert [params_euler + 4] = [params + 5]
    let (arr_collision_boundary) = alloc()
    let (
        dict_euler : DictAccess*,
        arr_collision_record_len_euler_step : felt
    ) = _recurse_euler_step_single_circle_aabb_boundary (
        dict_obj = dict,
        arr_collision_boundary = arr_collision_boundary,
        len = arr_obj_len,
        idx = 0,
        dt = dt,
        params_euler_len = params_euler_len,
        params_euler = params_euler,
        arr_collision_record_len = 0,
        arr_collision_record = arr_collision_record
    )

    #
    # Handle collision
    #
    let params_collision_len = 2
    let (params_collision) = alloc()
    assert [params_collision]     = [params]
    assert [params_collision + 1] = [params + 1]
    let (dict_collision_count_init) = default_dict_new (default_value = 0)
    let (
        dict_collision : DictAccess*,
        dict_copy_ : DictAccess*,
        dict_collision_count : DictAccess*,
        arr_collision_record_len_collision_step : felt
    ) = _recurse_collision_handling_outer_loop (
        dict_obj_cand_before = dict_euler,
        dict_obj_ref_before = dict_copy,
        dict_collision_count_before = dict_collision_count_init,
        arr_collision_record_len = arr_collision_record_len_euler_step,
        arr_collision_record = arr_collision_record,
        last = arr_obj_len,
        idx = 0,
        params_collision_len = params_collision_len,
        params_collision = params_collision
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
        len = arr_obj_len,
        idx = 0,
        dt = dt,
        a_friction = [params + 6]
    )

    #
    # Pack output array from dictionary
    #
    let arr_obj_nxt_len = arr_obj_len
    let (arr_obj_nxt : ObjectState*) = alloc()
    let (dict_obj_friction_) = _recurse_populate_obj_array_from_dict (
        arr_obj_nxt_len,
        arr_obj_nxt,
        dict_obj_friction,
        0
    )

    #
    # Finalize internal dictionaries
    #
    default_dict_finalize(dict_accesses_start = dict_obj_friction_, dict_accesses_end = dict_obj_friction_, default_value = 0)
    default_dict_finalize(dict_accesses_start = dict_collision_count_, dict_accesses_end = dict_collision_count_, default_value = 0)
    default_dict_finalize(dict_accesses_start = dict_copy_, dict_accesses_end = dict_copy_, default_value = 0)

    let arr_collision_record_len = arr_collision_record_len_collision_step
    return (arr_obj_nxt_len, arr_obj_nxt, arr_collision_record_len, arr_collision_record)
end


func _recurse_populate_array_from_pairwise_dict_outer {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        obj_count : felt,
        arr_len : felt,
        arr : felt*,
        dict_pairwise : DictAccess*,
        idx_outer : felt,
        idx_flatten : felt
    ) -> (
        dict_pairwise_outer : DictAccess*,
        idx_flatten_final : felt
    ):

    if idx_outer == obj_count-1:
        return (dict_pairwise, idx_flatten)
    end

    #
    # Inner loop
    #
    let (
        dict_pairwise_inner : DictAccess*,
        idx_flatten_inner : felt
    ) = _recurse_populate_array_from_pairwise_dict_inner (
        obj_count = obj_count,
        arr_len = arr_len,
        arr = arr,
        dict_pairwise = dict_pairwise,
        idx_outer = idx_outer,
        idx_inner = idx_outer + 1,
        idx_flatten = idx_flatten
    )

    #
    # Tail recursion
    #
    let (
        dict_pairwise_outer : DictAccess*,
        idx_flatten_final : felt
    ) = _recurse_populate_array_from_pairwise_dict_outer (
        obj_count = obj_count,
        arr_len = arr_len,
        arr = arr,
        dict_pairwise = dict_pairwise_inner,
        idx_outer = idx_outer + 1,
        idx_flatten = idx_flatten_inner
    )
    return (dict_pairwise_outer, idx_flatten_final)
end


func _recurse_populate_array_from_pairwise_dict_inner {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        obj_count : felt,
        arr_len : felt,
        arr : felt*,
        dict_pairwise : DictAccess*,
        idx_outer : felt,
        idx_inner : felt,
        idx_flatten : felt
    ) -> (
        dict_pairwise_inner : DictAccess*,
        idx_flatten_inner : felt
    ):

    if idx_inner == obj_count:
        return (dict_pairwise, idx_flatten)
    end

    #
    # Read from dictionary, write to array
    #
    let (count) = dict_read {dict_ptr = dict_pairwise} (key = idx_outer*obj_count + idx_inner)
    assert arr[idx_flatten] = count
    # reading_pairwise_collision_count.emit (first=idx_outer, second=idx_inner, index=idx_outer*obj_count + idx_inner, count=count)

    #
    # Tail recursion
    #
    let (
        dict_pairwise_inner,
        idx_flatten_inner
    ) = _recurse_populate_array_from_pairwise_dict_inner (
        obj_count = obj_count,
        arr_len = arr_len,
        arr = arr,
        dict_pairwise = dict_pairwise,
        idx_outer = idx_outer,
        idx_inner = idx_inner + 1,
        idx_flatten = idx_flatten + 1
    )
    return (dict_pairwise_inner, idx_flatten_inner)
end


func _recurse_populate_obj_array_from_dict {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        len : felt,
        arr : ObjectState*,
        dict : DictAccess*,
        idx : felt
    ) -> (
        dict_ : DictAccess*
    ):

    if idx == len:
        return (dict)
    end

    let (obj_ptr_felt) = dict_read {dict_ptr = dict} (key = idx)
    assert arr[idx] = [ cast(obj_ptr_felt, ObjectState*) ]

    let (dict_) = _recurse_populate_obj_array_from_dict (len, arr, dict, idx+1)
    return (dict_)
end


func _recurse_populate_dict_from_obj_array {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        len : felt,
        arr : ObjectState*,
        dict : DictAccess*,
        idx : felt
    ) -> (
        dict_ : DictAccess*
    ):

    let (__fp__, _) = get_fp_and_pc()
    if idx == len:
        return (dict)
    end

    dict_write {dict_ptr=dict} (key = idx, new_value = cast(&arr[idx], felt))

    let (dict_) = _recurse_populate_dict_from_obj_array (len, arr, dict, idx+1)
    return (dict_)
end


func _recurse_add_zip_pairwise_dictionaries_inner {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        obj_count : felt,
        dict_sum : DictAccess*,
        dict_inc : DictAccess*,
        idx_outer : felt,
        idx_inner : felt
    ) -> (
        dict_sum_inner : DictAccess*,
        dict_inc_inner : DictAccess*
    ):

    if idx_inner == obj_count:
        return (
            dict_sum,
            dict_inc
        )
    end

    let (sum) = dict_read {dict_ptr = dict_sum} (key = idx_outer * obj_count + idx_inner)
    let (inc) = dict_read {dict_ptr = dict_inc} (key = idx_outer * obj_count + idx_inner)
    dict_write {dict_ptr = dict_sum} (key = idx_outer * obj_count + idx_inner, new_value = sum + inc)

    let (
        dict_sum_inner,
        dict_inc_inner
    ) = _recurse_add_zip_pairwise_dictionaries_inner (
        obj_count,
        dict_sum,
        dict_inc,
        idx_outer,
        idx_inner + 1
    )
    return (dict_sum_inner, dict_inc_inner)
end


func _recurse_add_zip_pairwise_dictionaries_outer {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        obj_count : felt,
        dict_sum : DictAccess*,
        dict_inc : DictAccess*,
        idx_outer : felt
    ) -> (
        dict_sum_outer : DictAccess*,
        dict_inc_outer : DictAccess*
    ):

    if idx_outer == obj_count-1:
        return (
            dict_sum,
            dict_inc
        )
    end

    let (
        dict_sum_inner,
        dict_inc_inner
    ) = _recurse_add_zip_pairwise_dictionaries_inner (
        obj_count,
        dict_sum,
        dict_inc,
        idx_outer,
        idx_outer + 1
    )

    let (
        dict_sum_outer : DictAccess*,
        dict_inc_outer : DictAccess*
    ) = _recurse_add_zip_pairwise_dictionaries_outer (
        obj_count,
        dict_sum_inner,
        dict_inc_inner,
        idx_outer + 1
    )

    return (
        dict_sum_outer,
        dict_inc_outer
    )
end


func _recurse_collision_handling_inner_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj_cand_before : DictAccess*,
        dict_obj_ref_before : DictAccess*,
        dict_collision_count_before : DictAccess*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*,
        first : felt,
        last : felt,
        idx : felt,
        params_collision_len : felt,
        params_collision : felt*
    ) -> (
        dict_obj_cand_after : DictAccess*,
        dict_obj_ref_after : DictAccess*,
        dict_collision_count_after : DictAccess*,
        arr_collision_record_len_collision_step_inner : felt
    ):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    if idx == last:
        return (
            dict_obj_cand_before,
            dict_obj_ref_before,
            dict_collision_count_before,
            arr_collision_record_len
        )
    end

    #
    # Perform collision handling
    #
    let (obj_ptr_a_cand) = dict_read {dict_ptr = dict_obj_cand_before} (key = first)
    let (obj_ptr_b_cand) = dict_read {dict_ptr = dict_obj_cand_before} (key = idx)
    let (obj_ptr_a) = dict_read {dict_ptr = dict_obj_ref_before} (key = first)
    let (obj_ptr_b) = dict_read {dict_ptr = dict_obj_ref_before} (key = idx)
    let (
        local obj_a_nxt : ObjectState,
        local obj_b_nxt : ObjectState,
        bool_has_collided
    ) = collision_pair_circles (
        [ cast(obj_ptr_a, ObjectState*) ],
        [ cast(obj_ptr_b, ObjectState*) ],
        [ cast(obj_ptr_a_cand, ObjectState*) ],
        [ cast(obj_ptr_b_cand, ObjectState*) ],
        params_collision_len,
        params_collision
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
    # Update collision record array
    #
    local arr_collision_record_len_nxt
    if bool_has_collided == 0:
        assert arr_collision_record_len_nxt = arr_collision_record_len
    else:
        assert arr_collision_record_len_nxt = arr_collision_record_len + 1
        assert arr_collision_record [arr_collision_record_len] = last * 4 + first * last + idx
    end

    #
    # Tail recursion
    #
    let (
        dict_obj_cand_after : DictAccess*,
        dict_obj_ref_after : DictAccess*,
        dict_collision_count_after : DictAccess*,
        arr_collision_record_len_collision_step_inner : felt,
    ) = _recurse_collision_handling_inner_loop (
        dict_obj_cand_before,
        dict_obj_ref_before,
        dict_collision_count_before,
        arr_collision_record_len_nxt,
        arr_collision_record,
        first,
        last,
        idx+1,
        params_collision_len,
        params_collision
    )
    return (dict_obj_cand_after, dict_obj_ref_after, dict_collision_count_after, arr_collision_record_len_collision_step_inner)
end


func _recurse_collision_handling_outer_loop{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj_cand_before : DictAccess*,
        dict_obj_ref_before : DictAccess*,
        dict_collision_count_before : DictAccess*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*,
        last : felt,
        idx : felt,
        params_collision_len : felt,
        params_collision : felt*
    ) -> (
        dict_obj_cand : DictAccess*,
        dict_obj_ref : DictAccess*,
        dict_collision_count : DictAccess*,
        arr_collision_record_len_collision_step_outer : felt
    ):

    if idx == last-1:
        return (
            dict_obj_cand_before,
            dict_obj_ref_before,
            dict_collision_count_before,
            arr_collision_record_len
        )
    end

    #
    # inner loop
    #
    let (
        dict_obj_cand_after : DictAccess*,
        dict_obj_ref_after : DictAccess*,
        dict_collision_count_after : DictAccess*,
        arr_collision_record_len_collision_step_inner
    ) = _recurse_collision_handling_inner_loop (
        dict_obj_cand_before,
        dict_obj_ref_before,
        dict_collision_count_before,
        arr_collision_record_len,
        arr_collision_record,
        idx,
        last,
        idx+1,
        params_collision_len,
        params_collision
    )

    #
    # tail recursion
    #
    let (
        dict_obj_cand : DictAccess*,
        dict_obj_ref : DictAccess*,
        dict_collision_count : DictAccess*,
        arr_collision_record_len_collision_step_outer
    ) = _recurse_collision_handling_outer_loop (
        dict_obj_cand_after,
        dict_obj_ref_after,
        dict_collision_count_after,
        arr_collision_record_len_collision_step_inner,
        arr_collision_record,
        last,
        idx+1,
        params_collision_len,
        params_collision
    )

    return (dict_obj_cand, dict_obj_ref, dict_collision_count, arr_collision_record_len_collision_step_outer)
end


func _recurse_handle_friction{
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        dict_obj : DictAccess*,
        dict_collision_count : DictAccess*,
        arr_collision_boundary : felt*,
        is_first_euler_step : felt,
        len : felt,
        idx : felt,
        dt : felt,
        a_friction
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
        local obj_after_friction : ObjectState
    ) = friction_single_circle (
        dt = dt,
        c = [ cast(obj_ptr, ObjectState*) ],
        should_recalc = should_recalc_friction,
        a_friction = a_friction
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
        idx + 1,
        dt,
        a_friction
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
        idx : felt,
        dt : felt,
        params_euler_len : felt,
        params_euler : felt*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*
    ) -> (
        dict_obj_after : DictAccess*,
        arr_collision_record_len_euler : felt
    ):
    alloc_locals
    let (__fp__, _) = get_fp_and_pc()

    if idx == len:
        return (
            dict_obj,
            arr_collision_record_len
        )
    end

    #
    # Forward object state by one step by Euler method
    #
    let (ball_state_ptr_felt : felt) = dict_read {dict_ptr=dict_obj} (key = idx)
    let (
        local state_cand : ObjectState,
        collided_with_boundary
    ) = euler_step_single_circle_aabb_boundary (
        dt,
        [ cast(ball_state_ptr_felt, ObjectState*) ],
        params_euler_len,
        params_euler
    )

    #
    # Update dictionaries and array of records
    #
    dict_write {dict_ptr=dict_obj} (key = idx, new_value = cast(&state_cand, felt) )
    local arr_collision_record_nxt_len
    if collided_with_boundary == 0:
        assert arr_collision_boundary[idx] = 0
        assert arr_collision_record_nxt_len = arr_collision_record_len
    else:
        assert arr_collision_boundary[idx] = 1
        assert arr_collision_record_nxt_len = arr_collision_record_len + 1
        assert arr_collision_record [arr_collision_record_len] = idx * 4 + collided_with_boundary
    end


    #
    # Tail recursion
    #
    let (
        dict_obj_after,
        arr_collision_record_len_euler
    ) = _recurse_euler_step_single_circle_aabb_boundary (
        dict_obj,
        arr_collision_boundary,
        len,
        idx + 1,
        dt,
        params_euler_len,
        params_euler,
        arr_collision_record_nxt_len,
        arr_collision_record
    )

    return (dict_obj_after, arr_collision_record_len_euler)
end


#
# Events for debugging purposes
#
@event
func position (
        iter : felt,
        arr_obj_len : felt,
        arr_obj : ObjectState*
    ):
end


func is_zero {range_check_ptr} (value) -> (res):
    # invert the result of is_not_zero()
    let (temp) = is_not_zero(value)
    if temp == 0:
        return (res=1)
    end

    return (res=0)
end


func array_concat {range_check_ptr} (
        arr1_len : felt,
        arr1 : felt*,
        arr2_len : felt,
        arr2 : felt*
    ) -> (
        res_len : felt,
        res : felt*
    ):
    alloc_locals

    let (local res : felt*) = alloc()
    memcpy(res, arr1, arr1_len)
    memcpy(res + arr1_len, arr2, arr2_len)

    return (arr1_len + arr2_len, res)
end

# End of contract