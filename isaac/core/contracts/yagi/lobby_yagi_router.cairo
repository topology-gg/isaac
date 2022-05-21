%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.design.constants import (GYOZA)

# ** router **
# external function restricting GYOZA to change server address
# executeTask() and probeTask() that use call_contract() to call the server's respective functions

@contract_interface
namespace IContractIsaacServer:
    func yagiProbeTask () -> (bool : felt):
    end

    func yagiExecuteTask () -> ():
    end
end

@storage_var
func isaac_server_address () -> (addr: felt):
end

@view
func view_isaac_server_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (curr_address : felt):

    let (curr_address) = isaac_server_address.read ()

    return (curr_address)
end

@external
func change_isaac_server_address {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (new_address : felt) -> ():

    # GYOZA is the benevolent dictator until Isaac stabilizes
    let (caller) = get_caller_address ()
    assert caller = GYOZA

    isaac_server_address.write (new_address)

    return ()
end

@view
func probeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (bool : felt):

    let (server_address) = isaac_server_address.read ()

    let (bool) = IContractIsaacServer.yagiProbeTask (server_address)

    return (bool)
end

@external
func executeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

    let (server_address) = isaac_server_address.read ()

    IContractIsaacServer.yagiExecuteTask (server_address)

    return ()
end
