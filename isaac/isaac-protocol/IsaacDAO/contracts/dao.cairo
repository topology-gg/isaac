%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_lt
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.dao_storages import (
    ns_dao_storages,
    VotableAddresses
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
        address_map_play_to_share : felt,
        address_map_share_to_vote : felt,
        address_charter : felt,
        address_angel : felt
    ):

    #
    # Initialize votable addresses
    #
    ns_dao_storages.dao_votable_addresses_write (VotableAddresses(
        address_map_play_to_share,
        address_map_share_to_vote,
        address_charter,
        address_angel
    ))

    return()
end

##########################

#
# Role qualification
#

func assert_caller_is_player {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    #
    # Player qualification: check caller has >0 shares in the current epoch
    #
    let (caller) = get_caller_address ()
    let (curr_epoch) = ns_dao_storages.current_epoch_read ()
    let (player_share) = ns_dao_storages.player_shares_read (caller, curr_epoch)
    assert_lt (0, player_share)

    return ()
end

func assert_caller_is_angel {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    let (votable_addresses) = ns_dao_storages.dao_votable_addresses_read ()
    let curr_angel_address = votable_addresses.angel
    assert caller = curr_angel_address

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
func angel_propose_address_for_map_play_to_share {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
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
    let (fsm_addresses) = ns_dao_storages.fsm_addresses_read ()
    let fsm_address = fsm_addresses.map_play_to_share
    IContractFsm.voting_start (
        fsm_address,
        proposal
    )

    return ()
end

@external
func angel_propose_address_for_map_share_to_vote {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
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
    let (fsm_addresses) = ns_dao_storages.fsm_addresses_read ()
    let fsm_address = fsm_addresses.map_share_to_vote
    IContractFsm.voting_start (
        fsm_address,
        proposal
    )

    return ()
end

@external
func angel_propose_address_for_subject {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
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
    let (fsm_addresses) = ns_dao_storages.fsm_addresses_read ()
    let fsm_address = fsm_addresses.subject
    IContractFsm.voting_start (
        fsm_address,
        proposal
    )

    return ()
end

@external
func angel_propose_address_for_charter {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
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
    let (fsm_addresses) = ns_dao_storages.fsm_addresses_read ()
    let fsm_address = fsm_addresses.charter
    IContractFsm.voting_start (
        fsm_address,
        proposal
    )

    return ()
end

#
# Player propose
#
@external
func player_propose_address_for_angel {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    proposed_address : felt) ->  ():
    alloc_locals

    #
    # Player qualification
    #
    assert_caller_is_player ()

    #
    # Construct proposal
    #
    let (proposal : Proposal) = construct_proposal (proposed_address)

    #
    # Submit proposal to fsm
    #
    let (fsm_addresses) = ns_dao_storages.fsm_addresses_read ()
    let fsm_address = fsm_addresses.angel
    IContractFsm.voting_start (
        fsm_address,
        proposal
    )

    return ()
end

##########################

#
# Player vote
#


##########################

#
# Voter contract returns votes;
# determine voting passes / fails, and update votable address accordingly
#

##########################

#
# Subject return player participation info
#

##########################

#
# Charter return parameters
#
func get_period_from_charter {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (period : felt):

    let (votable_addresses) = ns_dao_storages.dao_votable_addresses_read ()
    let charter_address = votable_addresses.charter
    let (period) = IContractCharter.lookup_proposal_period (
        charter_address
    )

    return (period)
end

##########################

#
# Interfacing with `charter.cairo`
#
@contract_interface
namespace IContractCharter:
    func lookup_proposal_duration () -> (duration : felt):
    end
end

#
# Interfacing with `fsm.cairo`
#
@contract_interface
namespace IContractFsm:
    func voting_start (proposal : Proposal) -> ():
    end
end

