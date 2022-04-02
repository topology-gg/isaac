%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.macro import (forward_world_macro)
# from contracts.micro import ()
# from contracts.design.constants import ()
from contracts.util.structs import (
    Vec2, Dynamic, Dynamics
)

##############################

@storage_var
func last_l2_block () -> (block_num : felt):
end

@storage_var
func micro_contract_address () -> (addr : felt):
end

@constructor
func constructor{syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        # micro_contract_addr : felt
    ):

    #
    # Initialize macro world - trisolar system placement & planet rotation
    #
    macro_state_curr.write (Dynamics(
        sun0 = Dynamic(
            q=Vec2(
                x=47773868232910987264,
                y=32844341810368286720),
            qd=Vec2(
                x=3618502788666131213697322783095070105623107215331596699862321436184118558721,
                y=3618502788666131213697322783095070105623107215331596699937498889642259275777)
        ),
        sun1 = Dynamic(
            q=Vec2(
                x=60201625119764856832,
                y=3618502788666131213697322783095070105623107215331596699937586558378790285313),
            qd=Vec2(
                x=106710634915355459584,
                y=3618502788666131213697322783095070105623107215331596699961957519972063008769)
        ),
        sun2=Dynamic(
            q=Vec2(
                x=3618502788666131213697322783095070105623107215331596699865116562783200034817,
                y=2661155946711651328),
            qd=Vec2(
                x=4059985036398170112,
                y=46727702657421705216)
        ),
        plnt=Dynamic(
            q=Vec2(
                x=4676853079239927267328,
                y=3618502788666131213697322783095070105623107215331596695090310503521091321857),
            qd=Vec2(
                x=190912647818214178816,
                y=3618502788666131213697322783095070105623107215331596699776260363489563443201)
        )
    ))

    phi_curr.write (0)

    #
    # TODO: initialize mini world - resource distribution placement
    #


    #
    # Record L2 block at reality genesis
    #
    let (block) = get_block_number ()
    last_l2_block.write (block)

    return()
end

##############################

#
# phi: the spin orientation of the planet in the trisolar coordinate system;
# spin axis perpendicular to the plane of orbital motion
#
@storage_var
func phi_curr () -> (phi : felt):
end

@storage_var
func macro_state_curr () -> (macro_state : Dynamics):
end

@view
func view_phi_curr {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (phi : felt):
    let (phi) = phi_curr.read ()
    return (phi)
end

@view
func view_macro_state_curr {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
    ) -> (macro_state : Dynamics):
    let (macro_state) = macro_state_curr.read ()
    return (macro_state)
end

@external
func client_forward_world {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> ():
    alloc_locals

    #
    # Make sure only one L2 block has passed
    # TODO: allow fast-foward >1 L2 blocks in case of unexpected network / yagi issues
    #
    # let (block_curr) = get_block_number ()
    # let (block_last) = last_l2_block.read ()
    # let block_diff = block_curr - block_last
    # with_attr error_message("last block must be exactly one block away from current block."):
    #     assert block_diff = 1
    # end

    #
    # Forward macro world - orbital positions of trisolar system, and spin orientation of planet
    # TODO: allow fast-foward >1 DT, requiring recursive calls to forward_world_macro ()
    #
    let (macro_state : Dynamics) = macro_state_curr.read ()
    let (phi : felt) = phi_curr.read ()

    let (
        macro_state_nxt : Dynamics,
        phi_nxt : felt
    ) = forward_world_macro (macro_state, phi)

    macro_state_curr.write (macro_state_nxt)
    phi_curr.write (phi_nxt)

    #
    # Forward micro world - all activities on the surface of the planet
    #
    # forward_world_micro ()

    return ()
end

##############################
