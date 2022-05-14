%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    CIV_SIZE, UNIVERSE_COUNT
)
from contracts.lobby.lobby_state import (
    ns_lobby_state_functions
)


##############################

#
# Interfacing with deployed `universe.cairo`
#
@contract_interface
namespace IContractUniverse:
    func update_civilization_player_addresses (
        arr_player_adr_len : felt,
        arr_player_adr : felt*
    ) -> ():
    end
end

##############################

#
# For yagi automation
#
@view
func yagiProbeTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):

    let (_, _, bool) = can_dispatch_player_to_universe ()

    return (bool)
end

@external
func yagiExecuteTask {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():

    anyone_dispatch_player_to_universe ()

    return ()
end

##############################

#
# Functions for dispatching players from queue to universe
#
@view
func can_dispatch_player_to_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (
        curr_head_idx : felt,
        curr_tail_idx : felt,
        idle_universe_idx : felt
        bool : felt
    ):

    #
    # Check if at least `CIV_SIZE` worth of players in queue for dispatch
    #
    let (curr_head_idx) = ns_lobby_state_functions.queue_head_index_read ()
    let (curr_tail_idx) = ns_lobby_state_functions.queue_tail_index_read ()
    let curr_len = curr_tail_idx - curr_head_idx
    let (bool_has_sufficient_players_in_queue) = is_le (CIV_SIZE, curr_len)

    #
    # Check if at least one Universe is idle
    #
    local bool_has_idle_universe
    local idle_universe_idx
    recurse_find_idle_universe (bool_has_idle_universe, idle_universe_idx, 0)

    #
    # Aggregate flags
    #
    let bool = bool_has_sufficient_players_in_queue * bool_has_idle_universe

    return (curr_head_idx, curr_tail_idx, idle_universe_idx, bool)
end

func recurse_find_idle_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        bool_has_idle_universe : felt,
        idle_universe_idx : felt
        idx : felt
    ) -> ():

    if idx == UNIVERSE_COUNT:
        #
        # No idle universe found
        #
        assert bool_has_idle_universe = 0
        assert idle_universe_idx = 0
        return ()
    end

    let (is_active) = ns_lobby_state_functions.universe_active_read (idx)

    if is_active == 0:
        #
        # Idle universe found
        #
        assert bool_has_idle_universe = 1
        assert idle_universe_idx = idx
        return ()
    else:
        #
        # Recurse
        #
        recurse_find_idle_universe (
            bool_has_idle_universe,
            idle_universe_idx,
            idx + 1
        )
    end

    return ()
end

@external
func anyone_dispatch_player_to_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    #
    # Confirm can dispatch player to idle universe
    #
    let (
        curr_head_idx,
        curr_tail_idx,
        idle_universe_idx,
        bool
    ) = can_dispatch_player_to_universe ()
    with_attr error_message ("Unable to dispatch: either not having enough players in queue or not having idle universe available"):
        assert bool = 1
    end

    #
    # Prepare array of player addresses for dispatch; update queue accordingly
    #
    let (arr_player_adr : felt*) = alloc ()
    recurse_populate_player_adr_update_queue (
        arr_player_adr,
        curr_head_idx,
        0
    )

    #
    # Forward queue head index
    #
    queue_head_index_write (curr_head_idx + CIV_SIZE)

    #
    # Get universe address from idx
    #
    let (universe_address) = ns_lobby_state_functions.universe_addresses_read (idle_universe_idx)

    #
    # Dispatch
    #
    IContractUniverse.update_civilization_player_addresses (
        universe_address,
        arr_player_adr_len = CIV_SIZE,
        arr_player_adr = arr_player_adr
    )

    return ()
end

func recurse_populate_player_adr_update_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_player_adr : felt*,
        curr_head_idx : felt,
        offset : felt
    ) -> ():
    alloc_locals

    if offset == CIV_SIZE:
        return ()
    end

    #
    # Populate `arr_player_adr` array
    #
    let (player_adr) = queue_index_to_address_read (curr_head_idx + offset)
    assert arr_player_adr [offset] = player_adr

    #
    # Clear queue entry at `curr_head_idx + offset`
    #
    queue_address_to_index_write (player_adr, 0)
    queue_index_to_address_write (curr_head_idx + offset, 0)

    #
    # Tail recursion
    #
    recurse_populate_player_adr_update_queue (
        player_adr,
        curr_head_idx,
        offset + 1
    )

    return ()
end

##########################
#
##########################

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        universe_addresses_len : felt,
        universe_addresses : felt*
    ):

    recurse_write_universe_addresses (
        universe_addresses_len,
        universe_addresses,
        0
    )

    return()
end

func recurse_write_universe_addresses {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        adr_len : felt,
        adr : felt*,
        idx : felt
    ) -> ():

    if idx == adr_len:
        return ()
    end

    ns_lobby_state_functions.universe_addresses_write (idx, adr[idx])

    #
    # Tail recursion
    #
    recurse_write_universe_addresses (adr_len, adr, idx + 1)
    return ()
end

@external
func client_ask_to_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():
    alloc_locals

    #
    # Revert if caller is already in queue (index should be zero for address not in queue)
    #
    let (caller) = get_caller_address ()
    let (caller_idx_in_queue) = ns_lobby_state_functions.queue_address_to_index_read (caller)
    with_attr error_message ("caller index in queue != 0 => caller already in queue."):
        assert caller_idx_in_queue = 0
    end

    #
    # Enqueue
    #
    let (curr_tail_idx) = ns_lobby_state_functions.queue_tail_index_read ()
    let new_player_idx = curr_tail_idx + 1
    ns_lobby_state_functions.queue_tail_index_write (new_player_idx)
    ns_lobby_state_functions.queue_address_to_index_write (caller, new_player_idx)
    ns_lobby_state_functions.queue_index_to_address_write (new_player_idx, caller)

    return ()
end
