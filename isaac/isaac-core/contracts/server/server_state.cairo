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
    GYOZA, MIN_L2_BLOCK_NUM_BETWEEN_FORWARD,
    ns_macro_init
)
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)

@storage_var
func l2_block_at_last_forward () -> (block_num : felt):
end

namespace ns_server_state_functions:

    #
    # Getters
    #
    @view
    func l2_block_at_last_forward_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (block_num : felt):

        let (block_num) = l2_block_at_last_forward.read ()

        return (block_num)
    end

    #
    # Setters
    #
    func l2_block_at_last_forward_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        block_num : felt) -> ():

        l2_block_at_last_forward.write (block_num)

        return ()
    end

end # end namespace
