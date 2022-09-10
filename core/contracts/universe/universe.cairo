%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le, assert_not_equal, assert_not_zero
from starkware.cairo.common.math_cmp import is_le, is_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

#
# Import constants and structs
#
from contracts.design.constants import (
    GYOZA, ns_device_types,
    MIN_L2_BLOCK_NUM_BETWEEN_FORWARD,
    UNIVERSE_MAX_AGE_IN_TICKS,
    CIV_SIZE,
    ns_macro_init,
    is_device_type_utx
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
    is_world_macro_escape_condition_met,
    is_world_macro_destructed
)
from contracts.macro.macro_state import (ns_macro_state_functions)

#
# Import states / functions / namespaces for micro world
#
from contracts.micro.micro_state import (ns_micro_state_functions, DeviceEmapEntry, UtxSetDeployedEmapEntry)
from contracts.micro.micro_devices import (ns_micro_devices)
from contracts.micro.micro_utx import (ns_micro_utx)
from contracts.micro.micro_forwarding import (ns_micro_forwarding)
from contracts.micro.micro_iterator import (ns_micro_iterator)
from contracts.micro.micro_reset import (ns_micro_reset)

##############################

#
# Event emission for Apibara
#
@event
func activate_universe_occurred (
        event_counter : felt,
        civ_idx : felt
    ):
end

@event
func give_undeployed_fungible_device_occurred (
        event_counter : felt,
        to : felt,
        type : felt,
        amount : felt
    ):
end

@event
func player_deploy_device_occurred (
        event_counter : felt,
        owner : felt,
        device_id : felt,
        grid : Vec2
    ):
end

@event
func player_pickup_device_occurred (
        event_counter : felt,
        owner : felt,
        device_id : felt,
        grid : Vec2
    ):
end

@event
func player_deploy_utx_occurred (
        event_counter : felt,
        owner : felt,
        utx_label : felt,
        utx_device_type : felt,
        src_device_grid : Vec2,
        dst_device_grid : Vec2,
        locs_len : felt,
        locs : Vec2*
    ):
end

@event
func player_pickup_utx_occurred (
        event_counter : felt,
        owner : felt,
        grid : Vec2
    ):
end

@event
func player_upsf_build_fungible_device_occurred (
        event_counter : felt,
        owner : felt,
        grid : Vec2,
        device_type : felt,
        device_count : felt
    ):
end

@event
func player_transfer_undeployed_fungible_device_occurred (
        event_counter : felt,
        src : felt,
        dst : felt,
        device_type : felt,
        device_amount : felt
    ):
end

@event
func player_transfer_undeployed_nonfungible_device_occurred (
        event_counter : felt,
        src : felt,
        dst : felt,
        device_id : felt
    ):
end

@event
func terminate_universe_occurred (
        event_counter : felt,
        bool_universe_terminable : felt,
        destruction_by_which_sun : felt,
        bool_universe_max_age_reached : felt,
        bool_universe_escape_condition_met : felt
    ):
end

##############################

#
# For yagi automation
# Note: each universe is forwarded by yagi individually because of the
#       complexity of universe forwarding; aggregating all universe forwarding
#       into one transaction is more susceptible to exceeding n_step upper bound per tx.
#
@view
func probe_can_forward_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (bool : felt):

    let (_, bool) = can_forward_universe ()

    return (bool)
end

##############################

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

################
# Access control
################

# func assert_caller_is_admin {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():

#     let (caller) = get_caller_address ()
#     with_attr error_message ("Isaac currently operates under gyoza the benevolent dictator. Only gyoza can tick Isaac forward."):
#         assert caller = GYOZA
#     end

#     return ()
# end

@view
func check_address_in_civilization {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address : felt) -> (bool : felt):

    let (bool) = ns_universe_state_functions.civilization_player_address_to_bool_read (address)

    return (bool)
end

func assert_address_in_civilization {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address) -> ():

    let (bool) = check_address_in_civilization (address)
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

# @constructor
# func constructor {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

#     # let (curr_block_height) = get_block_number ()
#     # ns_universe_state_functions.l2_block_at_genesis_write (curr_block_height)

#     reset_and_deactivate_universe ()

#     return()
# end

