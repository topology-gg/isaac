%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.fsm_storages import (
    ns_fsm_storages,
    Proposal, S_IDLE, S_VOTE
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

func assert_in_idle_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

    let (state) = ns_fsm_storages.state_read ()
    assert state == S_IDLE

    return ()
end

func assert_in_vote_state {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

    let (state) = ns_fsm_storages.state_read ()
    assert state == S_VOTE

    return ()
end

##############################

#
# Functions for initialization
#

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        voter_name : felt
    ):
    #
    # Set name
    #
    ns_fsm_storages.name_write (voter_name)

    #
    # State initialization
    #
    ns_fsm_storages.state_write (S_IDLE)

    return()
end

#
# One-time initialization of dao address that owns this voter state machine
#
@external
func init_owner_dao_address (address : felt) -> ():
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
    assert_in_idle_state ()

    #
    # Save proposal
    #
    ns_fsm_storages.current_proposal_write (proposal)

    return ()
end

#
# Function for transitioning from S_VOTE => S_IDLE
#
@external
func voting_end {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (
        number_of_votes_supporting_proposal : felt
    ):
    alloc_locals

    #
    # Only the owner dao can invoke this function
    #
    assert_caller_is_dao ()

    #
    # Check if in vote state
    #
    assert_in_vote_state ()

    #
    # Check if proposal period has passed since voting started
    #
    let (block_height) = get_block_number ()
    let (proposal) = ns_fsm_storages.current_proposal_read ()
    let block_elapsed = block_height - proposal.start_l2_block_height
    assert_le (proposal.period, block_elapsed)

    #
    # Read and reset votes
    #
    let (votes) = ns_fsm_storages.votes_supporting_current_proposal_read ()
    ns_fsm_storages.votes_supporting_current_proposal_write (0)

    #
    # Return
    #
    let number_of_votes_supporting_proposal = votes
    return (number_of_votes_supporting_proposal)
end

#
# Function for casting vote
#
@external
func cast_vote {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        votes : felt
    ) -> ():

    #
    # Only the owner dao can invoke this function
    #
    assert_caller_is_dao ()

    #
    # Check if in vote state
    #
    assert_in_vote_state ()

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
    let (curr_votes) = ns_fsm_storages.votes_supporting_current_proposal_read ()
    ns_fsm_storages.votes_supporting_current_proposal_write (curr_votes + votes)

    return ()
end

##############################

# #
# # Interfacing with deployed `universe.cairo`
# #
# @contract_interface
# namespace IContractUniverse:
#     func update_civilization_player_addresses (
#         arr_player_adr_len : felt,
#         arr_player_adr : felt*
#     ) -> ():
#     end
# end
