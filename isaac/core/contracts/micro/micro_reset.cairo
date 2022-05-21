%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    ns_device_types,
    CIV_SIZE
)
from contracts.micro.micro_state import (
    ns_micro_state_functions
)
from contracts.universe.universe_state import (
    ns_universe_state_functions
)

namespace ns_micro_reset:

    func reset_world_micro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> ():
        alloc_locals

        ## Note: we are not reseting any storage whose input keys involved deployed-device-id or utx-label,
        ## because both deployed-device-id or utx-label are created with block-number, which is guaranteed to
        ## differ across civilizations, so we can get away with not reseting these mapping -- there's 0% chance
        ## new civilization will create id or label that collide with ids and labels from older civilizations

        ## Note: we also do not reset `grid_stats`, instead we let it freezes at the end of a civilization;
        ## `grid_stats` takes civilization index as its first input argument, so grid status will not collide
        ## across civilizations

        recurse_over_address_reset_device_undeployed_ledger (0) # for each player in civilization: for each type, set amount to 0

        ns_micro_state_functions.device_deployed_emap_size_write (0)

        ns_micro_state_functions.utx_set_deployed_emap_size_write (ns_device_types.DEVICE_UTB, 0)
        ns_micro_state_functions.utx_set_deployed_emap_size_write (ns_device_types.DEVICE_UTL, 0)

        ns_micro_state_functions.utx_deployed_index_to_grid_size_write (ns_device_types.DEVICE_UTB, 0)
        ns_micro_state_functions.utx_deployed_index_to_grid_size_write (ns_device_types.DEVICE_UTL, 0)

        return ()
    end

    func recurse_over_address_reset_device_undeployed_ledger {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            idx : felt
        ) -> ():
        alloc_locals

        if idx == CIV_SIZE:
            return ()
        end

        #
        # Get player address and recurse over all device types for it
        #
        let (player_address) = ns_universe_state_functions.civilization_player_idx_to_address_read (idx)
        recurse_over_device_type_given_address_reset_device_undeployed_ledger (
            player_address,
            0
        )

        #
        # Tail recursion
        #
        recurse_over_address_reset_device_undeployed_ledger (
            idx + 1
        )
        return ()
    end

    func recurse_over_device_type_given_address_reset_device_undeployed_ledger {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            player_address : felt,
            device_type : felt
        ) -> ():
        alloc_locals

        if device_type == ns_device_types.DEVICE_TYPE_COUNT:
            return ()
        end

        #
        # Reset entry at ledger
        #
        ns_micro_state_functions.device_undeployed_ledger_write (player_address, device_type, 0)

        #
        # Tail recursion
        #
        recurse_over_device_type_given_address_reset_device_undeployed_ledger (
            player_address,
            device_type + 1
        )
        return ()
    end

end # end namespace
