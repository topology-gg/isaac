%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import call_contract
from starkware.starknet.common.syscalls import get_caller_address

from contracts.design.constants import (GYOZA)

# ** router **
# external function restricting GYOZA to change server address
# executeTask() and probeTask() that use call_contract() to call the server's respective functions

const EXECUTE_TASK_SELECTOR = 1292293504451833265282220032973491109404444021620461033892479619388894734438

@contract_interface
namespace IContractIsaacServer:
    func yagiProbeTask () -> (bool : felt):
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

    # this function may eventually accept input to run executeTask()

    let (server_address) = isaac_server_address.read ()
    let (empty_array: felt*) = alloc()

    call_contract(
        contract_address = server_address,
        function_selector = EXECUTE_TASK_SELECTOR,
        calldata_size = 0,
        calldata = empty_array
    )

    return ()
end
