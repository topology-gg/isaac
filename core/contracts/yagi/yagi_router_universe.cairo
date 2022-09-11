%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import get_caller_address

from contracts.design.access import assert_correct_admin_key

// ** router **
// external function restricting GYOZA to change universe address
// executeTask() and probeTask() that use call_contract() to call the universe's respective functions

@contract_interface
namespace IContractUniverse {
    func probe_can_forward_universe() -> (bool: felt) {
    }

    func anyone_forward_universe() -> () {
    }
}

@storage_var
func isaac_universe_address() -> (addr: felt) {
}

@view
func view_isaac_universe_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    ) -> (curr_address: felt) {
    let (curr_address) = isaac_universe_address.read();

    return (curr_address,);
}

@external
func change_isaac_universe_address{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
    admin_key: felt, new_address: felt
) -> () {
    //
    // Check admin
    //
    assert_correct_admin_key(admin_key);

    isaac_universe_address.write(new_address);

    return ();
}

@view
func probeTask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (bool: felt) {
    let (universe_address) = isaac_universe_address.read();

    let (bool) = IContractUniverse.probe_can_forward_universe(universe_address);

    return (bool,);
}

@external
func executeTask{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> () {
    let (universe_address) = isaac_universe_address.read();

    IContractUniverse.anyone_forward_universe(universe_address);

    return ();
}
