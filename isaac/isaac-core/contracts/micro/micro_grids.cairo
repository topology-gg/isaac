%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.util.structs import (
    Vec2
)
from contracts.micro.micro_state import (
    ns_micro_state_functions,
    GridStat
)
from contracts.util.distribution import (
    ns_distribution
)

##############################

namespace ns_micro_grids:

    func is_unpopulated_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (grid : Vec2) -> ():
        alloc_locals

        let (grid_stat : GridStat) = ns_micro_state_functions.grid_stats_read (grid)
        local g : Vec2 = grid

        with_attr error_message ("grid ({g.x}, {g.y}) is already populated"):
            assert grid_stat.populated = 0
        end

        return ()
    end

    #
    # Make this function static i.e. not shifting over time due to geological events, not depleting due to harvest activities;
    # instead of initializing this value at civilization start and store it persistently, we choose to recompute the number everytime,
    # to (1) reduce compute requirement at civ start (2) trade storage with compute (3) allows for dynamic concentration later on.
    # note: if desirable, this function can be replicated as-is in frontend (instead of polling contract from starknet) to compute only-once
    # the distribution of concentration value per resource type per grid
    #
    func get_resource_concentration_at_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            grid : Vec2, resource_type : felt
        ) -> (resource_concentration : felt):
        alloc_locals

        # Requirement 1 / have a different distribution per resource type
        # Requirement 2 / design shape & amplitudes of distribution for specific resources e.g. plutonium-241 for game design purposes
        # Requirement 3 / expose parameters controlling these distributions as constants in `contracts.design.constants` for easier tuning
        # Requirement 4 / deal with fixed-point representation for concentration values

        let (resource_concentration) = ns_distribution.get_concentration_at_grid_given_element_type (
            grid,
            resource_type
        )

        return (resource_concentration)
    end

end # end namespace