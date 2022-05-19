%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc


struct Proposal:
    member address : felt
    member period : felt
    member start_l2_block_height : felt
end

@storage_vars
func name () -> (literal : felt):
end

@storage_vars
func state () -> (s : felt):
end

@storage_vars
func current_proposal () -> (proposal : Proposal):
end

@storage_vars
func owner_dao_address () -> (address : felt):
end

@storage_vars
func votes_for_current_proposal () -> (votes : felt):
end

@storage_vars
func votes_against_current_proposal () -> (votes : felt):
end

namespace ns_fsm_storages:

    #
    # Getters
    #

    @view
    func name_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (literal : felt):

        let (literal) = name.read ()

        return (literal)
    end

    @view
    func state_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (s : felt):

        let (s) = state.read ()

        return (s)
    end

    @view
    func current_proposal_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (proposal : Proposal):

        let (proposal : Proposal) = current_proposal.read ()

        return (proposal)
    end

    @view
    func owner_dao_address_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (address : felt):

        let (address) = ownder_dao_address.read ()

        return (address)
    end

    @view
    func votes_for_current_proposal_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (votes : felt):

        let (votes) = votes_for_current_proposal.read ()

        return (votes)
    end

    @view
    func votes_against_current_proposal_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (votes : felt):

        let (votes) = votes_against_current_proposal.read ()

        return (votes)
    end

    #
    # Setters
    #

    func name_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        literal : felt) -> ():

        name.write (literal)

        return ()
    end

    func state_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        s : felt) -> ():

        state.write (s)

        return ()
    end

    func current_proposal_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        proposal : Proposal) -> ():

        current_proposal.write (proposal)

        return ()
    end

    func owner_dao_address_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> ():

        ownder_dao_address.write (address)

        return ()
    end

    func votes_for_current_proposal_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        votes : felt) -> ():

        votes_for_current_proposal.write (votes)

        return ()
    end

    func votes_against_current_proposal_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        votes : felt) -> ():

        votes_against_current_proposal.write (votes)

        return ()
    end

end # end namespace
