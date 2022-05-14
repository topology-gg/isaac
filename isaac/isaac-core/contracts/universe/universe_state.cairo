%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

#
# Import constants and structs
#
from contracts.design.constants import (
    GYOZA, MIN_L2_BLOCK_NUM_BETWEEN_FORWARD,
    ns_macro_init
)
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)

@storage_var
func isaac_address () -> (address : felt):
end

@storage_var
func l2_block_at_genesis () -> (block_height : felt):
end

@storage_var
func civilization_index () -> (civ_idx : felt):
end

@storage_var
func civilization_player_idx_to_address (idx : felt) -> (address : felt):
end

@storage_var
func civilization_player_address_to_bool (address : felt) -> (bool : felt):
end

@storage_var
func l2_block_at_last_forward () -> (block_height : felt):
end

namespace ns_universe_state_functions:

    #
    # Getters
    #
    @view
    func isaac_address_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (address : felt):

        let (address) = isaac_address.read ()

        return (address)
    end

    @view
    func l2_block_at_genesis_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (address : felt):

        let (address) = l2_block_at_genesis.read ()

        return (address)
    end

    @view
    func civilization_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (civ_idx : felt):

        let (civ_idx) = civilization_index.read ()

        return (civ_idx)
    end

    @view
    func civilization_player_idx_to_address_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt) -> (address : felt):

        let (address) = civilization_player_idx_to_address.read (idx)

        return (address)
    end

    @view
    func civilization_player_address_to_bool_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> (bool : felt):

        let (bool) = civilization_player_address_to_bool.read (address)

        return (bool)
    end

    @view
    func l2_block_at_last_forward_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (block_height : felt):

        let (block_height) = l2_block_at_last_forward.read ()

        return (block_height)
    end


    #
    # Setters
    #
    func isaac_address_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> ():

        isaac_address.write (address)

        return ()
    end

    func l2_block_at_genesis_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> ():

        l2_block_at_genesis.write (address)

        return ()
    end

    func civilization_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        civ_idx : felt) -> ():

        civilization_index.write (civ_idx)

        return ()
    end

    func civilization_player_idx_to_address_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt, address : felt) -> ():

        civilization_player_idx_to_address.write (idx, address)

        return ()
    end

    func civilization_player_address_to_bool_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt, bool : felt) -> ():

        civilization_player_address_to_bool.write (address, bool)

        return ()
    end

    func l2_block_at_last_forward_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        block_height : felt) -> ():

        l2_block_at_last_forward.write (block_height)

        return ()
    end


end # end namespace
