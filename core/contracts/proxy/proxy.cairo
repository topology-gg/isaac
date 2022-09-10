# SPDX-License-Identifier: MIT
# OpenZeppelin Contracts for Cairo v0.3.2 (upgrades/presets/Proxy.cairo)

%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.starknet.common.syscalls import (
    library_call,
    library_call_l1_handler,
    get_caller_address
)
from openzeppelin.upgrades.library import Proxy

const GYOZA = 0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898

#
# Constructor
#

@constructor
func constructor{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(implementation_hash: felt):
    Proxy._set_implementation_hash(implementation_hash)
    return ()
end

#
# Change implementation hash - only GYOZA can invoke this
#
@external
func change_implementation_hash {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
        new_implementation_hash : felt
    ) -> ():

    let (caller) = get_caller_address ()
    with_attr error_message ("only GYOZA can invoke this function"):
        assert caller = GYOZA
    end

    Proxy._set_implementation_hash (new_implementation_hash)

    return ()
end

#
# View implementation hash
#
@view
func view_implementation_hash {syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr} (
    ) -> (implementation_hash : felt):

    let (implementation_hash) = Proxy.get_implementation_hash()

    return (implementation_hash)
end

#
# Fallback functions
#

@external
@raw_input
@raw_output
func __default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ) -> (
        retdata_size: felt,
        retdata: felt*
    ):
    let (class_hash) = Proxy.get_implementation_hash()

    let (retdata_size: felt, retdata: felt*) = library_call(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    )
    return (retdata_size=retdata_size, retdata=retdata)
end


@l1_handler
@raw_input
func __l1_default__{
        syscall_ptr: felt*,
        pedersen_ptr: HashBuiltin*,
        range_check_ptr
    }(
        selector: felt,
        calldata_size: felt,
        calldata: felt*
    ):
    let (class_hash) = Proxy.get_implementation_hash()

    library_call_l1_handler(
        class_hash=class_hash,
        function_selector=selector,
        calldata_size=calldata_size,
        calldata=calldata,
    )
    return ()
end
