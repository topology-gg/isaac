%lang starknet

from starkware.cairo.common.alloc import alloc
from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.find_element import search_sorted
from starkware.starknet.common.syscalls import get_caller_address

const N = 2
const GYOZA_ARGENT = 0x077d04506374b4920d6c35ecaded1ed7d26dd283ee64f284481e2574e77852c6
const GYOZA_CLI_0  = 0x0787b926da58c91601b292abc63ed3e36b6afa08d530dcd0b5dfe2d507b84230

func assert_caller_is_whitelisted {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> ():
    alloc_locals

    let (local caller) = get_caller_address ()

    let (arr : felt*) = alloc ()
    assert arr[0] = GYOZA_ARGENT
    assert arr[1] = GYOZA_CLI_0

    let (_, local bool) = search_sorted (
        array_ptr = arr,
        elm_size = 1,
        n_elms = N,
        key = caller
    )

    with_attr error_message ("Caller ({caller}) is not whitelisted"):
        assert bool = 1
    end

    return ()
end
