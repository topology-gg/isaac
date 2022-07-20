%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_zero
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.util.structs import (
    Play
)
from contracts.design.constants import (
    GYOZA, CIV_SIZE, UNIVERSE_COUNT
)
from contracts.lobby.lobby_state import (
    ns_lobby_state_functions
)
from contracts.lobby.ticket_state import (
    ns_ticket_state
)

const UNIVERSE_INDEX_OFFSET = 777

##############################

#
# Event emission for Apibara
#
@event
func universe_activation_occurred (
    event_counter      : felt,
    universe_index     : felt,
    universe_address   : felt,
    arr_player_adr_len : felt,
    arr_player_adr     : felt*
):
end

@event
func universe_deactivation_occurred (
    event_counter      : felt,
    universe_index     : felt,
    universe_address   : felt,
    arr_player_adr_len : felt,
    arr_player_adr     : felt*
):
end

@event
func ask_to_queue_occurred (
    event_counter : felt,
    account : felt,
    queue_idx : felt
):
end

@event
func give_invitation_occurred (
    event_counter : felt,
    account : felt
):
end

##############################

#
# Interfacing with deployed `universe.cairo` and `dao.cairo`
#

@contract_interface
namespace IContractUniverse:
    func activate_universe (
        arr_player_adr_len : felt,
        arr_player_adr : felt*
    ) -> ():
    end

    func check_address_in_civilization (
        address : felt
    ) -> (
        bool : felt
    ):
    end
end

@contract_interface
namespace IContractDAO:
    func subject_report_play (
        arr_play_len : felt,
        arr_play : Play*
    ) -> ():
    end
end

##############################

#
# Interfacing with s2m2
#
struct Record:
        member success : felt
        member puzzle_id : felt
    end


@contract_interface
namespace IContractS2m2:

    func read_s2m_solver_record (
        address : felt
    ) -> (record : Record):
    end

end

##############################

#
# For yagi automation
#
@view
func probe_can_dispatch_to_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):

    let (_, _, _, bool) = can_dispatch_player_to_universe ()

    return (bool)
end

## Note: hook up router with `anyone_dispatch_player_to_universe ()` for yagi execution

##############################

@constructor
func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

    #
    # give an invitation to GYOZA
    #
    ns_ticket_state.account_has_invitation_write (GYOZA, 1)

    let (event_counter) = ns_lobby_state_functions.event_counter_read ()
    ns_lobby_state_functions.event_counter_increment ()
    give_invitation_occurred.emit (
        event_counter,
        GYOZA
    )

    return()
end


@external
func init_give_invitations_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_guests_len : felt,
        arr_guests : felt*
    ):

    let (bool) = ns_lobby_state_functions.init_invitations_made_read ()
    with_attr error_message ("this function can only be invoked once"):
        assert bool = 0
    end

    recurse_give_invitations (0, arr_guests_len, arr_guests)
    ns_lobby_state_functions.init_invitations_made_set ()

    return ()
end


func recurse_give_invitations {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        arr_addr_len : felt,
        arr_addr : felt*
    ) -> ():

    if idx == arr_addr_len:
        return ()
    end

    ns_ticket_state.account_has_invitation_write (arr_addr[idx], 1)

    let (event_counter) = ns_lobby_state_functions.event_counter_read ()
    ns_lobby_state_functions.event_counter_increment ()
    give_invitation_occurred.emit (
        event_counter,
        arr_addr[idx]
    )

    recurse_give_invitations (
        idx + 1,
        arr_addr_len,
        arr_addr
    )
    return ()
end

@external
func set_universe_addresses_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        universe_addresses_len : felt,
        universe_addresses : felt*
    ):

    #
    # Check if the first universe address is already set
    #
    let (address) = ns_lobby_state_functions.universe_addresses_read (0 + UNIVERSE_INDEX_OFFSET)
    with_attr error_message ("Universe address already set"):
        assert address = 0
    end

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

    let universe_idx = idx + UNIVERSE_INDEX_OFFSET
    ns_lobby_state_functions.universe_addresses_write (
        universe_idx,
        adr[idx]
    )
    ns_lobby_state_functions.universe_address_to_index_write (
        adr[idx],
        universe_idx
    )

    #
    # Tail recursion
    #
    recurse_write_universe_addresses (adr_len, adr, idx + 1)
    return ()
end

##############################

#
# Functions to handle access to lobby queueing
#