@external
func set_lobby_address_once {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    address) -> ():

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
    # Reset micro world - all storages in `micro_state.cairo`
    #
    ns_micro_reset.reset_world_micro ()

    #
    # Reset macro world - trisolar system placement & planet rotation
    #
    let (macro_initial_state) = get_macro_initial_state ()
    ns_macro_state_functions.macro_state_curr_write (macro_initial_state)
    ns_macro_state_functions.phi_curr_write (ns_macro_init.phi)

    #
    # Reset number of ticks since genesis
    #
    ns_universe_state_functions.number_of_ticks_since_genesis_write (0)

    #
    # Clear civilization registry
    #
    recurse_reset_civilization_registry (0)

    return ()
end

func get_macro_initial_state {} () -> (dynamics : Dynamics):
    return (Dynamics(
        sun0 = Dynamic(
            q = Vec2(
                x = ns_macro_init.sun0_qx,
                y = ns_macro_init.sun0_qy
            ),
            qd = Vec2(
                x = ns_macro_init.sun0_px,
                y = ns_macro_init.sun0_py
            )
        ),
        sun1 = Dynamic(
            q = Vec2(
                x = ns_macro_init.sun1_qx,
                y = ns_macro_init.sun1_qy
            ),
            qd = Vec2(
                x = ns_macro_init.sun1_px,
                y = ns_macro_init.sun1_py
            )
        ),
        sun2 = Dynamic(
            q = Vec2(
                x = ns_macro_init.sun2_qx,
                y = ns_macro_init.sun2_qy
            ),
            qd = Vec2(
                x = ns_macro_init.sun2_px,
                y = ns_macro_init.sun2_py
            )
        ),
        plnt = Dynamic(
            q = Vec2(
                x = ns_macro_init.plnt_qx,
                y = ns_macro_init.plnt_qy
            ),
            qd = Vec2(
                x = ns_macro_init.plnt_px,
                y = ns_macro_init.plnt_py
            )
        )
    ))
end

@external
func activate_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_player_adr_len : felt,
        arr_player_adr : felt*
    ) -> ():
    alloc_locals

    reset_and_deactivate_universe ()

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
    let new_civ_idx = curr_civ_idx + 1
    ns_universe_state_functions.civilization_index_write (new_civ_idx)

    #
    # Record L2 block at universe activation
    # in both `l2_block_at_last_forward` and `l2_block_at_genesis`
    #
    let (block) = get_block_number ()
    ns_universe_state_functions.l2_block_at_last_forward_write (block)
    ns_universe_state_functions.l2_block_at_genesis_write (block)

    #
    # Forward macro once for Space View to render
    #
    forward_world_macro ()

    #
    # Event emission for Apibara
    #
    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    activate_universe_occurred.emit (
        event_counter,
        new_civ_idx
    )

    return ()
end

func recurse_populate_civilization_player_states {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_player_adr : felt*,
        idx : felt
    ) -> ():
    alloc_locals

    if idx == CIV_SIZE:
        return ()
    end

    #
    # Activate civilization record for player address
    #
    let player_adr = arr_player_adr[idx]
    ns_universe_state_functions.civilization_player_idx_to_address_write (idx, player_adr)
    ns_universe_state_functions.civilization_player_address_to_bool_write (player_adr, 1)

    #
    # Give player the starting loadout
    #
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_SPG,     amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_NPG,     amount = 10)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_FE_HARV, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_AL_HARV, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_CU_HARV, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_SI_HARV, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_PU_HARV, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_FE_REFN, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_AL_REFN, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_CU_REFN, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_SI_REFN, amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_PEF,     amount = 2)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_UTB,     amount = 50)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_UTL,     amount = 50)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_UPSF,    amount = 1)
    give_undeployed_device (to = player_adr, type = ns_device_types.DEVICE_NDPE,    amount = 10)

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

##############################

@view
func can_forward_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (block_curr : felt, bool : felt):
    alloc_locals

    #
    # Universe is active
    #
    let (bool_universe_is_active) = is_universe_active ()

    #
    # At least MIN_L2_BLOCK_NUM_BETWEEN_FORWARD between last-update block and current block
    #
    let (block_curr) = get_block_number ()
    let (block_last) = ns_universe_state_functions.l2_block_at_last_forward_read ()
    let block_diff = block_curr - block_last
    let (bool_sufficient_block_has_passed) = is_le (MIN_L2_BLOCK_NUM_BETWEEN_FORWARD, block_diff)

    #
    # Aggregate flags
    #
    let bool = bool_universe_is_active * bool_sufficient_block_has_passed

    return (block_curr, bool)
