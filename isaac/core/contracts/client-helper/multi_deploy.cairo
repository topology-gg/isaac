%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_nn)
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.util.structs import (
    Vec2
)

const SERVER_ADDR = 0x0025ecf8ef3993263fec37a54dd730c5d10fa347d1427c584de0a48ec292b4b4

@contract_interface
namespace IServerContract:
    func client_deploy_device_by_grid (type : felt, grid : Vec2) -> ():
    end
end

struct DeviceDeployInfo:
    member type : felt
    member grid : Vec2
end

@external
func multi_device_deploy {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        arr_len : felt,
        arr : DeviceDeployInfo*
    ) -> ():

    recurse_delegate_call_deploy_device (
        len = arr_len,
        arr = arr,
        idx = 0
    )

    return ()
end

func recurse_delegate_call_deploy_device {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        len : felt,
        arr : DeviceDeployInfo*,
        idx : felt
    ) -> ():

    if idx == len:
        return ()
    end

    let info : DeviceDeployInfo = arr[idx]

    IServerContract.delegate_client_deploy_device_by_grid (
        contract_address = SERVER_ADDR,
        type = info.type,
        grid = info.grid
    )

    recurse_delegate_call_deploy_device (
        len,
        arr,
        idx + 1
    )
    return ()
end