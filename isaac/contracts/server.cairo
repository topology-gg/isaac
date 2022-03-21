%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.macro import (forward_world_macro)
# from contracts.design.constants import ()
from contracts.util.structs import (
    MacroEvent, MicroEvent,
    Vec2, Dynamic, Dynamics
)

##############################

@storage_var
func last_l2_block () -> (block_num : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

    # TODO: initialize macro world - trisolar system placement
    # TODO: initialize mini world - resource distribution placement

    let (block) = get_block_number ()
    last_l2_block.write (block)

    return()
end

##############################

#
# phi: the spin orientation of the planet in the trisolar coordinate system;
# spin axis perpendicular to the plane of orbital motion
#
@storage_var
func phi_curr () -> (phi : felt):
end

@storage_var
func macro_state_curr () -> (macro_state : Dynamics):
end

@external
func forward_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Make sure only one L2 block has passed
    # TODO: allow fast-foward >1 L2 blocks in case of unexpected network / yagi issues
    #
    let (block_curr) = get_block_number ()
    let (block_last) = last_l2_block.read ()
    let block_diff = block_curr - block_last
    with_attr error_message("last block must be exactly one block away from current block."):
        assert block_diff = 1
    end

    #
    # Forward macro world - orbital positions of trisolar system, and spin orientation of planet
    # TODO: allow fast-foward >1 DT, requiring recursive calls to forward_world_macro ()
    #
    let (macro_state : Dynamics) = macro_state_curr.read ()
    let (phi : felt) = phi_curr.read ()
    let (
        macro_state_nxt : Dynamics,
        phi_nxt : felt
    ) = forward_world_macro (macro_state, phi)
    macro_state_curr.write (macro_state_nxt)
    phi_curr.write (phi_nxt)

    #
    # Forward micro world - all activities on the surface of the planet
    #
    forward_world_micro ()

    return ()
end

##############################

#
# Storing macro events for client retrieval
#
@storage_var
func macro_events_count () -> (count : felt):
end

@storage_var
func macro_events (index : felt) -> (event : MacroEvent):
end

func log_macro_event {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        event : MacroEvent
    ) -> ():
    alloc_locals

    let (count) = macro_events_count.read ()
    macro_events.write (count, event)
    macro_events_count.write (count+1)

    return ()
end

#
# Storing micro events for client retrieval
#
@storage_var
func micro_events_count () -> (count : felt):
end

@storage_var
func micro_events (index : felt) -> (event : MicroEvent):
end

func log_micro_event {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        event : MicroEvent
    ) -> ():
    alloc_locals

    let (count) = micro_events_count.read ()
    micro_events.write (count, event)
    micro_events_count.write (count+1)

    return ()
end

#
# Retrieve all macro/micro events transpired after a given index in an array;
# used by any client to forward their client-side macro state;
# the client should cache the last-synced event index,
# and ideally interpolate when replaying the events to catch up smoothly visually
#
@view
func view_macro_events_starting_from_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        index : felt
    ) -> (
        events_len : felt,
        events : MacroEvent*
    ):
    alloc_locals

    let (count) = macro_events_count.read ()
    let (events : MacroEvent*) = alloc ()
    recurse_populate_array_from_macro_events (
        count = count,
        arr = events,
        idx_arr = 0,
        idx_sto = index
    )

    return (
        count-index,
        events
    )
end

func recurse_populate_array_from_macro_events {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        count : felt,
        arr : MacroEvent*,
        idx_arr : felt,
        idx_sto : felt
    ) -> ():
    alloc_locals

    if idx_sto == count:
        return ()
    end

    let (event) = macro_events.read (idx_sto)
    assert arr[idx_arr] = event

    recurse_populate_array_from_macro_events (
        count,
        arr,
        idx_arr + 1,
        idx_sto + 1
    )

    return ()
end

@view
func view_micro_events_starting_from_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        index : felt
    ) -> (
        events_len : felt,
        events : MicroEvent*
    ):
    alloc_locals

    let (count) = micro_events_count.read ()
    let (events : MicroEvent*) = alloc ()
    recurse_populate_array_from_micro_events (
        count = count,
        arr = events,
        idx_arr = 0,
        idx_sto = index
    )

    return (
        count-index,
        events
    )
end

func recurse_populate_array_from_micro_events {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
        count : felt,
        arr : MicroEvent*,
        idx_arr : felt,
        idx_sto : felt
    ) -> ():
    alloc_locals

    if idx_sto == count:
        return ()
    end

    let (event) = micro_events.read (idx_sto)
    assert arr[idx_arr] = event

    recurse_populate_array_from_micro_events (
        count,
        arr,
        idx_arr + 1,
        idx_sto + 1
    )

    return ()
end

##############################

func forward_world_micro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr}(
    ) -> ():

    #
    return ()
end

##############################

#
# Storage, mint() and transfer() for devices
# not going to bother myself for making this 1155 compliant
#
@storage_var
func device_balance_of (owner : felt, kind : felt) -> (amount : felt):
end

#
# Device minting; only triggered at OPSF internally
#
func device_mint {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        kind : felt,
        amount : felt,
        to : felt
    ) -> ():
    alloc_locals

    #
    # mint tokens
    #
    let (amount_curr) = device_balance_of.read (to, kind)
    device_balance_of.write (to, kind, amount_curr + amount)

    #
    # log micro event
    # TODO
    #

    return ()
end

#
# Peer to peer transfer of devices for strategic purposes
#
@external
func device_transfer {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        kind : felt,
        amount : felt,
        to : felt
    ) -> ():
    alloc_locals

    let (caller_addr) = get_caller_address ()

    #
    # Assert caller has sufficient amount of device to transfer
    #
    let (caller_has_amount) = device_balance_of.read (caller_addr, kind)
    let (sufficient) = is_le (amount, caller_has_amount)
    assert sufficient = 1

    #
    # Make transfer
    #
    let (to_has_amount) = device_balance_of.read (to, kind)
    device_balance_of.write (caller_addr, kind, caller_has_amount - amount)
    device_balance_of.write (to,          kind, to_has_amount + amount)

    #
    # log micro event
    # TODO
    #

    return ()
end

#
# Player deploy one device at;
# excluding UTB and UTL, which requires dynamic set management
#
# @external
# func device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
#         at : ,
#         kind :
#     ) -> ():

#     # TODO: deal with bigger device taking up >1 grid
# end

#
# Player pick up one device at;
# excluding UTB and UTL, which requires dynamic set management
#
# @external
# func device_pickup {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
#         at : ,
#     ) -> ():

# end

