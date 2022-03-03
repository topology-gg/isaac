%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (unsigned_div_rem, assert_le, abs_value, split_felt)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_caller_address

from contracts.constants import (FP)
from contracts.structs import (Vec2, ObjectState, LevelState)
from contracts.scene_forwarder_array import (forward_scene_capped_counting_collision)
from examples.zeroxstrat_v1.levels import (pull_level, assert_legal_velocity)
from examples.libs.Str import (Str, str_from_literal, literal_from_number, str_concat)
from examples.libs.html_paragraph import (convert_str_array_to_html_string)
from examples.libs.html_table import (convert_str_table_to_html_string)

#########################

#
# SNS deployed on Starknet testnet
#
const SNS_ADDRESS = 0x02ef8e28b8d7fc96349c76a0607def71c678975dbd60508b9c343458c4758fac

@contract_interface
namespace IContractSNS:
    func sns_lookup (adr : felt) -> (exist : felt, name : felt):
    end
end

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


@view
func view_solution_records_as_html {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (arr_len : felt, arr : felt*):
    alloc_locals

    let (arr_str : Str*) = alloc()

    # 0. deal with edge case first
    let (sol_count) = solution_found_count.read ()
    if sol_count == 0:
        let (str : Str) = str_from_literal ('no solutions in record yet.')
        assert arr_str[0] = str
        let (arr_len, arr) = convert_str_array_to_html_string (1, arr_str)
        return (arr_len, arr)
    end

    # 1. prepare table header
    let (str : Str) = str_from_literal ('solution id')
    assert arr_str[0] = str
    let (str : Str) = str_from_literal ('discovered by')
    assert arr_str[1] = str
    let (str : Str) = str_from_literal ('solution family')
    assert arr_str[2] = str
    let (str : Str) = str_from_literal ('score')
    assert arr_str[3] = str

    # 2. read all solution records into a Str array
    _recurse_read_solution_records_into_str_array (
        len = sol_count,
        idx = 0,
        arr_str = arr_str
    )

    # 3. convert Str array into html string
    let (arr_len, arr) = convert_str_table_to_html_string (
        row_cnt = sol_count+1,
        col_cnt = 4,
        arr_str_len = 4*(sol_count+1),
        arr_str = arr_str
    )

    return (arr_len, arr)
end


func _recurse_read_solution_records_into_str_array {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len : felt,
        idx : felt,
        arr_str : Str*
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    # read solution record at idx
    let (solution_record : SolutionRecord) = solution_record_by_id.read (idx)
    # turn solution record into three Str elements; store to array; index starts at 4 because the first row is taken
    let (literal) = literal_from_number(idx)
    let (str : Str) = str_from_literal(literal)
    assert arr_str [4 + idx*4] = str

    let (exist, name) = IContractSNS.sns_lookup(SNS_ADDRESS, solution_record.discovered_by)
    if exist==1:
        let (str : Str) = str_from_literal (name)
        assert arr_str [4 + idx*4 + 1] = str
    else:
        let (str : Str) = str_from_literal('<adr not registered with SNS>')
        assert arr_str [4 + idx*4 + 1] = str
    end

    let (literal) = literal_from_number(solution_record.solution_family)
    let (str : Str) = str_from_literal(literal)
    assert arr_str [4 + idx*4 + 2] = str

    let (literal) = literal_from_number(solution_record.score)
    let (str : Str) = str_from_literal(literal)
    assert arr_str [4 + idx*4 + 3] = str

    _recurse_read_solution_records_into_str_array (len, idx+1, arr_str)
    return ()
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