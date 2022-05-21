%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.fsm_storages import (
    ns_fsm_storages,
    Proposal
)

##############################

#
# Access control
#
func assert_caller_is_dao {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    let (address) = ns_fsm_storages.owner_dao_address_read ()
    assert caller = address

    return ()
end

func assert_in_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (state_query : felt) -> ():

    let (state) = ns_fsm_storages.state_read ()
    assert state = state_query

    return ()
end

##############################

#
# Functions for initialization
#

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        fsm_name : felt
    ):
    #
    # Set name
    #
    ns_fsm_storages.name_write (fsm_name)

    #
    # State initialization
    #
    ns_fsm_storages.state_write ('S_IDLE')

    return()
end

#
# One-time initialization of dao address that owns this voter state machine
#
@external
func init_owner_dao_address_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address : felt) -> ():
    #
    # Make sure address is not set yet
    #
    let (curr_address) = ns_fsm_storages.owner_dao_address_read ()
    assert curr_address = 0

    #
    # Set address
    #
    ns_fsm_storages.owner_dao_address_write (address)

    return ()
end

##############################

#
# Function for transitioning from S_IDLE => S_VOTE
#
@external
func voting_start {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        proposal : Proposal
    ) -> ():
    alloc_locals

    #
    # Only the owner dao can invoke this function
    #
    assert_caller_is_dao ()

    #
    # Check if in idle state
    #
    assert_in_state ('S_IDLE')

    #
    # Save proposal
    #
    ns_fsm_storages.current_proposal_write (proposal)

    #
    # Make state transition
    #
    ns_fsm_storages.state_write ('S_VOTE')

    return ()
end

#
# Function for transitioning from S_VOTE => S_IDLE
#
@external
func voting_end {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    #
    # Only the owner dao can invoke this function
    #
    assert_caller_is_dao ()

    #
    # Check if in vote state
    #
    assert_in_state ('S_VOTE')

    #
    # Check if proposal period has passed since voting started; reset proposal
    #
    let (block_height) = get_block_number ()
    let (proposal) = ns_fsm_storages.current_proposal_read ()
    let block_elapsed = block_height - proposal.start_l2_block_height
    assert_le (proposal.period, block_elapsed)
    ns_fsm_storages.current_proposal_write (Proposal(0,0,0))


    #
    # Read and reset votes
    #
    let (votes_for) = ns_fsm_storages.votes_for_current_proposal_read ()
    let (votes_against) = ns_fsm_storages.votes_against_current_proposal_read ()
    ns_fsm_storages.votes_for_current_proposal_write (0)
    ns_fsm_storages.votes_against_current_proposal_write (0)
    let (pass) = is_le (votes_against + 1, votes_for) # votes_against < votes_for

    #
    # Make state transition
    #
    ns_fsm_storages.state_write ('S_IDLE')

    #
    # Report voting result to IsaacDAO
    #
    let (dao_address) = ns_fsm_storages.owner_dao_address_read ()
    IContractIsaacDAO.fsm_report_voting_result (
        dao_address,
        pass,
        proposal.address
    )

    return ()
end

#
# Function for checking if voting_end can be invoked
#
@view
func can_invoke_voting_end {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):
    alloc_locals

    #
    # Check if in vote state
    #
    let (state) = ns_fsm_storages.state_read ()
    local bool_correct_state
    if state == 'S_VOTE':
        assert bool_correct_state = 1
    else:
        assert bool_correct_state = 0
    end

    #
    # Check if proposal period has passed since voting started
    #
    let (block_height) = get_block_number ()
    let (proposal) = ns_fsm_storages.current_proposal_read ()
    let block_elapsed = block_height - proposal.start_l2_block_height
    let (bool_period_passed) = is_le (proposal.period, block_elapsed)

    #
    # Aggregate flags
    #
    let bool = bool_correct_state * bool_period_passed

    return (bool)
end

@view
func return_current_block_number {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (number : felt):
    let (number) = get_block_number ()
    return (number)
end

#
# Function for casting vote
#
@external
func cast_vote {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        votes : felt, for : felt
    ) -> ():
    alloc_locals

    #
    # Only the owner dao can invoke this function
    #
    assert_caller_is_dao ()

    #
    # Check if in vote state
    #
    assert_in_state ('S_VOTE')

    #
    # Check if proposal period has *not* passed since voting started
    #
    let (block_height) = get_block_number ()
    let (proposal) = ns_fsm_storages.current_proposal_read ()
    let block_elapsed = block_height - proposal.start_l2_block_height
    assert_lt (block_elapsed, proposal.period)

    #
    # Update votes
    #
    if for == 1:
        let (curr_votes_for) = ns_fsm_storages.votes_for_current_proposal_read ()
        ns_fsm_storages.votes_for_current_proposal_write (curr_votes_for + votes)
    else:
        let (curr_votes_against) = ns_fsm_storages.votes_against_current_proposal_read ()
        ns_fsm_storages.votes_against_current_proposal_write (curr_votes_against + votes)
    end

    return ()
end

##############################

#
# Interfacing with `isaac_dao.cairo`
#
@contract_interface
namespace IContractIsaacDAO:
    func fsm_report_voting_result (pass : felt, proposed_address : felt) -> ():
    end
end