end

@external
func anyone_forward_universe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Confirm world can be forwarded now
    #
    let (block_curr, bool) = can_forward_universe ()
    local min_dist = MIN_L2_BLOCK_NUM_BETWEEN_FORWARD
    with_attr error_message("last-update block must be at least {min_dist} block away from current block."):
        assert bool = 1
    end
    ns_universe_state_functions.l2_block_at_last_forward_write (block_curr)

    #
    # Forward macro world - orbital positions of trisolar system, and spin orientation of planet
    #
    forward_world_macro ()

    #
    # Forward micro world - all activities on the surface of the planet
    #
    ns_micro_forwarding.forward_world_micro ()

    #
    # Increase number_of_ticks_since_genesis by 1
    #
    let (curr_ticks) = ns_universe_state_functions.number_of_ticks_since_genesis_read ()
    ns_universe_state_functions.number_of_ticks_since_genesis_write (curr_ticks + 1)

    #
    # Check if this universe can be terminated
    #
    let (
        bool_universe_terminable,
        destruction_by_which_sun,
        bool_universe_max_age_reached,
        bool_universe_escape_condition_met
    ) = is_universe_terminable (curr_ticks + 1)

    #
    # Initiate termination process if universe is terminable
    #
    if bool_universe_terminable == 1:
        let (event_counter) = ns_universe_state_functions.event_counter_read ()
        ns_universe_state_functions.event_counter_increment ()
        terminate_universe_occurred.emit (
            event_counter,
            bool_universe_terminable,
            destruction_by_which_sun,
            bool_universe_max_age_reached,
            bool_universe_escape_condition_met
        )
        terminate_universe_and_notify_lobby (
            destruction_by_which_sun,
            bool_universe_escape_condition_met
        )

        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end

func terminate_universe_and_notify_lobby {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        destruction_by_which_sun : felt,
        bool_universe_escape_condition_met : felt
    ) -> ():
    alloc_locals

    #
    # Notify lobby of info for P2G participation calculation
    #
    let (lobby_address) = ns_universe_state_functions.lobby_address_read ()
    let (arr_play : Play*) = alloc ()
    recurse_prepare_play_record (
        destruction_by_which_sun,
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

func is_universe_terminable {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        curr_ticks : felt
    ) -> (
        bool : felt,
        destruction_by_which_sun : felt,
        bool_universe_max_age_reached : felt,
        bool_universe_escape_condition_met : felt
    ):
    alloc_locals

    #
    # Check planet - sun collisions
    #
    let (which_sun) = is_world_macro_destructed ()

    #
    # Check universe age against max age
    #
    let (bool_universe_max_age_reached) = is_le (UNIVERSE_MAX_AGE_IN_TICKS, curr_ticks)
    # let (block_genesis) = ns_universe_state_functions.l2_block_at_genesis_read ()
    # let universe_age = block_curr - block_genesis
    # let (bool_universe_max_age_reached) = is_le (UNIVERSE_MAX_AGE_IN_L2_BLOCK_NUM, universe_age)

    #
    # Check macro state against escape condition
    #
    let (bool_universe_escape_condition_met) = is_world_macro_escape_condition_met ()

    #
    # Aggregate flags
    #
    let sum = which_sun + bool_universe_max_age_reached + bool_universe_escape_condition_met
    let (bool) = is_not_zero (sum)
    return (bool, which_sun, bool_universe_max_age_reached, bool_universe_escape_condition_met)
end

func recurse_prepare_play_record {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        destruction_by_which_sun : felt,
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

    let (bool_destructed) = is_not_zero (destruction_by_which_sun)
    if bool_destructed == 1:
        assert arr_play[idx] = Play (
            player_address = player_address,
            grade = -1 # this would map to 0 vote by IsaacDAO's charter
        )
    else:
        assert arr_play[idx] = Play (
            player_address = player_address,
            grade = bool_universe_escape_condition_met * has_launched_ndpe
        )
    end

    #
    # Tail recursion
    #
    recurse_prepare_play_record (
        destruction_by_which_sun,
        bool_universe_escape_condition_met,
        arr_play,
        idx + 1
    )
    return ()
end

##############################

#
# Exposing functions for state-changing operations in micro world
#

@external
func player_deploy_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    device_id : felt, grid : Vec2) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    ns_micro_devices.device_deploy (caller, device_id, grid)

    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_deploy_device_occurred.emit (
        event_counter,
        caller,
        device_id,
        grid
    )

    return ()
end

@external
func player_pickup_device_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    grid : Vec2) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    let (device_id) = ns_micro_devices.device_pickup_by_grid (caller, grid)

    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_pickup_device_occurred.emit (
        event_counter,
        caller,
        device_id,
        grid
    )

    return ()
