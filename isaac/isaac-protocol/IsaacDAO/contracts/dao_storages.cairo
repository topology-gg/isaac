%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

struct VotableAddresses:
    member map_play_to_share : felt
    member map_share_to_vote : felt
    member subject : felt
    member charter : felt
    member angel : felt
end

@storage_vars
func player_shares (address : felt, epoch : felt) -> (amount : felt):
end

@storage_vars
func current_epoch () -> (epoch : felt):
end

@storage_vars
func dao_votable_addresses () -> (votable_addresses : VotableAddresses):
end

@storage_vars
func fsm_addresses () -> (votable_addresses : VotableAddresses):
end

namespace ns_dao_storages:

    #
    # Getters
    #

    @view
    func player_shares_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, epoch : felt) -> (amount : felt):

        let (amount) = player_shares.read (address, epoch)

        return (amount)
    end

    @view
    func current_epoch_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (epoch : felt):

        let (epoch) = current_epoch.read ()

        return (epoch)
    end

    #
    # Setters
    #

    func player_shares_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, epoch : felt, amount : felt) -> ():

        player_shares.write (address, epoch, amount)

        return ()
    end

    func current_epoch_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        epoch : felt) -> ():

        current_epoch.write (epoch)

        return ()
    end

end # end namespace
