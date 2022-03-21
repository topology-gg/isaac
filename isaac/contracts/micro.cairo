%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.macro import (forward_world_macro)
# from contracts.design.constants import ()
from contracts.util.structs import (
    MicroEvent, Vec2
)
from contracts.grid import (
    is_valid_grid, are_contiguous_grids_given_valid_grids
)

##############################

# @constructor
# func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} ():

#     return()
# end

##############################

# @storage_var
# func grid_stats () -> ():
# end

# @external
# func forward_micro_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
#     alloc_locals


#     return ()
# end

##############################

#
# utb
#

# @storage_var
# func utb_set_info_given_label {} (
#         label : felt
#     ) -> ( info : utbSetInfo ):

# end

@storage_var
func utb_ledger (index : felt) -> (grid : Vec2):
end

func view_utb_ledger {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        index : felt) -> (grid : Vec2):
    let (grid) = utb_ledger.read (index)
    return (grid)
end

func utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        locs_len : felt,
        locs : Vec2*,
        src_device_id : felt,
        dst_device_id : felt
    ) -> ():

    is_valid_grid (locs[0])
    # TODO: check locs[0] is contiguous to src_device_id's grid using `are_contiguous_grids_given_valid_grids()`
    # TODO: check locs[locs_len-1] is contiguous to dst_device_id's grid using `are_contiguous_grids_given_valid_grids()`

    recurse_utb_deploy (
        len = locs_len,
        arr = locs,
        idx = 1
    )

    # TODO: if the above deployment is successful, register with devices at source / destination

    return ()
end

func recurse_utb_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len : felt,
        arr : Vec2*,
        idx : felt
    ) -> ():
    alloc_locals

    if idx == len:
        return ()
    end

    #
    # In the following checks, any failure would revert this tx
    #
    # 1. check loc is a valid grid coordinate
    is_valid_grid (arr[idx])

    # 2. check loc is not already populated
    # TODO: is_unpopulated_grid (arr[idx])

    # 3. check loc is contiguous with previous loc, unless idx==0
    are_contiguous_grids_given_valid_grids (arr[idx-1], arr[idx])

    # register utb to grid
    # TODO

    recurse_utb_deploy (len, arr, idx+1)
    return ()
end

##############################