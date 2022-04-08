%lang starknet
%builtins range_check

from contracts.util.structs import Vec2, Dynamic, Dynamics
from contracts.util.Str import Str, literal_from_number, str_from_literal, str_concat_array
from starkware.cairo.common.math import signed_div_rem
from starkware.cairo.common.alloc import alloc
from contracts.design.constants import PLANET_DIM, SCALE_FP, SCALE_FP_DIV_100, RANGE_CHECK_BOUND

@view
func get_dynamics_viz{range_check_ptr}(dynamics : Dynamics) -> (
        sun0_len : felt, sun0 : felt*, sun1_len : felt, sun1 : felt*, sun2_len : felt, sun2 : felt*,
        plnt_len : felt, plnt : felt*):
    alloc_locals
    let sun0_dyn : Dynamic = dynamics.sun0
    let sun1_dyn : Dynamic = dynamics.sun1
    let sun2_dyn : Dynamic = dynamics.sun2
    let plnt_dyn : Dynamic = dynamics.plnt

    let (local sun0_len, local sun0) = get_svg(sun0_dyn)
    let (local sun1_len, local sun1) = get_svg(sun1_dyn)
    let (local sun2_len, local sun2) = get_svg(sun2_dyn)
    let (local plnt_len, local plnt) = get_svg(plnt_dyn)

    return (sun0_len, sun0, sun1_len, sun1, sun2_len, sun2, plnt_len, plnt)
end

@view
func get_svg{range_check_ptr}(dynamic : Dynamic) -> (arr_len : felt, arr : felt*):
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
