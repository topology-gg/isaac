%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.isaac_dao_storages import (
    ns_isaac_dao_storages,
    Components, Play
)
from contracts.fsm_storages import (
    Proposal
)

##############################

#
# For yagi automation
#
@view
func yagiProbeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):

    let (_, _, bool) = can_dispatch_player_to_universe ()

    return (bool)
end

@external
func yagiExecuteTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    anyone_dispatch_player_to_universe ()

    return ()
end

##########################

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address_subject : felt,
        address_charter : felt,
        address_angel : felt,
        fsm_address_subject : felt,
        fsm_address_charter : felt,
        fsm_address_angel : felt,
    ):

    #
    # Initialize votable addresses
    #
    ns_isaac_dao_storages.votable_addresses_write (Components(
        subject = address_subject,
        charter = address_charter,
        angel = address_angel
    ))

    #
    # Initialize fsm addresses
    #
    ns_isaac_dao_storages.fsm_addresses_write (Components(
        subject = fsm_address_subject,
        charter = fsm_address_charter,
        angel = fsm_address_angel
    ))

    return()
end

##########################

#
# Access control
#
func assert_caller_is_angel {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    let (votable_addresses) = ns_isaac_dao_storages.dao_votable_addresses_read ()
    assert caller = votable_addresses.angel

    return ()
end

func assert_caller_is_subject {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    let (votable_addresses) = ns_isaac_dao_storages.dao_votable_addresses_read ()
    assert caller = votable_addresses.subject

    return ()
end

##########################

#
# Helper function for constructing proposal
#
func construct_proposal {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    proposed_address : felt) ->  (proposal : Proposal):
    alloc_locals

    let (curr_block_height) = get_block_number ()
    let (period) = get_period_from_charter ()
    let proposal = Proposal (
        address = proposed_address,
        period = period,
        start_l2_block_height = curr_block_height
    )

    return (proposal)
end

#
# Angel propose
#
@external
func angel_propose_new_subject {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    proposed_address : felt) ->  ():
    alloc_locals

    #
    # Angel qualification
    #
    assert_caller_is_angel ()

    #
    # Construct proposal
    #
    let (proposal : Proposal) = construct_proposal (proposed_address)

    #
    # Submit proposal to fsm
    #
    let (fsm_addresses) = ns_isaac_dao_storages.fsm_addresses_read ()
    IContractFsm.voting_start (
        fsm_addresses.subject,
        proposal
    )

    return ()
end

@external
func angel_propose_new_charter {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    proposed_address : felt) ->  ():
    alloc_locals

    #
    # Angel qualification
    #
    assert_caller_is_angel ()

    #
    # Construct proposal
    #
    let (proposal : Proposal) = construct_proposal (proposed_address)

    #
    # Submit proposal to fsm
    #
    let (fsm_addresses) = ns_isaac_dao_storages.fsm_addresses_read ()
    IContractFsm.voting_start (
        fsm_addresses.charter,
        proposal
    )

    return ()
end

@external
func angel_propose_new_angel {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    proposed_address : felt) ->  ():
    alloc_locals

    #
    # Angel qualification
    #
    assert_caller_is_angel ()

    #
    # Construct proposal
    #
    let (proposal : Proposal) = construct_proposal (proposed_address)

    #
    # Submit proposal to fsm
    #
    let (fsm_addresses) = ns_isaac_dao_storages.fsm_addresses_read ()
    IContractFsm.voting_start (
        fsm_addresses.angel,
        proposal
    )

    return ()
end

##########################

#
# Player vote
#

## helper function
func player_vote_new_x {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    votes : felt, for : felt, fsm_address : felt) -> ():

    #
    # Qualification
    #
    let (caller) = get_caller_address ()
    let (votes_avail) = ns_isaac_dao_storages.player_votes_available_read (caller)
    assert_lt (0, votes) # 0 < votes
    assert_le (votes, votes_avail) # votes <= votes_avail

    #
    # Spend votes
    #
    ns_isaac_dao_storages.player_votes_available_write (caller, votes_avail - votes)
    IContractFsm.cast_vote (
        fsm_address,
        votes,
        for
    )

end

@external
func player_vote_new_subject {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    votes : felt, for : felt) ->  ():
    alloc_locals

    let (fsm_addresses) = ns_isaac_dao_storages.fsm_addresses_read ()
    player_vote_new_x (votes, for, fsm_addresses.subject)

    return ()
end

@external
func player_vote_new_charter {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    votes : felt, for : felt) ->  ():
    alloc_locals

    let (fsm_addresses) = ns_isaac_dao_storages.fsm_addresses_read ()
    player_vote_new_x (votes, for, fsm_addresses.charter)

    return ()
end

@external
func player_vote_new_angel {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    votes : felt, for : felt) ->  ():
    alloc_locals

    let (fsm_addresses) = ns_isaac_dao_storages.fsm_addresses_read ()
    player_vote_new_x (votes, for, fsm_addresses.angel)

    return ()
end

##########################

#
# FSM contract returns pass/fail; implement change if passed
#
@external
func fsm_report_voting_result {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    pass : felt, proposed_address : felt) -> ():
    alloc_locals

    #
    # Prepare for change depending on fsm address (1:1 mapped to votable address) and pass/fail
    #
    let (caller) = get_caller_address ()
    let (fsm_addresses : Components) = ns_isaac_dao_storages.fsm_addresses_read ()
    let (curr_votable_addresses : Components) = ns_isaac_dao_storages.votable_addresses_read ()
    local new_votable_addresses : Components

    if caller == fsm_addresses.subject:
        if pass == 1:
            assert new_votable_addresses = Components (
                subject = proposed_address,
                charter = curr_votable_addresses.charter,
                angel   = curr_votable_addresses.angel
            )
            let (curr_epoch) = ns_isaac_dao_storages.current_epoch_read ()
            ns_isaac_dao_storages.current_epoch_write (curr_epoch + 1) # subject evolved to its next epoch

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            assert new_votable_addresses = curr_votable_addresses

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end
    end

    if caller == fsm_addresses.charter:
        if pass == 1:
            assert new_votable_addresses = Components (
                subject = curr_votable_addresses.subject,
                charter = proposed_address,
                angel   = curr_votable_addresses.angel
            )
        else:
            assert new_votable_addresses = curr_votable_addresses
        end
    end

    if caller == fsm_addresses.angel:
        if pass == 1:
            assert new_votable_addresses = Components (
                subject = curr_votable_addresses.subject,
                charter = curr_votable_addresses.charter,
                angel   = proposed_address
            )
        else:
            assert new_votable_addresses = curr_votable_addresses
        end
    end

    #
    # Update votable addresses
    #
    ns_isaac_dao_storages.votable_addresses_write (new_votable_addresses)

    #
    # Caller not a component FSM of this DAO
    #
    not_fsm_address:
    with_attr error_message ("Caller is not one of the DAO's component-FSM addresses"):
        assert 1 = 0
    end
    return ()
end

##########################

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
    assert_caller_is_subject ()

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
    let (new_votes) = get_votes_from_charter_given_play_grade (arr_play[idx].grade)
    let (curr_votes) = ns_isaac_dao_storages.player_votes_available_read ()
    ns_isaac_dao_storages.player_votes_available_write (curr_votes + new_votes)

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

##########################

#
# Charter return parameters
#
func get_period_from_charter {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (period : felt):

    let (votable_addresses) = ns_isaac_dao_storages.dao_votable_addresses_read ()
    let charter_address = votable_addresses.charter
    let (period) = IContractCharter.lookup_proposal_period (
        charter_address
    )

    return (period)
end

func get_votes_from_charter_given_play_grade {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    play_grade : felt) -> (votes : felt):

    let (votable_addresses) = ns_isaac_dao_storages.dao_votable_addresses_read ()
    let charter_address = votable_addresses.charter
    let (votes) = IContractCharter.lookup_votes_given_play_grade (
        charter_address,
        play_grade
    )

    return (votes)
end

##########################

#
# Interfacing with `charter.cairo`
#
@contract_interface
namespace IContractCharter:
    func lookup_proposal_duration () -> (duration : felt):
    end

    func lookup_votes_given_play_grade (play_grade : felt) -> (votes : felt):
    end
end

#
# Interfacing with `fsm.cairo`
#
@contract_interface
namespace IContractFsm:
    func voting_start (proposal : Proposal) -> ():
    end

    func cast_vote (votes : felt, for : felt) -> ():
    end
end

