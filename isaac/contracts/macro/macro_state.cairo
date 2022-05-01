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

namespace ns_macro_state_functions:

    #
    # Getters
    #
    @view
    func phi_curr_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (phi : felt):
        let (phi) = phi_curr.read ()
        return (phi)
    end

    @view
    func macro_state_curr_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (macro_state : Dynamics):
        let (macro_state) = macro_state_curr.read ()
        return (macro_state)
    end

    #
    # Setters
    #
    func phi_curr_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        phi : felt) -> ():
        phi_curr.write (phi)
        return ()
    end

    func macro_state_curr_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        macro_state : Dynamics) -> ():
        macro_state_curr.write (macro_state)
        return ()
    end

end # end namespace