@external
func gyoza_give_invitation_to_account {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        account : felt
    ) -> ():

    let (caller) = get_caller_address ()
    with_attr error_message ("only gyoza can invoke this function"):
        assert caller = GYOZA
    end

    ns_ticket_state.account_has_invitation_write (account, 1)

    let (event_counter) = ns_lobby_state_functions.event_counter_read ()
    ns_lobby_state_functions.event_counter_increment ()
    give_invitation_occurred.emit (
        event_counter,
        account
    )

    return ()
end

@external
func set_s2m2_address_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt
    ) -> ():

    let (curr_address) = ns_ticket_state.s2m2_address_read ()
    with_attr error_message ("s2m2 contract address has been set"):
        assert curr_address = 0
    end

    ns_ticket_state.s2m2_address_write (address)

    return ()
end

func account_has_ticket_or_invitation {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        account : felt
    ) -> (
        bool : felt
    ):

    #
    # Check if account has invitation
    #
    let (bool_has_invitation) = ns_ticket_state.account_has_invitation_read (account)
    if bool_has_invitation == 1:
        return (1)
    end

    #
    # Check if account has solved s2m2
    #
    let (s2m2_address) = ns_ticket_state.s2m2_address_read ()
    let (record : Record) = IContractS2m2.read_s2m_solver_record (s2m2_address, account)
    if record.success == 1:
        return (1)
    end

    return (0)
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
        idle_universe_idx : felt,
        bool : felt
    ):
    alloc_locals

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
    let (bool_has_idle_universe, idle_universe_idx) = recurse_find_idle_universe (0)

    #
    # Aggregate flags
    #
    let bool = bool_has_sufficient_players_in_queue * bool_has_idle_universe

    return (curr_head_idx, curr_tail_idx, idle_universe_idx, bool)
end

func recurse_find_idle_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt
    ) -> (
        bool_has_idle_universe : felt,
        idle_universe_idx : felt
    ):

    if idx == UNIVERSE_COUNT:
        return (0,0)
    end

    let universe_idx = idx + UNIVERSE_INDEX_OFFSET
    let (is_active) = ns_lobby_state_functions.universe_active_read (universe_idx)
    if is_active == 0:
        return (1, universe_idx)
    end

    let (b, i) = recurse_find_idle_universe (idx + 1)
    return (b, i)
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
    ns_lobby_state_functions.queue_head_index_write (curr_head_idx + CIV_SIZE)

    #
    # Get universe address from idx
    #
    let (universe_address) = ns_lobby_state_functions.universe_addresses_read (idle_universe_idx)

    #
    # Mark universe as active
    #
    ns_lobby_state_functions.universe_active_write (idle_universe_idx, 1)

    #
    # Dispatch
    #
    IContractUniverse.activate_universe (
        universe_address,
        arr_player_adr_len = CIV_SIZE,
        arr_player_adr = arr_player_adr
    )

    #
    # Apibara event emission
    #
    let (event_counter) = ns_lobby_state_functions.event_counter_read ()
    ns_lobby_state_functions.event_counter_increment ()
    universe_activation_occurred.emit (
        event_counter,
        idle_universe_idx,
        universe_address,
        CIV_SIZE,
        arr_player_adr
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
    # Note: always start from head index + 1
    #
    let (player_adr) = ns_lobby_state_functions.queue_index_to_address_read (curr_head_idx + offset + 1)
    assert arr_player_adr [offset] = player_adr

    #
    # Clear queue entry at `curr_head_idx + offset`
    #
    ns_lobby_state_functions.queue_address_to_index_write (player_adr, 0)
    ns_lobby_state_functions.queue_index_to_address_write (curr_head_idx + offset + 1, 0)

    #
    # Tail recursion
    #
    recurse_populate_player_adr_update_queue (
        arr_player_adr,
        curr_head_idx,
        offset + 1
    )

    return ()
end

##############################

#
# Function for player to join queue
# NOTE: queue idx starts from 1; 0 is reserved for uninitialized (not in queue)
#
@external
func anyone_ask_to_queue {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():
    alloc_locals

    #
    # Revert is caller is 0x0 address => universe contract uses 0x0 as indicator of uninitialized
    #
    let (caller) = get_caller_address ()
    with_attr error_message ("address 0x0 is not allowed to join queue"):
        assert_not_zero (caller)
    end

    #
    # Revert if caller index-in-queue is not zero, indicating the caller is already in the queue
    #
    let (caller_idx_in_queue) = ns_lobby_state_functions.queue_address_to_index_read (caller)
    with_attr error_message ("caller index in queue != 0 => caller already in queue."):
        assert caller_idx_in_queue = 0
    end

    #
    # Revert if caller is in one of the active universes
    #
    recurse_assert_caller_not_in_active_universe (0, caller)

    #
    # Revert if caller has no ticket nor invitation to the Isaac reality
    #
    let (bool_has_ticket_or_invitation) = account_has_ticket_or_invitation (caller)
    with_attr error_message ("caller has no invitation to Isaac nor record of having solved a puzzle at s2m2"):
        assert bool_has_ticket_or_invitation = 1
    end

    #
    # Enqueue
    #
    let (curr_tail_idx) = ns_lobby_state_functions.queue_tail_index_read ()
    let new_player_idx = curr_tail_idx + 1
    ns_lobby_state_functions.queue_tail_index_write (new_player_idx)
    ns_lobby_state_functions.queue_address_to_index_write (caller, new_player_idx)
    ns_lobby_state_functions.queue_index_to_address_write (new_player_idx, caller)


    #
    # Event emission
    #
    let (event_counter) = ns_lobby_state_functions.event_counter_read ()
    ns_lobby_state_functions.event_counter_increment ()
    ask_to_queue_occurred.emit (
        event_counter,
        caller,
        new_player_idx
    )

    return ()
end


func recurse_assert_caller_not_in_active_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        caller : felt
    ) -> ():
    alloc_locals

    local index = idx

    if index == UNIVERSE_COUNT:
        return ()
    end

    let universe_idx = index + UNIVERSE_INDEX_OFFSET
    let (universe_addr) = ns_lobby_state_functions.universe_addresses_read (universe_idx)
    let (bool_in_civ) = IContractUniverse.check_address_in_civilization (
        universe_addr,
        caller
    )
    with_attr error_message ("caller already in the active universe {index}"):
        assert bool_in_civ = 0
    end

    recurse_assert_caller_not_in_active_universe (idx + 1, caller)
    return ()
end


##############################

#
# Functions for:
# - settting DAO address once
# - universe to report play records, which is reported up to IsaacDAO
#
@external
func set_dao_address_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address : felt) -> ():

    let (curr_dao_address) = ns_lobby_state_functions.dao_address_read ()
    with_attr error_message ("DAO address is already set"):
        assert curr_dao_address = 0
    end

    ns_lobby_state_functions.dao_address_write (address)

    return ()
