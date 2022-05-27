%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

@storage_var
func queue_head_index () -> (head_idx : felt):
end

@storage_var
func queue_tail_index () -> (tail_idx : felt):
end

@storage_var
func queue_address_to_index (address : felt) -> (idx : felt):
end

@storage_var
func queue_index_to_address (idx : felt) -> (address : felt):
end

@storage_var
func universe_addresses (idx : felt) -> (address : felt):
end

@storage_var
func universe_address_to_index (address : felt) -> (idx : felt):
end

@storage_var
func universe_active (idx : felt) -> (is_active : felt):
end

@storage_var
func dao_address () -> (address : felt):
end

namespace ns_lobby_state_functions:

    #
    # Getters
    #
    @view
    func queue_head_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (head_idx : felt):

        let (head_idx) = queue_head_index.read ()

        return (head_idx)
    end

    @view
    func queue_tail_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (tail_idx : felt):

        let (tail_idx) = queue_tail_index.read ()

        return (tail_idx)
    end

    @view
    func queue_address_to_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> (idx : felt):

        let (idx) = queue_address_to_index.read (address)

        return (idx)
    end

    @view
    func queue_index_to_address_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt) -> (address : felt):

        let (address) = queue_index_to_address.read (idx)

        return (address)
    end

    @view
    func universe_addresses_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt) -> (address : felt):

        let (address) = universe_addresses.read (idx)

        return (address)
    end

    @view
    func universe_address_to_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> (idx : felt):

        let (idx) = universe_address_to_index.read (address)

        return (idx)
    end

    @view
    func universe_active_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt) -> (is_active : felt):

        let (is_active) = universe_active.read (idx)

        return (is_active)
    end

    @view
    func dao_address_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (address : felt):

        let (address) = dao_address.read ()

        return (address)
    end

    #
    # Setters
    #
    func queue_head_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        head_idx : felt) -> ():

        queue_head_index.write (head_idx)

        return ()
    end

    func queue_tail_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        tail_idx : felt) -> ():

        queue_tail_index.write (tail_idx)

        return ()
    end

    func queue_address_to_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, idx : felt) -> ():

        queue_address_to_index.write (address, idx)

        return ()
    end

    func queue_index_to_address_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt, address : felt) -> ():

        queue_index_to_address.write (idx, address)

        return ()
    end

    func universe_addresses_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt, address : felt) -> ():

        universe_addresses.write (idx, address)

        return ()
    end

    func universe_address_to_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, idx : felt) -> ():

        universe_address_to_index.write (address, idx)

        return ()
    end

    func universe_active_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt, is_active : felt) -> ():

        universe_active.write (idx, is_active)

        return ()
    end

    func dao_address_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> ():

        dao_address.write (address)

        return ()
    end

end # end namespace