end

@external
func player_deploy_utx_by_grids {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt,
        src_device_grid : Vec2,
        dst_device_grid : Vec2,
        locs_len : felt,
        locs : Vec2*
    ) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    let (utx_label) = ns_micro_utx.utx_deploy (
        caller,
        utx_device_type,
        locs_len,
        locs,
        src_device_grid,
        dst_device_grid
    )

    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_deploy_utx_occurred.emit (
        event_counter = event_counter,
        owner = caller,
        utx_label = utx_label,
        utx_device_type = utx_device_type,
        src_device_grid = src_device_grid,
        dst_device_grid = dst_device_grid,
        locs_len = locs_len,
        locs = locs
    )

    return ()
end

@external
func player_pickup_utx_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    grid : Vec2) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    ns_micro_utx.utx_pickup_by_grid (caller, grid)

    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_pickup_utx_occurred.emit (
        event_counter = event_counter,
        owner = caller,
        grid = grid
    )

    return ()
end

@external
func player_upsf_build_fungible_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2,
        device_type : felt,
        device_count : felt
    ) -> ():
    alloc_locals

    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    ns_micro_devices.upsf_build_fungible_device (
        caller,
        grid,
        device_type,
        device_count
    )

    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_upsf_build_fungible_device_occurred.emit (
        event_counter,
        caller,
        grid,
        device_type,
        device_count
    )

    return ()
end

@external
func player_upsf_build_nonfungible_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2,
        device_type : felt,
        device_count : felt
    ) -> ():

    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    ns_micro_devices.upsf_build_nonfungible_device (
        caller,
        grid,
        device_type,
        device_count
    )

    ## Note: Apibara event emission for building nonfungible device is located in `micro_devices.cairo :: create_new_nonfungible_device ()`

    return ()
end

@external
func player_launch_all_deployed_ndpe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2
    ) -> ():

    ## Note: caller is expected to provide a grid where caller has an NDPE deployed

    #
    # Player qualification
    #
    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)

    #
    # Invoking `launch_all_deployed_ndpe()` to launch all ndpes:
    # update impulse cache, which will be incorporated in next macro world forwarding,
    # as well as record which player has launched deployed-ndpe - for play record purposes (IsaacDAO)
    #
    ns_micro_devices.launch_all_deployed_ndpe (
        caller,
        grid
    )

    return ()
end


@external
func player_transfer_undeployed_fungible_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        type : felt,
        amount : felt,
        to_player_idx : felt
    ) -> ():
    #
    # get player address at to_player_idx
    #
    let (to) = ns_universe_state_functions.civilization_player_idx_to_address_read (to_player_idx)
    with_attr error_message ("player address should not be 0"):
        assert_not_zero (to)
    end

    #
    # Confirm caller & to are both in this civilization
    #
    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)
    assert_address_in_civilization (to)

    #
    # Confirm caller is not equal to transfer destination
    #
    with_attr error_message ("why transferring to yourself?"):
        assert_not_equal (caller, to)
    end

    #
    # Confirm caller has at least `amount` number of undeployed devices of type `type`
    #
    let (from_curr_amount) = ns_micro_state_functions.fungible_device_undeployed_ledger_read (caller, type)
    with_attr error_message ("insufficient device balance"):
        assert_le (amount, from_curr_amount)
    end

    #
    # Make transfer
    #
    let (to_curr_amount) = ns_micro_state_functions.fungible_device_undeployed_ledger_read (to, type)
    ns_micro_state_functions.fungible_device_undeployed_ledger_write (caller, type, from_curr_amount - amount)
    ns_micro_state_functions.fungible_device_undeployed_ledger_write (to,     type, to_curr_amount + amount)

    #
    # Apibara event emission
    #
    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_transfer_undeployed_fungible_device_occurred.emit (
        event_counter = event_counter,
        src = caller,
        dst = to,
        device_type = type,
        device_amount = amount
    )

    return ()
