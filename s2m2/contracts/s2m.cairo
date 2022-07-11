%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_le, is_nn_le, is_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_caller_address)
from starkware.cairo.common.default_dict import (
    default_dict_new, default_dict_finalize)
from starkware.cairo.common.dict import (
    dict_write, dict_read, dict_update)
from starkware.cairo.common.dict_access import DictAccess

from contracts.inventory import (
    Circle, BLACK, WHITE, PUZZLE_DIM, _get_puzzle
)

##############################
#
# storages
#

@storage_var
func puzzle_id () -> (id : felt):
end


@storage_var
func s2m_status () -> (status : felt):
end

##############################

# @event
# func new_puzzle (
#     arr_cell_len : felt,
#     arr_cell : felt*
# )

@event
func success (
        solver : felt,
        puzzle_id : felt
    ):
end

# @event
# func ended ()

# constructor() -> emit new_puzzle
# solve() -> _check()
#   -- if success -> emit success; emit new_puzzle
#   -- if fail -> emit fail

# checking for:
# - path enclosed (pairwise contiguity from start to end and between end-start)
# - no revisit
# - black condition met at all black circles
# - white condition met at all white circles
# - all circles visited

##############################

#
# Event emission for Apibara
#
# TODO

##############################

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

    #
    # initialize puzzle_id and s2m_status
    #
    puzzle_id.write (0)
    s2m_status.write (1)

    #
    # Emit `new_puzzle` event
    #

    return()
end

##############################

#
# Path.type takes value {0,1,2,3,4,5}
# 0: horizontal
# 1: vertical
# 2: vertical turn horizontal left
# 3: vertical turn horizontal right
# 4: horizontal turn vertical up
# 5: horizontal turn vertical down
#
struct Path:
    member type : felt
end

#
# Solver calls solve() to submit the `arr_cell_indices` array,
# where each element is a cell index indicating the cell is visited by the path
#
@external
func solve {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_cell_indices_len : felt,
        arr_cell_indices : felt*
    ) -> ():
    alloc_locals

    #
    # if not active => revert
    #
    let (curr_s2m_tatus) = s2m_status.read ()
    with_attr error_message ("this s2m is no longer active"):
        assert curr_s2m_tatus = 1
    end

    #
    # if caller has solved a puzzle => revert
    #
    let (solver) = get_caller_address ()
    # TODO

    #
    # get current puzzle and build dictionary
    #
    let (curr_puzzle_id) = puzzle_id.read ()
    let (arr_circles_len, arr_circles) = _get_puzzle (curr_puzzle_id)
    let (puzzle_dict_ptr : DictAccess*) = _build_puzzle_dictionary (
        arr_circles_len,
        arr_circles
    )

    #
    # produce a corresponding arr_paths
    #
    let (arr_paths : Path*) = alloc ()
    let (arr_cell_index_visited_at_idx : felt*) = alloc ()
    let (circle_count) = _produce_arr_paths_and_perform_checks (
        idx = 0,
        arr_cell_indices_len = arr_cell_indices_len,
        arr_cell_indices = arr_cell_indices,
        arr_paths = arr_paths,
        arr_cell_index_visited_at_idx = arr_cell_index_visited_at_idx,
        puzzle_dict_ptr = puzzle_dict_ptr,
        circle_count = 0
    )
    with_attr error_message ("not all circles are visited by the solution path"):
        assert circle_count = arr_circles_len
    end

    #
    # check both white circle condition and black circle condition
    #
    _check_black_white_condition (
        idx = 0,
        arr_cell_indices_len = arr_cell_indices_len,
        arr_cell_indices = arr_cell_indices,
        arr_paths = arr_paths,
        puzzle_dict_ptr = puzzle_dict_ptr
    )

    #
    # success:
    # -- emit `success` event;
    # -- check puzzle_id, if reached puzzle amount
    #    => switch off s2m active, emit `ended` event;
    #       else increment puzzle_id, emit `new_puzzle` event
    #
    success.emit (
        solver = solver,
        puzzle_id = curr_puzzle_id
    )
    return ()
end


