# https://github.com/marcellobardus/starknet-l2-storage-verifier/blob/master/contracts/starknet/lib/concat_arr.cairo
# https://github.com/sekai-studio/starknet-libs/blob/main/cairo_string/Array.cairo

from starkware.cairo.common.memcpy import memcpy
from starkware.cairo.common.alloc import alloc

func array_concat {range_check_ptr} (
        arr1_len : felt,
        arr1 : felt*,
        arr2_len : felt,
        arr2 : felt*
    ) -> (
        res_len : felt,
        res : felt*
    ):
    alloc_locals

    let (local res : felt*) = alloc()
    memcpy(res, arr1, arr1_len)
    memcpy(res + arr1_len, arr2, arr2_len)

    return (arr1_len + arr2_len, res)
end