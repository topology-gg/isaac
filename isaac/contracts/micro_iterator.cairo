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
from contracts.micro_state import (
    ns_micro_state_functions,
    GridStat, DeviceDeployedEmapEntry, TransformerResourceBalances, UtxSetDeployedEmapEntry
)

#####################################
## Iterators for client view purposes
#####################################

namespace ns_micro_iterator:

    #
    # Iterating over device emap
    #
    func iterate_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (
            emap_len : felt,
            emap : DeviceDeployedEmapEntry*
        ):
        alloc_locals

        let (emap_size) = ns_micro_state_functions.device_deployed_emap_size_read ()
        let (emap : DeviceDeployedEmapEntry*) = alloc ()

        recurse_traverse_device_deployed_emap (emap_size, emap, 0)

        return (emap_size, emap)
    end

    func recurse_traverse_device_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len : felt,
        arr : DeviceDeployedEmapEntry*,
        idx : felt) -> ():

        if idx == len:
            return ()
        end

        let (emap_entry) = ns_micro_state_functions.device_deployed_emap_read (idx)
        assert arr[idx] = emap_entry

        recurse_traverse_device_deployed_emap (len, arr, idx+1)

        return ()
    end

    #
    # Iterating over utx emap
    #
    func iterate_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt
        ) -> (
            emap_len : felt,
            emap : UtxSetDeployedEmapEntry*
        ):
        alloc_locals

        let (emap_size) = ns_micro_state_functions.utx_set_deployed_emap_size_read (utx_device_type)
        let (emap : UtxSetDeployedEmapEntry*) = alloc ()

        recurse_traverse_utx_deployed_emap (utx_device_type, emap_size, emap, 0)

        return (emap_size, emap)
    end

    func recurse_traverse_utx_deployed_emap {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt,
            len : felt,
            arr : UtxSetDeployedEmapEntry*,
            idx : felt
        ) -> ():

        if idx == len:
            return ()
        end

        let (emap_entry) = ns_micro_state_functions.utx_set_deployed_emap_read (utx_device_type, idx)
        assert arr[idx] = emap_entry

        recurse_traverse_utx_deployed_emap (utx_device_type, len, arr, idx+1)

        return ()
    end

    #
    # Iterating over utx emap, return grids
    #
    func iterate_utx_deployed_emap_grab_all_utxs {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt
        ) -> (
            grids_len : felt,
            grids : Vec2*
        ):
        alloc_locals

        #
        # Double recursion:
        # recurse over utx-deployed emap,
        # then for each entry, recurse from index start to index end to grab the grids
        # return one big array of grids
        #

        let (grids : Vec2*) = alloc ()
        let (outer_loop_len) = ns_micro_state_functions.utx_set_deployed_emap_size_read (utx_device_type)
        let (count_final) = recurse_outer_grab_utxs (
            utx_device_type = utx_device_type,
            len = outer_loop_len,
            idx = 0,
            arr = grids,
            count = 0
        )

        return (count_final, grids)
    end

    func recurse_outer_grab_utxs {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt,
            len : felt,
            idx : felt,
            arr : Vec2*,
            count : felt
        ) -> (
            count_final : felt
        ):
        alloc_locals

        if idx == len:
            return (count)
        end

        #
        # inner recursion
        #
        let (emap_entry)  = ns_micro_state_functions.utx_set_deployed_emap_read (utx_device_type, idx)
        let utx_idx_start = emap_entry.utx_deployed_index_start
        let utx_idx_end   = emap_entry.utx_deployed_index_end

        with_attr error_message ("utx_idx_start should not equal to utx_idx_end for any utx emap entry."):
            assert_not_equal (utx_idx_start, utx_idx_end)
        end

        recurse_inner_grab_utxs (
            utx_device_type = utx_device_type,
            idx_start = utx_idx_start,
            idx_end = utx_idx_end,
            off = 0,
            arr = arr
        )

        #
        # tail recursion
        #
        let (count_final) = recurse_outer_grab_utxs (
            utx_device_type,
            len,
            idx + 1,
            &arr [utx_idx_end - utx_idx_start],
            count + utx_idx_end - utx_idx_start
        )
        return (count_final)
    end

    func recurse_inner_grab_utxs {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            utx_device_type : felt,
            idx_start : felt,
            idx_end : felt,
            off : felt,
            arr : Vec2*
        ) -> ():
        alloc_locals

        if idx_start + off == idx_end:
            return ()
        end

        let (grid : Vec2) = ns_micro_state_functions.utx_deployed_index_to_grid_read (utx_device_type, idx_start + off)

        local offset = off
        with_attr error_message ("`arr` at {offset} already occupied."):
            assert arr[off] = grid
        end

        recurse_inner_grab_utxs (
            utx_device_type,
            idx_start,
            idx_end,
            off + 1,
            arr
        )
        return ()
    end

end # end namespace
