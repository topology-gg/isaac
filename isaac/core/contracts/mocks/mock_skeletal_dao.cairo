%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.util.structs import (
    Play
)

@storage_var
func subject_address () -> (adr : felt):
end

@storage_var
func player_votes_available (player_adr : felt) -> (votes : felt):
end

@external
func set_subject_address_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    adr : felt) -> ():

    let (curr_adr) = subject_address.read ()
    assert curr_adr = 0
    subject_address.write (adr)

    return ()
end

#
# Subject return player participation info
#
@external
func subject_report_play {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_play_len : felt,
        arr_play : Play*
    ) -> ():
    alloc_locals

    #
    # Subject qualification
    #
    let (caller) = get_caller_address ()
    let (subject_adr) = subject_address.read ()
    assert caller = subject_adr

    #
    # Issue new votes to players reported by subject
    #
    recurse_issue_new_vote_given_play (
        arr_play_len,
        arr_play,
        0
    )

    return ()
end

func recurse_issue_new_vote_given_play {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_play_len : felt,
        arr_play : Play*,
        idx : felt
    ) -> ():
    alloc_locals

    if idx == arr_play_len:
        return ()
    end

    #
    # Issue new votes to player, where number of new votes is derived from play grade by Charter
    #
    let (new_votes) = mock_get_votes_from_charter_given_play_grade (arr_play[idx].grade)
    let (curr_votes) = player_votes_available.read (arr_play[idx].player_address)
    player_votes_available.write (arr_play[idx].player_address, curr_votes + new_votes)

    #
    # Tail recursion
    #
    recurse_issue_new_vote_given_play (
        arr_play_len,
        arr_play,
        idx + 1
    )
    return ()
end

func mock_get_votes_from_charter_given_play_grade {} (play_grade : felt) -> (votes : felt):
    alloc_locals

    if play_grade == 0:
        return (7)
    end

    if play_grade == 1:
        return (25)
    end

    local pg = play_grade
    with_attr error_message ("play_grade value (pg) unrecognized"):
        assert 1 = 0
    end
    return (0)
end

@view
func view_player_votes_available {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    player_adr : felt) -> (votes : felt):

    let (votes) = player_votes_available.read (player_adr)

    return (votes)
end