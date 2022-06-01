%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.design.access import (assert_correct_admin_key)

# ** router **
# external function restricting whitelisted addresses to change dao address
# executeTask() and probeTask() that use call_contract() to call the dao's respective functions

@contract_interface
namespace IContractDAO:
    func probe_can_end_vote () -> (bool : felt):
    end

    func anyone_execute_end_vote () -> ():
    end
end

@storage_var
func isaac_dao_address () -> (addr: felt):
end

@view
func view_isaac_dao_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (curr_address : felt):

    let (curr_address) = isaac_dao_address.read ()

    return (curr_address)
end

@external
func change_isaac_dao_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    admin_key : felt,
    new_address : felt) -> ():

    #
    # Check admin
    #
    assert_correct_admin_key (admin_key)

    isaac_dao_address.write (new_address)

    return ()
end

@view
func probeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (bool : felt):

    let (dao_address) = isaac_dao_address.read ()

    let (bool) = IContractDAO.probe_can_end_vote (dao_address)

    return (bool)
end

@external
func executeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

    let (dao_address) = isaac_dao_address.read ()

    IContractDAO.anyone_execute_end_vote (dao_address)

    return ()
end
