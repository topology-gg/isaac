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
    GYOZA,
    MIN_L2_BLOCK_NUM_BETWEEN_FORWARD,
    UNIVERSE_MAX_AGE_IN_L2_BLOCK_NUM,
    CIV_SIZE,
    ns_macro_init
)
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics,
    Play
)

#
# Import getters and setters for universe states
#
from contracts.universe.universe_state import (
    ns_universe_state_functions
)

#
# Import functions / namespaces for macro world
# TODO: extract macro state from this contract to `macro_state.cairo`
#
from contracts.macro.macro_simulation import (
    forward_world_macro,
    is_world_macro_escape_condition_met
)
from contracts.macro.macro_state import (ns_macro_state_functions)

#
# Import states / functions / namespaces for micro world
#
from contracts.micro.micro_state import (ns_micro_state_functions, DeviceDeployedEmapEntry, UtxSetDeployedEmapEntry)
from contracts.micro.micro_devices import (ns_micro_devices)
from contracts.micro.micro_utx import (ns_micro_utx)
from contracts.micro.micro_forwarding import (ns_micro_forwarding)
from contracts.micro.micro_iterator import (ns_micro_iterator)
from contracts.micro.micro_reset import (ns_micro_reset)

#
# Interface with lobby
#
@contract_interface
namespace IContractLobby:
    func universe_report_play (
        arr_play_len : felt,
        arr_play : Play*
    ) -> ():
    end
end

func assert_address_in_civilization {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address) -> ():

    let (bool) = ns_universe_state_functions.civilization_player_address_to_bool_read (address)
    with_attr error_message ("caller is not in the civilization of this universe"):
        assert bool = 1
    end

    return ()
end

func assert_caller_is_lobby {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

    let (caller) = get_caller_address ()
    let (lobby_address) = ns_universe_state_functions.lobby_address_read ()
    with_attr error_message ("Caller is not the lobby contract"):
        assert caller = lobby_address
    end

    return ()
end

##########################
# Init and reset functions
##########################

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

    reset_and_deactivate_universe ()

    return()
end

@external
func set_lobby_address_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address) -> ():

    #
    # Only GYOZA can set lobby address
    #
    # assert_caller_is_admin ()

    #
    # Check if lobby address is already set
    #
    let (curr_lobby_address) = ns_universe_state_functions.lobby_address_read ()
    with_attr error_message ("Lobby address already set"):
        assert curr_lobby_address = 0
    end

    #
    # Set lobby address
    #
    ns_universe_state_functions.lobby_address_write (address)

    return ()
end

func recurse_reset_civilization_registry {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    idx : felt) -> ():

    if idx == CIV_SIZE:
        return ()
    end

    #
    # reset registry entry for `idx`
    #
    let (player_address) = ns_universe_state_functions.civilization_player_idx_to_address_read (idx)
    ns_universe_state_functions.civilization_player_idx_to_address_write (idx, 0)
    ns_universe_state_functions.civilization_player_address_to_bool_write (player_address, 0)
    ns_universe_state_functions.civilization_player_address_to_has_launched_ndpe_write (player_address, 0)

    #
    # Tail recursion
    #
    recurse_reset_civilization_registry (idx + 1)
    return ()
end

func reset_and_deactivate_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Clear civilization registry
    #
    recurse_reset_civilization_registry (0)

    return ()
end

@external
func activate_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_player_adr_len : felt,
        arr_player_adr : felt*
    ) -> ():

    #
    # Only lobby contract can invoke this function
    #
    assert_caller_is_lobby ()

    #
    # Confirm getting `CIV_SIZE` worth of player addresses
    #
    assert arr_player_adr_len = CIV_SIZE

    #
    # Recursively activate civilization records given player addresses
    #
    recurse_populate_civilization_player_states (
        arr_player_adr,
        0
    )

    #
    # Increment civilization index
    #
    let (curr_civ_idx) = ns_universe_state_functions.civilization_index_read ()
    ns_universe_state_functions.civilization_index_write (curr_civ_idx + 1)

    #
    # Record L2 block at universe activation
    # in both `l2_block_at_last_forward` and `l2_block_at_genesis`
    #
    let (block) = get_block_number ()
    ns_universe_state_functions.l2_block_at_last_forward_write (block)
    ns_universe_state_functions.l2_block_at_genesis_write (block)

    return ()
end

func recurse_populate_civilization_player_states {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_player_adr : felt*,
        idx : felt
    ) -> ():

    if idx == CIV_SIZE:
        return ()
    end

    #
    # Activate civilization record for player address
    #
    ns_universe_state_functions.civilization_player_idx_to_address_write (idx, arr_player_adr[idx])
    ns_universe_state_functions.civilization_player_address_to_bool_write (arr_player_adr[idx], 1)

    #
    # Tail recursion
    #
    recurse_populate_civilization_player_states (
        arr_player_adr,
        idx + 1
    )
    return ()
end

func is_universe_active {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool):

    # check player address at `idx=0` is not zero in civilization registry
    # (idle universe would have all player address equal to zero in civilization registry

    let (player_address) = ns_universe_state_functions.civilization_player_idx_to_address_read (0)
    if player_address == 0:
        return (0)
    else:
        return (1)
    end

end

@external
func test_terminate_universe_and_notify_lobby {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        bool_universe_escape_condition_met : felt
    ) -> ():
    alloc_locals

    #
    # Notify lobby of info for P2G participation calculation;
    # this needs to precede resetting universe, otherwise civilization address info is unavailable
    #
    let (lobby_address) = ns_universe_state_functions.lobby_address_read ()
    let (arr_play : Play*) = alloc ()
    recurse_prepare_play_record (
        bool_universe_escape_condition_met,
        arr_play,
        0
    )
    IContractLobby.universe_report_play (
        lobby_address,
        CIV_SIZE,
        arr_play
    )

    #
    # Reset universe
    #
    reset_and_deactivate_universe ()

    return ()
end

func recurse_prepare_play_record {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        bool_universe_escape_condition_met : felt,
        arr_play : Play*,
        idx : felt
    ) -> ():
    alloc_locals

    if idx == CIV_SIZE:
        return ()
    end

    let (player_address) = ns_universe_state_functions.civilization_player_idx_to_address_read (idx)
    let (has_launched_ndpe) = ns_universe_state_functions.civilization_player_address_to_has_launched_ndpe_read (player_address)
    let grade = bool_universe_escape_condition_met * has_launched_ndpe
    assert arr_play[idx] = Play (
        player_address = player_address,
        grade = grade
    )

    #
    # Tail recursion
    #
    recurse_prepare_play_record (
        bool_universe_escape_condition_met,
        arr_play,
        idx + 1
    )
    return ()
end

@external
func test_write_civilization_player_address_to_has_launched_ndpe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    player_adr : felt, has_launched_ndpe : felt) -> ():

    ns_universe_state_functions.civilization_player_address_to_has_launched_ndpe_write (player_adr, has_launched_ndpe)

    return ()
end