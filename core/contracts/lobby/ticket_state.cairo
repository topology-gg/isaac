%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)


@storage_var
func account_has_invitation (account : felt) -> (bool : felt):
end

@storage_var
func s2m2_address () -> (address : felt):
end

namespace ns_ticket_state:

    #
    # Getters
    #
    @view
    func account_has_invitation_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            account : felt
        ) -> (
            bool : felt
        ):

        let (bool) = account_has_invitation.read (account)

        return (bool)
    end

    @view
    func s2m2_address_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> (address : felt):

        let (address) = s2m2_address.read ()

        return (address)
    end

    #
    # Setters
    #
    func account_has_invitation_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            account : felt,
            bool : felt
        ) -> ():

        account_has_invitation.write (account, bool)

        return ()
    end

    func s2m2_address_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        address : felt) -> ():

        s2m2_address.write (address)

        return ()
    end

end # end namespace
