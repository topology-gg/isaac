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
func player_voices_available (address : felt) -> (voices : felt):
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
    func player_voices_available_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> (voices : felt):

        let (voices) = player_voices_available.read (address)

        return (voices)
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

    func player_voices_available_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, voices : felt) -> ():

        player_voices_available.write (address, voices)

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
