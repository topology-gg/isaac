%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash import hash2

func assert_correct_admin_key {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        admin_key : felt
    ) -> ():
    alloc_locals

    let (hash) = hash2 {hash_ptr = pedersen_ptr} (admin_key, 12345678)

    with_attr error_message ("Key incorrect"):
        assert hash = 1123311700856456447520088966947734763983622271258280925316211858501306616838
    end

    return ()
end
