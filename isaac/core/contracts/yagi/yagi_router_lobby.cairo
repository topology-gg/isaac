%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.design.access import (assert_correct_admin_key)

# ** router **
# external function restricting GYOZA to change lobby address
# executeTask() and probeTask() that use call_contract() to call the lobby's respective functions

@contract_interface
namespace IContractLobby:
    func probe_can_dispatch_to_universe () -> (bool : felt):
    end

    func anyone_dispatch_player_to_universe () -> ():
    end
end

@storage_var
func isaac_lobby_address () -> (addr: felt):
end

@view
func view_isaac_lobby_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (curr_address : felt):

    let (curr_address) = isaac_lobby_address.read ()

    return (curr_address)
end

@external
func change_isaac_lobby_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    admin_key : felt,
    new_address : felt) -> ():

    #
    # Check admin
    #
    assert_correct_admin_key (admin_key)

    isaac_lobby_address.write (new_address)

    return ()
end

@view
func probeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (bool : felt):

    let (lobby_address) = isaac_lobby_address.read ()

    let (bool) = IContractLobby.probe_can_dispatch_to_universe (lobby_address)

    return (bool)
end

@external
func executeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

    let (lobby_address) = isaac_lobby_address.read ()

    IContractLobby.anyone_dispatch_player_to_universe (lobby_address)

    return ()
end