end

@external
func player_transfer_undeployed_nonfungible_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        device_id : felt,
        to_player_idx : felt
    ) -> ():
    #
    # get player address at to_player_idx
    #
    let (to) = ns_universe_state_functions.civilization_player_idx_to_address_read (to_player_idx)
    with_attr error_message ("player address should not be 0"):
        assert_not_zero (to)
    end

    #
    # Confirm caller & to are both in this civilization
    #
    let (caller) = get_caller_address ()
    assert_address_in_civilization (caller)
    assert_address_in_civilization (to)

    #
    # Confirm caller is not equal to transfer destination
    #
    with_attr error_message ("why transferring to yourself?"):
        assert_not_equal (caller, to)
    end

    #
    # Confirm device_id is a device owned by caller, and it is not deployed
    # note: device_id is given only to non-fungible device
    #
    let (emap_index) = ns_micro_state_functions.device_id_to_emap_index_read (device_id)
    let (emap_entry) = ns_micro_state_functions.device_emap_read (emap_index)
    with_attr error_message ("caller does not own the device with this device_id"):
        assert emap_entry.owner = caller
    end
    with_attr error_message ("The device with this device_id is deployed, hence unable to transfer"):
        assert emap_entry.is_deployed = 0
    end

    #
    # Make transfer by updating the entry in device_emap
    #
    ns_micro_state_functions.device_emap_write (emap_index, DeviceEmapEntry(
        owner       = to,
        type        = emap_entry.type,
        id          = emap_entry.id,
        is_deployed = emap_entry.is_deployed,
        grid        = emap_entry.grid
    ))

    #
    # Apibara event emission
    #
    let (event_counter) = ns_universe_state_functions.event_counter_read ()
    ns_universe_state_functions.event_counter_increment ()
    player_transfer_undeployed_nonfungible_device_occurred.emit (
        event_counter = event_counter,
        src = caller,
        dst = to,
        device_id = device_id
    )

    return ()
end

#
# Exposing iterator functions for observing the micro world
#

@view
func anyone_view_device_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (
        emap_len : felt,
        emap : DeviceEmapEntry*
    ):

    let (emap_len, emap) = ns_micro_iterator.iterate_device_emap ()

    return (emap_len, emap)
end

@view
func anyone_view_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        emap_len : felt,
        emap : UtxSetDeployedEmapEntry*
    ):

    let (emap_len, emap) = ns_micro_iterator.iterate_utx_deployed_emap (utx_device_type)

    return (emap_len, emap)
end

@view
func anyone_view_all_utx_grids {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt
    ) -> (
        grids_len : felt,
        grids : Vec2*
    ):

    let (grids_len, grids) = ns_micro_iterator.iterate_utx_deployed_emap_grab_all_utxs (utx_device_type)

    return (grids_len, grids)
end

######################################
# Admin functions for testing purposes
######################################

func give_undeployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    to : felt, type : felt, amount : felt):
    alloc_locals

    let (bool_is_utx) = is_device_type_utx (type)

    if bool_is_utx == 1:
        #
        # Give device
        #
        ns_micro_state_functions.fungible_device_undeployed_ledger_write (to, type, amount)

        #
        # Event emission for Apibara
        #
        let (event_counter) = ns_universe_state_functions.event_counter_read ()
        ns_universe_state_functions.event_counter_increment ()
        give_undeployed_fungible_device_occurred.emit (
            event_counter,
            to,
            type,
            amount
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    else:
        let (block_height) = get_block_number ()
        recurse_give_undeployed_device (
            idx = 0,
            len = amount,
            block_height = block_height,
            to = to,
            type = type
        )
        tempvar syscall_ptr = syscall_ptr
        tempvar pedersen_ptr = pedersen_ptr
        tempvar range_check_ptr = range_check_ptr
    end

    return ()
end

func recurse_give_undeployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        idx : felt,
        len : felt,
        block_height : felt,
        to : felt,
        type : felt
    ):
    alloc_locals

    if idx == len:
        return ()
    end

    ## note: create_new_nonfungible_device () emits event for Apibara
    ns_micro_devices.create_new_nonfungible_device (
        block_height = block_height,
        owner = to,
        device_type = type
    )

    #
    # Tail recursion
    #
    recurse_give_undeployed_device (
        idx + 1,
        len,
        block_height,
        to,
        type
    )

    return ()
end