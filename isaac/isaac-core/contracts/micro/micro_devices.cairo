%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    ns_device_types, assert_device_type_is_utx,
    harvester_device_type_to_element_type,
    transformer_device_type_to_element_types,
    get_device_dimension_ptr
)
from contracts.util.structs import (
    Vec2
)
from contracts.util.distribution import (
    ns_distribution
)
from contracts.util.grid import (
    is_valid_grid, are_contiguous_grids_given_valid_grids,
    locate_face_and_edge_given_valid_grid,
    is_zero
)
from contracts.util.logistics import (
    ns_logistics_harvester, ns_logistics_transformer,
    ns_logistics_xpg, ns_logistics_utb, ns_logistics_utl
)
from contracts.util.manufacturing import (
    ns_manufacturing
)
from contracts.micro.micro_state import (
    ns_micro_state_functions,
    GridStat, DeviceDeployedEmapEntry, TransformerResourceBalances, UtxSetDeployedEmapEntry
)

##############################
## Devices (including opsf)
##############################

namespace ns_micro_devices:

    func assert_device_footprint_populable {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            type : felt, grid : Vec2
        ):
        alloc_locals

        #
        # for given device type, confirm the underlying grid(s) lie on the same face and are unpopulated
        # TODO: consider refactor this into constants.cairo, but need to encapsulate information of shape
        #       because constants.cairo does not have access to the storage_var `grid_stats` here
        #

        let (dim_ptr) = get_device_dimension_ptr ()
        let device_dim = dim_ptr [type]
        let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)

        #
        # Check 1x1
        #
        assert_valid_unpopulated_and_same_face (grid, face)

        if device_dim == 1:
            return ()
        end

        #
        # Check 2x2
        #
        let grid_ = Vec2 (grid.x + 1, grid.y)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 1, grid.y + 1)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x, grid.y + 1)
        assert_valid_unpopulated_and_same_face (grid_, face)

        if device_dim == 2:
            return ()
        end

        #
        # Check 3x3
        #
        let grid_ = Vec2 (grid.x + 2, grid.y)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 2, grid.y + 1)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 2, grid.y + 2)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 1, grid.y + 2)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x, grid.y + 2)
        assert_valid_unpopulated_and_same_face (grid_, face)

        if device_dim == 3:
            return ()
        end

        #
        # Check 5x5
        #
        let grid_ = Vec2 (grid.x + 3, grid.y)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 3, grid.y + 1)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 3, grid.y + 2)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 3, grid.y + 3)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 2, grid.y + 3)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 1, grid.y + 3)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x, grid.y + 3)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 4, grid.y)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 4, grid.y + 1)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 4, grid.y + 2)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 4, grid.y + 3)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 4, grid.y + 4)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 3, grid.y + 4)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 2, grid.y + 4)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x + 1, grid.y + 4)
        assert_valid_unpopulated_and_same_face (grid_, face)

        let grid_ = Vec2 (grid.x, grid.y + 4)
        assert_valid_unpopulated_and_same_face (grid_, face)

        return ()
    end

    func assert_valid_unpopulated_and_same_face {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            grid : Vec2, face_tgt : felt
        ) -> ():
        alloc_locals

        is_valid_grid (grid)

        let (grid_stat) = ns_micro_state_functions.grid_stats_read (grid)
        assert grid_stat.populated = 0

        let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)
        assert face = face_tgt

        return ()
    end

    func update_grid_with_new_grid_stat {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            type : felt, grid : Vec2, grid_stat : GridStat
        ) -> ():
        alloc_locals

        let (dim_ptr) = get_device_dimension_ptr ()
        let device_dim = dim_ptr [type]

        #
        # 1x1
        #
        ns_micro_state_functions.grid_stats_write (grid, grid_stat)

        if device_dim == 1:
            return ()
        end

        #
        # 2x2
        #
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 1, grid.y), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 1, grid.y + 1), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x, grid.y + 1), grid_stat)

        if device_dim == 2:
            return ()
        end

        #
        # 3x3
        #
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 2, grid.y), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 2, grid.y + 1), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 2, grid.y + 2), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 1, grid.y + 2), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x, grid.y + 2), grid_stat)

        if device_dim == 3:
            return ()
        end

        #
        # 5x5
        #
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 3, grid.y), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 3, grid.y + 1), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 3, grid.y + 2), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 3, grid.y + 3), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 2, grid.y + 3), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 1, grid.y + 3), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x, grid.y + 3), grid_stat)

        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 4, grid.y), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 4, grid.y + 1), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 4, grid.y + 2), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 4, grid.y + 3), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 4, grid.y + 4), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 3, grid.y + 4), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 2, grid.y + 4), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x + 1, grid.y + 4), grid_stat)
        ns_micro_state_functions.grid_stats_write (Vec2 (grid.x, grid.y + 4), grid_stat)

        return ()
    end

    func device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            type : felt,
            grid : Vec2
        ) -> ():
        alloc_locals

        #
        # Check if caller owns at least 1 undeployed device of type `type`
        #
        let (amount_curr) = ns_micro_state_functions.device_undeployed_ledger_read (caller, type)
        assert_nn (amount_curr - 1)

        #
        # Check if this device can be deployed with the origin of its footprint at `grid`
        #
        assert_device_footprint_populable (type, grid)

        #
        # Create new device id
        #
        tempvar data_ptr : felt* = new (4, caller, type, grid.x, grid.y)
        let (new_id) = hash_chain {hash_ptr = pedersen_ptr} (data_ptr)

        #
        # Update `grid_stats` at grid(s)
        #
        let new_grid_stat = GridStat(
            populated = 1,
            deployed_device_type = type,
            deployed_device_id =  new_id,
            deployed_device_owner = caller
        )
        update_grid_with_new_grid_stat (type, grid, new_grid_stat)

        #
        # Update `device_deployed_emap`
        #
        let (emap_size_curr) = ns_micro_state_functions.device_deployed_emap_size_read ()
        ns_micro_state_functions.device_deployed_emap_size_write (emap_size_curr + 1)
        ns_micro_state_functions.device_deployed_emap_write (emap_size_curr, DeviceDeployedEmapEntry(
            grid = grid,
            type = type,
            id = new_id,
        ))

        #
        # Update `device_deployed_id_to_emap_index`
        #
        ns_micro_state_functions.device_deployed_id_to_emap_index_write (new_id, emap_size_curr)

        #
        # Update `device_undeployed_ledger`: subtract by 1
        #
        ns_micro_state_functions.device_undeployed_ledger_write (caller, type, amount_curr - 1)

        return ()
    end

    func recurse_untether_utx_for_deployed_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt,
            id : felt,
            len : felt,
            idx : felt
        ) -> ():
        alloc_locals

        if idx == len:
            return ()
        end

        #
        # Get utx-set label at current idx
        #
        let (utx_set_label) = ns_micro_state_functions.utx_tether_labels_of_deployed_device_read (utx_device_type, id, idx)

        #
        # With the utx-set label, get its emap-index, then get its emap-entry
        #
        let (utx_set_emap_index) = ns_micro_state_functions.utx_set_deployed_label_to_emap_index_read (utx_device_type, utx_set_label)
        let (utx_set_emap_entry) = ns_micro_state_functions.utx_set_deployed_emap_read (utx_device_type, utx_set_emap_index)

        #
        # Construct new src & dst device id based on whether the device is this utx-set's src or dst device
        #
        let (is_src_device) = is_zero (utx_set_emap_entry.src_device_id - id)
        let (is_dst_device) = is_zero (utx_set_emap_entry.dst_device_id - id)
        let new_src_device_id = (1-is_src_device) * utx_set_emap_entry.src_device_id
        let new_dst_device_id = (1-is_dst_device) * utx_set_emap_entry.dst_device_id

        #
        # Update utx emap
        #
        ns_micro_state_functions.utx_set_deployed_emap_write (
            utx_device_type, utx_set_emap_index,
            UtxSetDeployedEmapEntry(
                utx_set_deployed_label   = utx_set_emap_entry.utx_set_deployed_label,
                utx_deployed_index_start = utx_set_emap_entry.utx_deployed_index_start,
                utx_deployed_index_end   = utx_set_emap_entry.utx_deployed_index_end,
                src_device_id = new_src_device_id,
                dst_device_id = new_dst_device_id
            )
        )

        recurse_untether_utx_for_deployed_device (utx_device_type, id, len, idx + 1)

        return ()
    end

    func device_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            grid : Vec2
        ) -> ():
        alloc_locals

        #
        # Check if caller owns the device on `grid`
        #
        let (grid_stat) = ns_micro_state_functions.grid_stats_read (grid)
        assert grid_stat.populated = 1
        assert grid_stat.deployed_device_owner = caller

        #
        # Update `device_deployed_emap`
        #
        let (emap_index)      = ns_micro_state_functions.device_deployed_id_to_emap_index_read (grid_stat.deployed_device_id)
        let (emap_size_curr)  = ns_micro_state_functions.device_deployed_emap_size_read ()
        let (emap_entry)      = ns_micro_state_functions.device_deployed_emap_read (emap_index)
        let (emap_entry_last) = ns_micro_state_functions.device_deployed_emap_read (emap_size_curr - 1)
        ns_micro_state_functions.device_deployed_emap_size_write (
            emap_size_curr - 1
        )
        ns_micro_state_functions.device_deployed_emap_write (
            emap_size_curr - 1,
            DeviceDeployedEmapEntry(
                Vec2(0,0), 0, 0
            )
        )
        ns_micro_state_functions.device_deployed_emap_write (emap_index, emap_entry_last)
        let grid_0_0 = emap_entry.grid
        let type = emap_entry.type

        #
        # Update `device_deployed_id_to_emap_index`
        #
        let id_moved = emap_entry_last.id
        ns_micro_state_functions.device_deployed_id_to_emap_index_write (id_moved, emap_index)

        #
        # Untether all utx-sets tethered to this device
        #
        let (utb_tether_count) = ns_micro_state_functions.utx_tether_count_of_deployed_device_read (ns_device_types.DEVICE_UTB, grid_stat.deployed_device_id)
        recurse_untether_utx_for_deployed_device (
            utx_device_type = ns_device_types.DEVICE_UTB,
            id = grid_stat.deployed_device_id,
            len = utb_tether_count,
            idx = 0
        )

        let (utl_tether_count) = ns_micro_state_functions.utx_tether_count_of_deployed_device_read (ns_device_types.DEVICE_UTL, grid_stat.deployed_device_id)
        recurse_untether_utx_for_deployed_device (
            utx_device_type = ns_device_types.DEVICE_UTL,
            id = grid_stat.deployed_device_id,
            len = utl_tether_count,
            idx = 0
        )

        update_devices:
        local syscall_ptr : felt* = syscall_ptr
        local pedersen_ptr : HashBuiltin* = pedersen_ptr
        local range_check_ptr = range_check_ptr
        #
        # Clear entry in device-id to resource-balance lookup
        #
        let (bool_is_harvester) = is_device_harvester (grid_stat.deployed_device_type)
        let (bool_is_transformer) = is_device_transformer (grid_stat.deployed_device_type)

        check_harvesters:
        tempvar bool_is_harvester_minus_one = bool_is_harvester - 1
        jmp check_transformers if bool_is_harvester_minus_one != 0

        ns_micro_state_functions.harvesters_deployed_id_to_resource_balance_write (
            grid_stat.deployed_device_id,
            0
        )
        jmp recycle

        check_transformers:
        if bool_is_transformer == 1:
            ns_micro_state_functions.transformers_deployed_id_to_resource_balances_write (
                grid_stat.deployed_device_id,
                TransformerResourceBalances (0,0)
            )
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        recycle:
        #
        # Recycle device back to caller
        #
        let (amount_curr) = ns_micro_state_functions.device_undeployed_ledger_read (caller, grid_stat.deployed_device_type)
        ns_micro_state_functions.device_undeployed_ledger_write (caller, grid_stat.deployed_device_type, amount_curr + 1)

        update_grid_stat:
        update_grid_with_new_grid_stat (type, grid_0_0, GridStat(
            populated = 0,
            deployed_device_type = 0,
            deployed_device_id = 0,
            deployed_device_owner = 0
        ))

        return ()
    end

    func opsf_build_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            grid : Vec2,
            device_type : felt,
            device_count : felt
        ) -> ():
        alloc_locals

        #
        # Check if `caller` owns the device at `opsf_grid`
        #
        let (grid_stat) = ns_micro_state_functions.grid_stats_read (grid)
        assert grid_stat.populated = 1
        assert grid_stat.deployed_device_owner = caller

        #
        # Check if an OPSF is deployed at `opsf_grid`
        #
        assert grid_stat.deployed_device_type = ns_device_types.DEVICE_OPSF
        let opsf_device_id = grid_stat.deployed_device_id

        #
        # Get resource & energy requirement for manufacturing one device of type `device_type`
        #
        let (
            energy : felt,
            resource_arr_len : felt,
            resource_arr : felt*
        ) = ns_manufacturing.get_resource_energy_requirement_given_device_type (
            device_type
        )
        local energy_should_consume = energy * device_count

        #
        # Consume opsf energy; revert if insufficient
        #
        let (local curr_energy) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (opsf_device_id)
        with_attr error_message ("insufficient energy; {energy_should_consume} required, {curr_energy} available at OPSF."):
            assert_le (energy_should_consume, curr_energy)
        end
        ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
            opsf_device_id,
            curr_energy - energy_should_consume
        )

        #
        # Recurse update resource balance at this OPSF; revert if any balance is insufficient
        #
        recurse_consume_device_balance_at_opsf (
            opsf_device_id = opsf_device_id,
            device_count = device_count,
            len = resource_arr_len,
            arr = resource_arr,
            idx = 0
        )

        #
        # If both resource & energy update above are successful, give devices to caller
        #
        let (curr_amount) = ns_micro_state_functions.device_undeployed_ledger_read (caller, device_type)
        ns_micro_state_functions.device_undeployed_ledger_write (
            caller, device_type,
            curr_amount + device_count
        )

        return ()
    end

    func recurse_consume_device_balance_at_opsf {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            opsf_device_id : felt,
            device_count : felt,
            len : felt,
            arr : felt*,
            idx : felt
        ) -> ():
        alloc_locals

        if idx == len:
            return ()
        end

        #
        # Check if opsf has sufficient resource balance of this type
        #
        let (local curr_balance) = ns_micro_state_functions.opsf_deployed_id_to_resource_balances_read (
            opsf_device_id, idx
        )
        local quantity_should_consume = arr[idx] * device_count

        local element_type = idx
        with_attr error_message ("insufficient quantity of type {element_type}; {quantity_should_consume} required, {curr_balance} available at OPSF."):
            assert_le (quantity_should_consume, curr_balance)
        end

        #
        # Update opsf's resource balance of this type
        #
        ns_micro_state_functions.opsf_deployed_id_to_resource_balances_write (
            opsf_device_id, idx,
            curr_balance - quantity_should_consume
        )

        #
        # Tail recursion
        #
        recurse_consume_device_balance_at_opsf (
            opsf_device_id,
            device_count,
            len,
            arr,
            idx + 1
        )
        return ()
    end

    func launch_all_deployed_ndpe {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            grid : Vec2
        ) -> (
            impulse_to_planet : Vec2
        ):
        alloc_locals

        #
        # Check if `caller` owns the device at `opsf_grid`
        #
        let (grid_stat) = ns_micro_state_functions.grid_stats_read (grid)
        assert grid_stat.populated = 1
        assert grid_stat.deployed_device_owner = caller

        #
        # Check if an NDPE is deployed at `opsf_grid`
        #
        assert grid_stat.deployed_device_type = ns_device_types.DEVICE_NDPE
        let ndpe_device_id = grid_stat.deployed_device_id

        #
        # Loop over all deployed NDPEs
        #
        # TODO

        let impulse_to_planet : Vec2 = Vec2 (0,0)

        return (impulse_to_planet)
    end

    func are_producer_consumer_relationship {range_check_ptr} (
        utx_device_type, device_type0, device_type1) -> ():

        # TODO: refactor this code to improve extensibility

        alloc_locals
        # upgrade input to local for error-message accessibility
        local x = device_type0
        local y = device_type1
        local z = utx_device_type


        if utx_device_type == ns_device_types.DEVICE_UTB:
            #
            # From harvester to corresponding refinery / enrichment facility
            #
            # iron harvester => iron refinery
            if (device_type0 - ns_device_types.DEVICE_FE_HARV + 1) * (device_type1 - ns_device_types.DEVICE_FE_REFN + 1) == 1:
                return ()
            end

            # aluminum harvester => aluminum refinery
            if (device_type0 - ns_device_types.DEVICE_AL_HARV + 1) * (device_type1 - ns_device_types.DEVICE_AL_REFN + 1) == 1:
                return ()
            end

            # copper harvester => copper refinery
            if (device_type0 - ns_device_types.DEVICE_CU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_CU_REFN + 1) == 1:
                return ()
            end

            # silicon harvester => silicon refinery
            if (device_type0 - ns_device_types.DEVICE_SI_HARV + 1) * (device_type1 - ns_device_types.DEVICE_SI_REFN + 1) == 1:
                return ()
            end

            # plutonium harvester => plutonium enrichment facility
            if (device_type0 - ns_device_types.DEVICE_PU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_PEF + 1) == 1:
                return ()
            end

            #
            # From harvester straight to OPSF
            #
            # iron harvester => OPSF
            if (device_type0 - ns_device_types.DEVICE_FE_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # aluminum harvester => OPSF
            if (device_type0 - ns_device_types.DEVICE_AL_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # copper harvester => OPSF
            if (device_type0 - ns_device_types.DEVICE_CU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # silicon harvester => OPSF
            if (device_type0 - ns_device_types.DEVICE_SI_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # plutonium harvester => OPSF
            if (device_type0 - ns_device_types.DEVICE_PU_HARV + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            #
            # From refinery/enrichment facility to OPSF
            #
            # iron refinery => OPSF
            if (device_type0 - ns_device_types.DEVICE_FE_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # aluminum refinery => OPSF
            if (device_type0 - ns_device_types.DEVICE_AL_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # copper refinery => OPSF
            if (device_type0 - ns_device_types.DEVICE_CU_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # silicon refinery => OPSF
            if (device_type0 - ns_device_types.DEVICE_SI_REFN + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            # plutonium enrichment facility => OPSF
            if (device_type0 - ns_device_types.DEVICE_PEF + 1) * (device_type1 - ns_device_types.DEVICE_OPSF + 1) == 1:
                return ()
            end

            tempvar range_check_ptr = range_check_ptr
        else:
            ## UTL

            #
            # SPG / NPG => any of the devices;
            # meaning device_type0 needs to be power generator (pg) :: {0, 1}
            # and device_type1 needs to be power consumer (pc) :: {2, 3 ... 14}
            #

            let (is_device_type0_pg) = is_nn_le (device_type0, 1)
            let (is_device_type1_pc) = is_nn_le (device_type1 - 2, 12)
            if is_device_type0_pg * is_device_type1_pc == 1:
                return ()
            end

            tempvar range_check_ptr = range_check_ptr
        end

        with_attr error_message("resource producer-consumer relationship check failed, with utx_device_type = {z}, device_type0 = {x} and device_type1 = {y}"):
            assert 1 = 0
        end
        return ()
    end

    func is_device_harvester {range_check_ptr} (type : felt) -> (bool : felt):
        let (bool) = is_nn_le (
            type - ns_device_types.DEVICE_HARVESTER_MIN,
            ns_device_types.DEVICE_HARVESTER_MAX - ns_device_types.DEVICE_HARVESTER_MIN
        )
        return (bool)
    end

    func is_device_transformer {range_check_ptr} (type : felt) -> (bool : felt):
        let (bool) = is_nn_le (
            type - ns_device_types.DEVICE_TRANSFORMER_MIN,
            ns_device_types.DEVICE_TRANSFORMER_MAX - ns_device_types.DEVICE_TRANSFORMER_MIN
        )
        return (bool)
    end

    func is_device_opsf {range_check_ptr} (type : felt) -> (bool : felt):
        if type == ns_device_types.DEVICE_OPSF:
            return (1)
        else:
            return (0)
        end
    end

end # end namespace