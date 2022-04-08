%lang starknet
%builtins range_check

from contracts.util.structs import Vec2, Dynamic, Dynamics
from contracts.util.Str import Str, literal_from_number, str_from_literal, str_concat_array
from starkware.cairo.common.math import signed_div_rem
from starkware.cairo.common.alloc import alloc
from contracts.design.constants import PLANET_DIM, SCALE_FP, SCALE_FP_DIV_100, RANGE_CHECK_BOUND

@view
func get_sun_svg{range_check_ptr}(dynamic : Dynamic) -> (arr_len : felt, arr : felt*):
    alloc_locals
    let sun_x = dynamic.q.x
    let sun_y = dynamic.q.y

    let (cx_fp, _) = signed_div_rem(sun_x, SCALE_FP, RANGE_CHECK_BOUND)
    let (cy_fp, _) = signed_div_rem(sun_y, SCALE_FP, RANGE_CHECK_BOUND)

    let (cx_literal) = literal_from_number(cx_fp)
    let (cy_literal) = literal_from_number(cy_fp)

    let (arr) = alloc()

    assert arr[0] = '<circle cx="'
    assert arr[1] = cx_literal
    assert arr[2] = '" cy="'
    assert arr[3] = cy_literal
    assert arr[4] = '" r="'
    assert arr[5] = '0.1'
    assert arr[6] = '" fill="'
    assert arr[7] = 'red'
    assert arr[8] = '" />'

    return (9, arr)
end
