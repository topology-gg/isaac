%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.structs import (Vec2, ObjectState)
from contracts.scene_forwarder import (forward_scene_capped_counting_collision)

@view
func mock_forward_scene_capped_counting_collision {
        syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
    } (
        arr_obj_len : felt,
        arr_obj : ObjectState*,
        cap : felt,
        dt : felt,
        params_len : felt,
        params : felt*
    ) -> (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_pairwise_count_len : felt,
        arr_collision_pairwise_count : felt*
    ):

    let (
        arr_obj_final_len : felt,
        arr_obj_final : ObjectState*,
        arr_collision_pairwise_count_len : felt,
        arr_collision_pairwise_count : felt*
    ) = forward_scene_capped_counting_collision (
        arr_obj_len,
        arr_obj,
        cap,
        dt,
        params_len,
        params
    )

    return (
        arr_obj_final_len,
        arr_obj_final,
        arr_collision_pairwise_count_len,
        arr_collision_pairwise_count
    )
end