func _check_black_white_condition {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        arr_cell_indices_len : felt,
        arr_cell_indices : felt*,
        arr_paths : Path*,
        puzzle_dict_ptr : DictAccess*
    ) -> ():
    alloc_locals

    if idx == arr_cell_indices_len:
        return ()
    end

    #
    # get cell indices of self and neighbors
    #
    let curr_cell_index = arr_cell_indices [idx]
    local prev_idx
    local next_idx
    if idx == 0:
        assert prev_idx = arr_cell_indices_len - 1
        assert next_idx = idx + 1
    else:
        if idx == arr_cell_indices_len - 1:
            assert prev_idx = idx - 1
            assert next_idx = 0
        else:
            assert prev_idx = idx - 1
            assert next_idx = idx + 1
        end
    end
    let prev_cell_index = arr_cell_indices [prev_idx]
    let next_cell_index = arr_cell_indices [next_idx]

    #
    # get path of self and neighbors, and get flags of their corner-ness
    #
    let curr_path = arr_paths [idx]
    let prev_path = arr_paths [prev_idx]
    let next_path = arr_paths [next_idx]

    let (is_curr_path_corner) = _is_path_corner (curr_path)
    let (is_prev_path_corner) = _is_path_corner (prev_path)
    let (is_next_path_corner) = _is_path_corner (next_path)
    let (is_curr_path_straight) = is_zero (is_curr_path_corner) # inversion

    #
    # get cell types of self and neighbors
    #
    let (curr_cell_type) = dict_read {dict_ptr = puzzle_dict_ptr} (curr_cell_index)
    let (prev_cell_type) = dict_read {dict_ptr = puzzle_dict_ptr} (prev_cell_index)
    let (next_cell_type) = dict_read {dict_ptr = puzzle_dict_ptr} (next_cell_index)

    #
    # check black circle condition
    # "every square containing a black circle must be a corner not connected directly to another corner"
    #
    if curr_cell_type == BLACK:
        with_attr error_message ("black circle must be a corner"):
            assert is_curr_path_corner = 1
        end

        with_attr error_message ("black circle must not be connected directly to another corner"):
            assert is_prev_path_corner = 0
            assert is_next_path_corner = 0
        end
    end

    #
    # check white circle condition
    # "every square containing a white circle must be a straight which is connected to at least one corner"
    #
    if curr_cell_type == WHITE:
        with_attr error_message ("white circle must be a straight"):
            assert is_curr_path_straight = 1
        end

        let sum_neighbor_cornerness = is_prev_path_corner + is_next_path_corner
        with_attr error_message ("white circle must be connected to at least one corner"):
            assert_not_zero (sum_neighbor_cornerness)
        end
    end

    _check_black_white_condition (
        idx + 1,
        arr_cell_indices_len,
        arr_cell_indices,
        arr_paths,
        puzzle_dict_ptr
    )
    return ()
end


func _build_puzzle_dictionary {range_check_ptr} (
        arr_circles_len : felt,
        arr_circles : Circle*
    ) -> (
        dict_ptr : DictAccess*
    ):
    alloc_locals

    #
    # init and populate dictionary
    #
    let (dict_init) = default_dict_new (default_value = 0)
    let (dict) = _populate_puzzle_dictionary (
        0,
        arr_circles_len,
        arr_circles,
        dict_init
    )

    # finalize() from the empty start pointer and the *updated* end pointer
    default_dict_finalize(
        dict_accesses_start = dict,
        dict_accesses_end = dict,
        default_value = 0
    )

    return (dict)
end


func _populate_puzzle_dictionary {range_check_ptr} (
        idx : felt,
        arr_circles_len : felt,
        arr_circles : Circle*,
        dict_ptr : DictAccess*
    ) -> (
        dict_ptr_final : DictAccess*
    ):

    if idx == arr_circles_len:
        return (dict_ptr)
    end

    #
    # write entry
    #
    dict_write {dict_ptr=dict_ptr} (
        key = arr_circles[idx].cell_index,
        new_value = arr_circles[idx].type
    )

    #
    # tail recursion
    #
    let (dict_ptr_final) = _populate_puzzle_dictionary (
        idx + 1,
        arr_circles_len,
        arr_circles,
        dict_ptr
    )
    return (dict_ptr_final)
end


func _produce_arr_paths_and_perform_checks {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        arr_cell_indices_len : felt,
        arr_cell_indices : felt*,
        arr_paths : Path*,
        arr_cell_index_visited_at_idx : felt*,
        puzzle_dict_ptr : DictAccess*,
        circle_count : felt
    ) -> (circle_count_final : felt):
    alloc_locals

    #
    # check for:
    # 1. path contiguity & path closed
    # 2. cell revisits
    # 3. count circle visits
    #

    local curr_cell_index = arr_cell_indices [idx]
    local prev_cell_index
    local next_cell_index

    #
    # check for valid cell index
    #
    let (bool_valid) = _is_valid_cell_index (curr_cell_index)

    #
    # check for revisit by marking it with current `idx`;
    # if revisited then the assertion will fail because the trace cell would have been populated
    #
    with_attr error_message ("the solution path revisits the same cell at cell index: {curr_cell_index}"):
        assert arr_cell_index_visited_at_idx [curr_cell_index] = idx
    end

    #
    # compute prev_cell_index and next_cell_index
    #
    if idx == 0:
        assert prev_cell_index = arr_cell_indices [arr_cell_indices_len - 1]
        assert next_cell_index = arr_cell_indices [idx + 1]
    else:
        if idx == arr_cell_indices_len - 1:
            assert prev_cell_index = arr_cell_indices [idx - 1]
            assert next_cell_index = arr_cell_indices [0]
        else:
            assert prev_cell_index = arr_cell_indices [idx - 1]
            assert next_cell_index = arr_cell_indices [idx + 1]
        end
    end

    #
    # check for path contiguity between the last cell and first cell
    #
    let (bool_contiguous) = _is_cell_indices_contiguous (curr_cell_index, next_cell_index)
    with_attr error_message ("the solution path is not closed"):
        assert bool_contiguous = 1
    end

    #
    # compute path type and populate arr_paths
    #
    let (path_type) = _compute_path_type (
        prev_cell_index,
        curr_cell_index,
        next_cell_index
    )
    assert arr_paths [idx] = Path (type = path_type)

    #
    # see if current cell has a circle
    #
    let (type) = dict_read {dict_ptr = puzzle_dict_ptr} (curr_cell_index)
    let (bool_has_circle) = is_not_zero (type)

    #
    # return if reached last cell of the solution
    #
    if idx == arr_cell_indices_len - 1:
        return (circle_count + bool_has_circle)
    end

    #
    # tail recursion
    #
    let (circle_count_final) = _produce_arr_paths_and_perform_checks (
        idx + 1,
        arr_cell_indices_len,
        arr_cell_indices,
        arr_paths,
        arr_cell_index_visited_at_idx,
        puzzle_dict_ptr,
        circle_count + bool_has_circle
    )
    return (circle_count_final)

