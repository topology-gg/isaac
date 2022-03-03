%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from examples.libs.Str import (Str, str_concat, str_concat_array, str_from_literal, str_empty)

const P_OPEN = '<p>'
const P_CLOSE = '</p>'

#
# Convert a provided 2d string array into html table encoded as felt array;
# arr_str is 2d table flattned to 1d array through concatenating rows
#
func convert_str_array_to_html_string {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_str_len : felt,
        arr_str : Str*
    ) -> (
        arr_len : felt,
        arr : felt*
    ):
    alloc_locals

    let (wrapped_paragraphs : Str) = wrap_p (arr_str_len, arr_str)

    return (wrapped_paragraphs.arr_len, wrapped_paragraphs.arr)
end


func wrap_p {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_str_len : felt,
        arr_str : Str*
    ) -> (
        res : Str
    ):

    let (res_init : Str) = str_empty()
    let (res : Str) = _recurse_wrap_p (
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        res = res_init,
        idx = 0
    )

    return (res)

end


func _recurse_wrap_p {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_str_len : felt,
        arr_str : Str*,
        res : Str,
        idx : felt
    ) -> (
        res_final : Str
    ):
    alloc_locals

    if idx == arr_str_len:
        return (res)
    end

    #
    # Sandwhich string with opening and closing p tag
    #
    let (p_open_str) = str_from_literal (P_OPEN)
    let (p_close_str) = str_from_literal (P_CLOSE)
    let (res_with_p_open) = str_concat (res, p_open_str)
    let (res_with_str) = str_concat (res_with_p_open, arr_str[idx])
    let (res_with_p_close) = str_concat (res_with_str, p_close_str)

    #
    # Tail recursion
    #
    let (res_final : Str) = _recurse_wrap_p (
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        res = res_with_p_close,
        idx = idx + 1
    )
    return (res_final)
end
