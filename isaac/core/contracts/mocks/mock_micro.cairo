%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_nn)
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.util.structs import (
    MicroEvent, Vec2
)
from contracts.micro import (
    device_deploy, device_pickup_by_grid,
    utb_deploy, utb_pickup_by_grid, utb_tether_by_grid,
    are_resource_producer_consumer_relationship
)


@external
func mock_device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        type : felt,
        grid : Vec2
    ) -> ():

    device_deploy (
        caller,
        type,
        grid
    )

    return ()
end


@external
func mock_device_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid : Vec2
    ) -> ():
    alloc_locals

    device_pickup_by_grid (
        caller,
        grid
    )

    return ()
end


@external
func mock_utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        locs_len : felt,
        locs : Vec2*,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    utb_deploy (
        caller,
        locs_len,
        locs,
        src_device_grid,
        dst_device_grid
    )

    return ()
end


@external
func mock_utb_pickup_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        grid : Vec2
    ) -> ():

    utb_pickup_by_grid (
        caller,
        grid
    )

    return ()
end


@external
func mock_utb_tether_by_grid {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        caller : felt,
        utb_grid : Vec2,
        src_device_grid : Vec2,
        dst_device_grid : Vec2
    ) -> ():

    utb_tether_by_grid (
        caller,
        utb_grid,
        src_device_grid,
        dst_device_grid
    )

    return ()
end


@external
func mock_are_resource_producer_consumer_relationship {range_check_ptr} (
    device_type0, device_type1) -> ():

    are_resource_producer_consumer_relationship (
        device_type0,
        device_type1
    )

    return ()
end
