%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from examples.libs.Str import (Str, str_concat, str_concat_array, str_from_literal, str_empty)

const TABLE_OPEN = '<table>'
const TABLE_CLOSE = '</table>'
const TR_OPEN = '<tr>'
const TR_CLOSE = '</tr>'
const TD_OPEN = '<td>'
const TD_CLOSE = '</td>'

#
# Convert a provided 2d string array into html table encoded as felt array;
# arr_str is 2d table flattned to 1d array through concatenating rows
#
func convert_str_table_to_html_string {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        row_cnt : felt,
        col_cnt : felt,
        arr_str_len : felt,
        arr_str : Str*
    ) -> (
        arr_len : felt,
        arr : felt*
    ):
    alloc_locals

    let (content_str : Str) = wrap_tr_td (row_cnt, col_cnt, arr_str_len, arr_str)

    #
    # Sandwich with opening and closing table tag
    #
    let (table_open_str) = str_from_literal (TABLE_OPEN)
    let (table_close_str) = str_from_literal (TABLE_CLOSE)
    let (wrapped_table_str_ : Str) = str_concat (table_open_str, content_str)
    let (wrapped_table_str : Str) = str_concat (wrapped_table_str_, table_close_str)

    return (wrapped_table_str.arr_len, wrapped_table_str.arr)
end


func wrap_tr_td {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        row_cnt : felt,
        col_cnt : felt,
        arr_str_len : felt,
        arr_str : Str*
    ) -> (
        res : Str
    ):

    let (res_init : Str) = str_empty()
    let (res : Str) = _recurse_wrap_tr_td_outer (
        row_cnt = row_cnt,
        col_cnt = col_cnt,
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        res = res_init,
        row_idx = 0
    )

    return (res)

end


func _recurse_wrap_tr_td_outer {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        row_cnt : felt,
        col_cnt : felt,
        arr_str_len : felt,
        arr_str : Str*,
        res : Str,
        row_idx : felt
    ) -> (
        res_outer : Str
    ):
    alloc_locals

    if row_idx == row_cnt:
        return (res)
    end

    #
    # Add opening tr tag
    #
    let (tr_open_str) = str_from_literal (TR_OPEN)
    let (res_with_tr_open) = str_concat (res, tr_open_str)

    #
    # Run inner recursion
    #
    let (res_inner : Str) = _recurse_wrap_tr_td_inner (
        col_cnt = col_cnt,
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        res = res_with_tr_open,
        row_idx = row_idx,
        col_idx = 0
    )

    #
    # Add closing tr tag
    #
    let (tr_close_str) = str_from_literal (TR_CLOSE)
    let (res_with_tr_close) = str_concat (res_inner, tr_close_str)

    #
    # Tail recursion
    #
    let (res_outer : Str) = _recurse_wrap_tr_td_outer (
        row_cnt = row_cnt,
        col_cnt = col_cnt,
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        res = res_with_tr_close,
        row_idx = row_idx + 1
    )
    return (res_outer)
end


func _recurse_wrap_tr_td_inner {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        col_cnt : felt,
        arr_str_len : felt,
        arr_str : Str*,
        res : Str,
        row_idx : felt,
        col_idx : felt
    ) -> (
        res_inner : Str
    ):

    if col_idx == col_cnt:
        return (res)
    end

    #
    # Add opening td tag
    #
    let (td_open_str) = str_from_literal (TD_OPEN)
    let (res_with_td_open) = str_concat (res, td_open_str)

    #
    # Add td content
    #
    let (res_with_td_content) = str_concat (res_with_td_open, arr_str[row_idx * col_cnt + col_idx])

    #
    # Add closing td tag
    #
    let (td_close_str) = str_from_literal (TD_CLOSE)
    let (res_with_td_close) = str_concat (res_with_td_content, td_close_str)

    #
    # Tail recursion
    #
    let (res_inner : Str) = _recurse_wrap_tr_td_inner (
        col_cnt = col_cnt,
        arr_str_len = arr_str_len,
        arr_str = arr_str,
        res = res_with_td_close,
        row_idx = row_idx,
        col_idx = col_idx + 1
    )
    return (res_inner)
end
