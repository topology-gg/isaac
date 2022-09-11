%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_block_number, get_caller_address

@storage_var
func queue_head_index() -> (head_idx: felt) {
}

@storage_var
func queue_tail_index() -> (tail_idx: felt) {
}

@storage_var
func queue_address_to_index(address: felt) -> (idx: felt) {
}

@storage_var
func queue_index_to_address(idx: felt) -> (address: felt) {
}

@storage_var
func universe_addresses(idx: felt) -> (address: felt) {
}

@storage_var
func universe_address_to_index(address: felt) -> (idx: felt) {
}

@storage_var
func universe_active(idx: felt) -> (is_active: felt) {
}

@storage_var
func dao_address() -> (address: felt) {
}

@storage_var
func event_counter() -> (val: felt) {
}

@storage_var
func init_invitations_made() -> (bool: felt) {
}

namespace ns_lobby_state_functions {
    //
    // Getters
    //
    @view
    func queue_head_index_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (head_idx: felt) {
        let (head_idx) = queue_head_index.read();

        return (head_idx,);
    }

    @view
    func queue_tail_index_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (tail_idx: felt) {
        let (tail_idx) = queue_tail_index.read();

        return (tail_idx,);
    }

    @view
    func queue_address_to_index_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(address: felt) -> (idx: felt) {
        let (idx) = queue_address_to_index.read(address);

        return (idx,);
    }

    @view
    func queue_index_to_address_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(idx: felt) -> (address: felt) {
        let (address) = queue_index_to_address.read(idx);

        return (address,);
    }

    @view
    func universe_addresses_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        idx: felt
    ) -> (address: felt) {
        let (address) = universe_addresses.read(idx);

        return (address,);
    }

    @view
    func universe_address_to_index_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(address: felt) -> (idx: felt) {
        let (idx) = universe_address_to_index.read(address);

        return (idx,);
    }

    @view
    func universe_active_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        idx: felt
    ) -> (is_active: felt) {
        let (is_active) = universe_active.read(idx);

        return (is_active,);
    }

    @view
    func dao_address_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        address: felt
    ) {
        let (address) = dao_address.read();

        return (address,);
    }

    @view
    func event_counter_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        val: felt
    ) {
        let (val) = event_counter.read();

        return (val,);
    }

    @view
    func init_invitations_made_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }() -> (bool: felt) {
        let (bool) = init_invitations_made.read();

        return (bool,);
    }

    //
    // Setters
    //
    func queue_head_index_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        head_idx: felt
    ) -> () {
        queue_head_index.write(head_idx);

        return ();
    }

    func queue_tail_index_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        tail_idx: felt
    ) -> () {
        queue_tail_index.write(tail_idx);

        return ();
    }

    func queue_address_to_index_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(address: felt, idx: felt) -> () {
        queue_address_to_index.write(address, idx);

        return ();
    }

    func queue_index_to_address_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(idx: felt, address: felt) -> () {
        queue_index_to_address.write(idx, address);

        return ();
    }

    func universe_addresses_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        idx: felt, address: felt
    ) -> () {
        universe_addresses.write(idx, address);

        return ();
    }

    func universe_address_to_index_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(address: felt, idx: felt) -> () {
        universe_address_to_index.write(address, idx);

        return ();
    }

    func universe_active_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        idx: felt, is_active: felt
    ) -> () {
        universe_active.write(idx, is_active);

        return ();
    }

    func dao_address_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        address: felt
    ) -> () {
        dao_address.write(address);

        return ();
    }

    func event_counter_reset{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}() -> (
        ) {
        event_counter.write(0);

        return ();
    }
    func event_counter_increment{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> () {
        let (val) = event_counter.read();
        event_counter.write(val + 1);

        return ();
    }

    func init_invitations_made_set{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> () {
        init_invitations_made.write(1);

        return ();
    }
}  // end namespace
