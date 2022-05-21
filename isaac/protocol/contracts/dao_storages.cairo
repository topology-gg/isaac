%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc


struct Components:
    member subject : felt
    member charter : felt
    member angel : felt
end

struct Play:
    member player_address : felt
    member grade : felt
end

@storage_var
func player_votes_available (address : felt) -> (votes : felt):
end

@storage_var
func current_epoch () -> (epoch : felt):
end

@storage_var
func votable_addresses () -> (addresses : Components):
end

@storage_var
func fsm_addresses () -> (addresses : Components):
end

namespace ns_dao_storages:

    #
    # Getters
    #

    @view
    func player_votes_available_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> (votes : felt):

        let (votes) = player_votes_available.read (address)

        return (votes)
    end

    @view
    func current_epoch_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (epoch : felt):

        let (epoch) = current_epoch.read ()

        return (epoch)
    end

    @view
    func votable_addresses_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (addresses : Components):

        let (addresses : Components) = votable_addresses.read ()

        return (addresses)
    end

    @view
    func fsm_addresses_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (addresses : Components):

        let (addresses : Components) = fsm_addresses.read ()

        return (addresses)
    end

    #
    # Setters
    #

    func player_votes_available_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, votes : felt) -> ():

        player_votes_available.write (address, votes)

        return ()
    end

    func current_epoch_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        epoch : felt) -> ():

        current_epoch.write (epoch)

        return ()
    end

    func votable_addresses_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        addresses : Components) -> ():

        votable_addresses.write (addresses)

        return ()
    end

    func fsm_addresses_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        addresses : Components) -> ():

        fsm_addresses.write (addresses)

        return ()
    end

end # end namespace