end

##############################

#
# utility function
#

func _is_valid_cell_index {range_check_ptr} (
        cell_index : felt
    ) -> (bool_valid):

    let (bool_valid) = is_nn_le (cell_index, PUZZLE_DIM * PUZZLE_DIM - 1)

    return (bool_valid)
end


func _is_cell_indices_contiguous {range_check_ptr} (
        cell_index_0 : felt,
        cell_index_1 : felt
    ) -> (bool_contiguous):
    alloc_locals

    # if neighbor from left or right => delta is -+ 1
    # if neighbor from top or bottom => delta is -+ PUZZLE_DIM

    let dist = cell_index_1 - cell_index_0
    if dist == 1:
        return (1)
    end
    if dist == -1:
        return (1)
    end
    if dist == PUZZLE_DIM:
        return (1)
    end
    if dist == -1 * PUZZLE_DIM:
        return (1)
    end

    return (0)
end


func _compute_path_type {range_check_ptr} (
        prev_cell_index : felt,
        curr_cell_index : felt,
        next_cell_index : felt
    ) -> (path_type : felt):
    alloc_locals

    let (bool_prev_is_left)  = is_zero (curr_cell_index - prev_cell_index - 1)
    let (bool_prev_is_right) = is_zero (prev_cell_index - curr_cell_index - 1)
    let (bool_prev_is_down)  = is_zero (curr_cell_index - prev_cell_index - PUZZLE_DIM)
    let (bool_prev_is_up)    = is_zero (prev_cell_index - curr_cell_index - PUZZLE_DIM)

    let (bool_next_is_left)  = is_zero (curr_cell_index - next_cell_index - 1)
    let (bool_next_is_right) = is_zero (next_cell_index - curr_cell_index - 1)
    let (bool_next_is_down)  = is_zero (curr_cell_index - next_cell_index - PUZZLE_DIM)
    let (bool_next_is_up)    = is_zero (next_cell_index - curr_cell_index - PUZZLE_DIM)

    if bool_prev_is_left * bool_next_is_right == 1:
        return (0)
    end
    if bool_prev_is_left * bool_next_is_up == 1:
        return (4)
    end
    if bool_prev_is_left * bool_next_is_down == 1:
        return (5)
    end

    if bool_prev_is_right * bool_next_is_left == 1:
        return (0)
    end
    if bool_prev_is_right * bool_next_is_up == 1:
        return (4)
    end
    if bool_prev_is_right * bool_next_is_down == 1:
        return (5)
    end

    if bool_prev_is_up * bool_next_is_left == 1:
        return (2)
    end
    if bool_prev_is_up * bool_next_is_right == 1:
        return (3)
    end
    if bool_prev_is_up * bool_next_is_down == 1:
        return (1)
    end

    if bool_prev_is_down * bool_next_is_left == 1:
        return (2)
    end
    if bool_prev_is_down * bool_next_is_right == 1:
        return (3)
    end
    if bool_prev_is_down * bool_next_is_up == 1:
        return (1)
    end

    with_attr error_message ("the solution path is not closed"):
        assert 1 = 0
    end
    return (0)

end


func is_zero {range_check_ptr} (x) -> (res):
    let (bool_is_not_zero) = is_not_zero (x)
    if bool_is_not_zero == 1:
        return (0)
    end
    return (1)
end

func _is_path_corner {range_check_ptr} (
    path : Path) -> (bool):

    # Path.type takes value {0,1,2,3,4,5}

    if path.type == 0:
        return (0)
    end

    if path.type == 1:
        return (0)
    end

    return (1)
end