end

@external
func universe_report_play {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_play_len : felt,
        arr_play : Play*
    ) -> ():
    alloc_locals

    #
    # Caller qualification - must be an active universe
    #
    let (caller) = get_caller_address ()
    let (universe_idx) = ns_lobby_state_functions.universe_address_to_index_read (caller)
    assert_not_zero (universe_idx) ## zero index means invalid universe address, because every universe address is offset by UNIVERSE_INDEX_OFFSET
    let (universe_status) = ns_lobby_state_functions.universe_active_read (universe_idx)
    assert universe_status = 1 ## the calling universe needs to be active

    #
    # Mark universe as idle
    #
    ns_lobby_state_functions.universe_active_write (universe_idx, 0)

    #
    # Apibara event emission
    # (need to prepare `arr_player_adr`)
    #
    let (arr_player_adr : felt*) = alloc ()
    recurse_prepare_arr_player_adr_from_report_play (0, arr_player_adr, arr_play)

    let (event_counter) = ns_lobby_state_functions.event_counter_read ()
    ns_lobby_state_functions.event_counter_increment ()
    universe_deactivation_occurred.emit (
        event_counter,
        universe_idx,
        caller,
        CIV_SIZE,
        arr_player_adr
    )

    #
    # Pass play to DAO
    #
    let (dao_address) = ns_lobby_state_functions.dao_address_read ()
    IContractDAO.subject_report_play (
        dao_address,
        arr_play_len,
        arr_play
    )

    return ()
end

func recurse_prepare_arr_player_adr_from_report_play {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        arr_player_adr : felt*,
        arr_play : Play*
    ) -> ():
    alloc_locals

    if idx == CIV_SIZE:
        return ()
    end

    assert arr_player_adr[idx] = arr_play[idx].player_address

    recurse_prepare_arr_player_adr_from_report_play (
        idx + 1,
        arr_player_adr,
        arr_play
    )
    return ()
end
