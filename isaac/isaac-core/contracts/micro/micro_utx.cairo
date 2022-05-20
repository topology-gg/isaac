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
from contracts.micro.micro_state import (
    ns_micro_state_functions,
    GridStat, DeviceDeployedEmapEntry, TransformerResourceBalances, UtxSetDeployedEmapEntry
)
from contracts.micro.micro_devices import (
    ns_micro_devices
)
from contracts.micro.micro_grids import (
    ns_micro_grids
)
from contracts.universe.universe_state import (
    ns_universe_state_functions
)

##############################
## utx
##############################

#
# utx (utb/utl) is fungible before deployment, but non-fungible after deployment,
# because they are deployed as a spatially-contiguous set with the same label,
# where contiguity is defined by the coordinate system on the cube surface;
# they are also deployed exclusively to connect their src & dst devices that meet
# the resource producer-consumer relationship.
#

namespace ns_micro_utx:

    #
    # Player deploys UTX
    # by providing a contiguous set of grids
    #
    func utx_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            utx_device_type : felt,
            locs_len : felt,
            locs : Vec2*,
            src_device_grid : Vec2,
            dst_device_grid : Vec2
        ) -> ():
        alloc_locals

        assert_device_type_is_utx (utx_device_type)

        #
        # Get civilization index
        #
        let (civ_idx) = ns_universe_state_functions.civilization_index_read ()

        #
        # Check if caller owns at least `locs_len` amount of undeployed utx
        #
        let (local owned_utx_amount) = ns_micro_state_functions.device_undeployed_ledger_read (caller, utx_device_type)
        local len = locs_len
        with_attr error_message ("attempt to deploy {len} amount of UTXs but owning only {owned_utx_amount}"):
            assert_le (locs_len, owned_utx_amount)
        end

        #
        # Check if caller owns src and dst device
        #
        let (src_grid_stat) = ns_micro_state_functions.grid_stats_read (civ_idx, src_device_grid)
        let (dst_grid_stat) = ns_micro_state_functions.grid_stats_read (civ_idx, dst_device_grid)
        with_attr error_message ("source-device grid is not populated"):
            assert src_grid_stat.populated = 1
        end
        with_attr error_message ("destination-device grid is not populated"):
            assert dst_grid_stat.populated = 1
        end
        with_attr error_message ("source-device is not owned by caller"):
            assert src_grid_stat.deployed_device_owner = caller
        end
        with_attr error_message ("destination-device is not owned by caller"):
            assert dst_grid_stat.deployed_device_owner = caller
        end

        #
        # Retrieve emap entry for src & dst devices
        #
        let src_device_id = src_grid_stat.deployed_device_id
        let dst_device_id = dst_grid_stat.deployed_device_id
        let (src_emap_index) = ns_micro_state_functions.device_deployed_id_to_emap_index_read (src_device_id)
        let (dst_emap_index) = ns_micro_state_functions.device_deployed_id_to_emap_index_read (dst_device_id)
        let (src_emap_entry) = ns_micro_state_functions.device_deployed_emap_read (src_emap_index)
        let (dst_emap_entry) = ns_micro_state_functions.device_deployed_emap_read (dst_emap_index)

        #
        # Check locs[0] is contiguous to src_device_id's grid using `are_contiguous_grids_given_valid_grids()`
        #
        are_contiguous_grids_given_valid_grids (locs[0], src_device_grid)

        #
        # Check locs[locs_len-1] is contiguous to dst_device_id's grid using `are_contiguous_grids_given_valid_grids()`
        #
        are_contiguous_grids_given_valid_grids (locs[locs_len-1], dst_device_grid)

        #
        # Check the type of (src,dst) meets (producer,consumer) relationship give utx type
        #
        ns_micro_devices.are_producer_consumer_relationship (
            utx_device_type,
            src_grid_stat.deployed_device_type,
            dst_grid_stat.deployed_device_type
        )

        #
        # Recursively check for each locs's grid: (1) grid validity (2) grid unpopulated (3) grid is contiguous to previous grid
        #
        let (utx_idx_start) = ns_micro_state_functions.utx_deployed_index_to_grid_size_read (utx_device_type)
        let utx_idx_end = utx_idx_start + locs_len
        let (block_height) = get_block_number ()
        tempvar data_ptr : felt* = new (4, block_height, caller, utx_idx_start, utx_idx_end)
        let (new_label) = hash_chain {hash_ptr = pedersen_ptr} (data_ptr)
        recurse_utx_deploy (
            caller = caller,
            utx_device_type = utx_device_type,
            len = locs_len,
            arr = locs,
            idx = 0,
            utx_idx = utx_idx_start,
            set_label = new_label,
            civ_idx = civ_idx
        )

        #
        # Decrease caller's undeployed utx amount
        #
        ns_micro_state_functions.device_undeployed_ledger_write (caller, utx_device_type, owned_utx_amount - locs_len)

        #
        # Update `utx_deployed_index_to_grid_size`
        #
        ns_micro_state_functions.utx_deployed_index_to_grid_size_write (utx_device_type, utx_idx_end)

        #
        # Insert to utx_set_deployed_emap; increase emap size
        #
        let (emap_size) = ns_micro_state_functions.utx_set_deployed_emap_size_read (utx_device_type)
        ns_micro_state_functions.utx_set_deployed_emap_write (
            utx_device_type, emap_size,
            UtxSetDeployedEmapEntry(
                utx_set_deployed_label   = new_label,
                utx_deployed_index_start = utx_idx_start,
                utx_deployed_index_end   = utx_idx_end,
                src_device_id = src_device_id,
                dst_device_id = dst_device_id
        ))
        ns_micro_state_functions.utx_set_deployed_emap_size_write (utx_device_type, emap_size + 1)

        #
        # Update label-to-index for O(1) reverse lookup
        #
        ns_micro_state_functions.utx_set_deployed_label_to_emap_index_write (utx_device_type, new_label, emap_size)

        #
        # For src and dst device, update their `utx_tether_count_of_deployed_device` and `utx_tether_labels_of_deployed_device`
        #
        let (count) = ns_micro_state_functions.utx_tether_count_of_deployed_device_read (utx_device_type, src_emap_entry.id)
        ns_micro_state_functions.utx_tether_count_of_deployed_device_write (utx_device_type, src_emap_entry.id, count + 1)
        ns_micro_state_functions.utx_tether_labels_of_deployed_device_write (
            utx_device_type, src_emap_entry.id, count,
            new_label
        )

        let (count) = ns_micro_state_functions.utx_tether_count_of_deployed_device_read (utx_device_type, dst_emap_entry.id)
        ns_micro_state_functions.utx_tether_count_of_deployed_device_write (utx_device_type, dst_emap_entry.id, count + 1)
        ns_micro_state_functions.utx_tether_labels_of_deployed_device_write (
            utx_device_type, dst_emap_entry.id, count,
            new_label
        )

        return ()
    end

    func recurse_utx_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            utx_device_type : felt,
            len : felt,
            arr : Vec2*,
            idx : felt,
            utx_idx : felt,
            set_label : felt,
            civ_idx : felt
        ) -> ():
        alloc_locals

        if idx == len:
            return ()
        end

        #
        # In the following checks, any failure would revert this tx
        #
        # 1. check loc is a valid grid coordinate
        is_valid_grid (arr[idx])

        # 2. check loc is not already populated
        ns_micro_grids.is_unpopulated_grid (civ_idx, arr[idx])

        # 3. check loc is contiguous with previous loc, unless idx==0
        if idx == 0:
            jmp deploy
        end
        with_attr error_message ("recurse_utx_deploy(): grids are not contiguous."):
            are_contiguous_grids_given_valid_grids (arr[idx-1], arr[idx])
        end

        deploy:
        #
        # Update `utx_deployed_index_to_grid`
        #
        ns_micro_state_functions.utx_deployed_index_to_grid_write (utx_device_type, utx_idx, arr[idx])

        #
        # Update global grid_stats ledger
        #
        ns_micro_state_functions.grid_stats_write (
            civ_idx, arr[idx],
            GridStat (
                populated = 1,
                deployed_device_type = utx_device_type,
                deployed_device_id = set_label,
                deployed_device_owner = caller
            )
        )

        recurse_utx_deploy (caller, utx_device_type, len, arr, idx+1, utx_idx+1, set_label, civ_idx)
        return ()
    end

    #
    # Player picks up UTX;
    # given a grid, check its contains caller's own utx, and pick up the entire utx-set
    #
    func utx_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            grid : Vec2
        ) -> ():
        alloc_locals

        #
        # Get civilization index
        #
        let (civ_idx) = ns_universe_state_functions.civilization_index_read ()

        #
        # Check the grid contains an utx owned by caller
        #
        let (grid_stat) = ns_micro_state_functions.grid_stats_read (civ_idx, grid)
        assert grid_stat.populated = 1
        assert grid_stat.deployed_device_owner = caller
        let utx_device_type = grid_stat.deployed_device_type
        assert_device_type_is_utx (utx_device_type)
        let utx_set_deployed_label = grid_stat.deployed_device_id

        #
        # O(1) find the emap_entry for this utx-set
        #
        let (emap_size_curr) = ns_micro_state_functions.utx_set_deployed_emap_size_read (utx_device_type)
        let (emap_index)     = ns_micro_state_functions.utx_set_deployed_label_to_emap_index_read (utx_device_type, utx_set_deployed_label)
        let (emap_entry)     = ns_micro_state_functions.utx_set_deployed_emap_read (utx_device_type, emap_index)
        let utx_start_index = emap_entry.utx_deployed_index_start
        let utx_end_index = emap_entry.utx_deployed_index_end

        #
        # Recurse from start utx-idx to end utx-idx for this set
        # and clear the associated grid
        #
        recurse_pickup_utx_given_start_end_utx_index (
            utx_device_type = utx_device_type,
            start_idx = utx_start_index,
            end_idx = utx_end_index,
            idx = 0,
            civ_idx = civ_idx
        )

        #
        # Return the entire set of utxs back to the caller
        #
        let (amount_curr) = ns_micro_state_functions.device_undeployed_ledger_read (caller, utx_device_type)
        ns_micro_state_functions.device_undeployed_ledger_write (caller, utx_device_type, amount_curr + utx_end_index - utx_start_index)

        #
        # Update enumerable map of utx-sets:
        # removal operation - put last entry to index at removed entry, clear index at last entry,
        # and decrease emap size by one
        #
        let (emap_entry_last) = ns_micro_state_functions.utx_set_deployed_emap_read (utx_device_type, emap_size_curr - 1)
        ns_micro_state_functions.utx_set_deployed_emap_write (utx_device_type, emap_index, emap_entry_last)
        ns_micro_state_functions.utx_set_deployed_emap_write (utx_device_type, emap_size_curr - 1, UtxSetDeployedEmapEntry (0,0,0,0,0))
        ns_micro_state_functions.utx_set_deployed_emap_size_write (utx_device_type, emap_size_curr - 1)

        #
        # Update `utx_tether_count_of_deployed_device` and `utx_tether_labels_of_deployed_device` for both src and dst device
        #
        let (tether_count) = ns_micro_state_functions.utx_tether_count_of_deployed_device_read (utx_device_type, emap_entry.src_device_id)
        ns_micro_state_functions.utx_tether_count_of_deployed_device_write (utx_device_type, emap_entry.src_device_id, tether_count - 1)
        ns_micro_state_functions.utx_tether_labels_of_deployed_device_write (utx_device_type, emap_entry.src_device_id, tether_count - 1, 0)

        let (tether_count) = ns_micro_state_functions.utx_tether_count_of_deployed_device_read (utx_device_type, emap_entry.dst_device_id)
        ns_micro_state_functions.utx_tether_count_of_deployed_device_write (utx_device_type, emap_entry.dst_device_id, tether_count - 1)
        ns_micro_state_functions.utx_tether_labels_of_deployed_device_write (utx_device_type, emap_entry.dst_device_id, tether_count - 1, 0)

        return ()
    end

    func recurse_pickup_utx_given_start_end_utx_index {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt,
            start_idx : felt,
            end_idx : felt,
            idx : felt,
            civ_idx : felt
        ) -> ():
        alloc_locals

        if start_idx + idx == end_idx:
            return ()
        end

        let (grid_to_clear) = ns_micro_state_functions.utx_deployed_index_to_grid_read (utx_device_type, start_idx + idx)
        ns_micro_state_functions.grid_stats_write (
            civ_idx, grid_to_clear,
            GridStat(0,0,0,0)
        )

        recurse_pickup_utx_given_start_end_utx_index (utx_device_type, start_idx, end_idx, idx + 1, civ_idx)
        return()
    end

    #
    # Tether utx-set to src and device manually;
    # useful when player wants to re-tether a deployed utx-set to new devices
    # instead of having to pick up and redeploy the utx-set
    #
    func utx_tether_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            caller : felt,
            utx_device_type : felt,
            utx_grid : Vec2,
            src_device_grid : Vec2,
            dst_device_grid : Vec2
        ) -> ():

        with_attr error_message ("Not implemented."):
            assert 1 = 0
        end

        return ()
    end

end # end namespace
