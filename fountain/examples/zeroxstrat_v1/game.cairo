%lang starknet

from starkware.cairo.common.cairo_builtins import BitwiseBuiltin
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (unsigned_div_rem, assert_le, abs_value)
from starkware.cairo.common.bitwise import (bitwise_or, bitwise_and, bitwise_xor)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address

from contracts.constants import (FP)
from contracts.structs import (Vec2, ObjectState, LevelState)
from examples.zeroxstrat_v1.levels import (pull_level, assert_legal_velocity)
from contracts.scene_forwarder_array import (forward_scene_capped_counting_collision)

#########################

struct SolutionRecord:
    member discovered_by : felt
    member solution_family : felt
    member score : felt
end


@storage_var
func solution_found_count () -> (count : felt):
end


@storage_var
func solution_record_by_id (id : felt) -> (solution_record : SolutionRecord):
end


@view
func view_solution_found_count {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (count : felt):
    let (count) = solution_found_count.read ()
    return (count)
end


@view
func view_solution_record_by_id {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    id : felt) -> (solution_record : SolutionRecord):
    let (solution_record : SolutionRecord) = solution_record_by_id.read (id)
    return (solution_record)
end


#
# Player submits move for specified level to be simulated by the Fountain engine
#
@external
func submit_move_for_level {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        level : felt,
        move : Vec2
    ) -> (
        is_solution : felt,
        is_solution_family_new : felt,
        solution_id : felt,
        solution_family : felt,
        score : felt
    ):
    alloc_locals

    #
    # Check if the move is legal (within velocity constraints)
    #
    assert_legal_velocity (move)


    #
    # Pull level from inventory
    #
    let (level_state : LevelState) = pull_level (level)


    #
    # Assemble initial scene state and parameters
    #
    let arr_obj_len = 4
    let (arr_obj : ObjectState*) = alloc()

    assert arr_obj[0] = ObjectState(
        pos = level_state.score0_ball,
        vel = Vec2(0,0),
        acc = Vec2(0,0)
    )

    assert arr_obj[1] = ObjectState(
        pos = level_state.score1_ball,
        vel = Vec2(0,0),
        acc = Vec2(0,0)
    )

    assert arr_obj[2] = ObjectState(
        pos = level_state.forbid_ball,
        vel = Vec2(0,0),
        acc = Vec2(0,0)
    )

    assert arr_obj[3] = ObjectState(
        pos = level_state.player_ball,
        vel = move,
        acc = Vec2(0,0)
    )

    let cap = 40
    let dt = 150000000000 # 0.15 * FP

    let params_len = 7
    let (params) = alloc()
    assert params[0] = 20 *FP  # radius
    assert params[1] = (20+20)**2 *FP # square of double radius
    assert params[2] = 0       # xmin
    assert params[3] = 250 *FP # xmax
    assert params[4] = 0       # ymin
    assert params[5] = 250 *FP # ymax
    assert params[6] = 40 *FP  # frictional acceleration


    #
    # Run simlulation
    #
    let (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_record_len : felt,
        arr_collision_record : felt*
    ) = forward_scene_capped_counting_collision (
        arr_obj_len,
        arr_obj,
        cap,
        dt,
        params_len,
        params
    )


    # Debug: revert if scene is not at rest after one transaction
    # (if requiring multi-tx -- may need a ticker mechanism to resolve e.g. yagi)


    #
    # Check if is_solution: score non_zero at the end
    #
    let (score) = _calculate_score_from_record {} (
        arr_collision_record_len,
        arr_collision_record
    )

    local is_solution
    if score != 0:
        assert is_solution = 1
    else:
        assert is_solution = 0
    end


    #
    # Obtain family number and check for originality;
    # naively using O(n) storage array traversal to check for value collision
    # TODO: use merkle tree is n is large
    #
    let (this_family) = _serialize_collision_record_to_family (arr_collision_record_len, arr_collision_record)

    let (count) = solution_found_count.read ()
    let (is_solution_family_new) = _recurse_check_for_family_collision (
        target = this_family,
        len = count,
        idx = 0
    )

    #
    # update record if new solution family is found
    #
    if is_solution_family_new * is_solution == 1:
        let (caller_address) = get_caller_address()
        solution_found_count.write (count + 1)
        solution_record_by_id.write (
            count,
            SolutionRecord(
                discovered_by = caller_address,
                solution_family = this_family,
                score = score
            )
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end


    return (
        is_solution,
        is_solution_family_new,
        count,
        this_family,
        score
    )
end


func _recurse_check_for_family_collision {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        target : felt,
        len : felt,
        idx : felt
    ) -> (is_new : felt):

    if idx == len:
        return (1)
    end

    #
    # check for family collision and return if collided
    #
    let (solution_record : SolutionRecord) = solution_record_by_id.read (idx)
    if solution_record.solution_family == target:
        return (0)
    end

    let (discovered) = _recurse_check_for_family_collision (
        target,
        len,
        idx + 1
    )
    return (discovered)
end


func _calculate_score_from_record {range_check_ptr} (
        arr_collision_record_len : felt,
        arr_collision_record : felt*
    ) -> (score : felt):

    let (score) = _recurse_over_collision_record_calculate_score (
        len = arr_collision_record_len,
        arr = arr_collision_record,
        idx = 0,
        score = 0
    )

    return (score)
end


func _recurse_over_collision_record_calculate_score {range_check_ptr} (
        len : felt,
        arr : felt*,
        idx : felt,
        score : felt
    ) -> (
        score_final : felt
    ):
    alloc_locals

    if idx == len:
        return (score)
    end

    # parse arr[idx] to obtain score_nxt
    let (score_incr, is_reset) = _parse_single_collision_record (
        arr[idx]
    )
    local score_nxt
    if is_reset == 1:
        assert score_nxt = 0
    else:
        assert score_nxt = score + score_incr
    end

    let (score_final) = _recurse_over_collision_record_calculate_score (
        len,
        arr,
        idx + 1,
        score_nxt
    )
    return (score_final)
end


func _parse_single_collision_record {range_check_ptr} (
        record : felt
    ) -> (
        score : felt,
        is_reset : felt
    ):

    # if <16: collided with boundary
    # if >16:
    #   if 16 + 0*4 + 3 = 19: collided with score0
    #   if 16 + 1*4 + 3 = 23: collided with score1
    #   if 16 + 2*4 + 3 = 27: collided with forbid
    # TODO: abstract the mapping from score ball type to score value into levels.cairo

    if record == 19:
        return (
            score = 10,
            is_reset = 0
        )
    end

    if record == 23:
        return (
            score = 20,
            is_reset = 0
        )
    end

    if record == 27:
        return (
            score = 0,
            is_reset = 1
        )
    else:
        return (
            score = 0,
            is_reset = 0
        )
    end

end


func _serialize_collision_record_to_family {range_check_ptr} (
        arr_len : felt, arr : felt*
    ) -> (
        family : felt
    ):

    #
    # iterate over the array, shift by BOUND and add next,
    # where BOUND = last(4) * 4 + first(2) * last(4) + idx(3) + carry(1) = 28
    #
    let (family) = _recurse_add_shift_by_28 (
        len = arr_len,
        arr = arr,
        idx = 0,
        sum = 0
    )

    return (family)
end


func _recurse_add_shift_by_28 {} (
        len : felt,
        arr : felt*,
        idx : felt,
        sum : felt
    ) -> (
        sum_final : felt
    ):

    if idx == len:
        return (sum)
    end

    let sum_nxt = sum *28 + arr[idx]

    let (sum_final) = _recurse_add_shift_by_28 (
        len,
        arr,
        idx + 1,
        sum_nxt
    )

    return (sum_final)
end