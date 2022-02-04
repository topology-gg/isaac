import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer

FP = 1000 * 1000
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2

@pytest.mark.asyncio
async def test_game_state_forwarder ():

    starknet = await Starknet.empty()
    contract = await starknet.deploy('contracts/core/game_state_forwarder.cairo')
    print()

    state_init = contract.GameState(
        score0_ball = contract.BallState(
            pos = contract.Vec2(300*FP, 250*FP), vel = contract.Vec2(0, 0), acc = contract.Vec2(0, 0)
        ),
        score1_ball = contract.BallState(
            pos = contract.Vec2(200*FP, 250*FP), vel = contract.Vec2(0, 0), acc = contract.Vec2(0, 0)
        ),
        forbid_ball = contract.BallState(
            pos = contract.Vec2(200*FP, 350*FP), vel = contract.Vec2(0, 0), acc = contract.Vec2(0, 0)
        ),
        player1_ball = contract.BallState(
            pos = contract.Vec2(50*FP, 40*FP), vel = contract.Vec2(20*FP, 20*FP), acc = contract.Vec2(0, 0)
        ),
        player2_ball = contract.BallState(
            pos = contract.Vec2(91*FP, 40*FP), vel = contract.Vec2(20*FP, 20*FP), acc = contract.Vec2(0, 0)
        ),
        player3_ball = contract.BallState(
            pos = contract.Vec2(180*FP, 60*FP), vel = contract.Vec2(200*FP, 150*FP), acc = contract.Vec2(0, 0)
        )
    )
    print(f'> starting state:')
    print_game_state(state_init)
    print()

    CAP = 80
    print(f'> Calling recurse_euler_forward_capped() with cap={CAP} ...')
    ret = await contract.recurse_euler_forward_capped(
        state = state_init,
        first = 1,
        iter = 0,
        cap = CAP
    ).call()
    print()

    print(f'> result:')
    print_game_state(ret.result.state_end)
    print(f'    p1 stats: {ret.result.p1_stats_end}')
    print(f'    p2 stats: {ret.result.p2_stats_end}')
    print(f'    p3 stats: {ret.result.p3_stats_end}')
    print()

    print(f'  call_info: {ret.call_info}')


def print_game_state (state):
    s0 = state.score0_ball
    s1 = state.score1_ball
    fb = state.forbid_ball
    p1 = state.player1_ball
    p2 = state.player2_ball
    p3 = state.player3_ball

    print(f'    score0_ball:   pos=({adjust(s0.pos.x)}, {adjust(s0.pos.y)}), vel=({adjust(s0.vel.x)}, {adjust(s0.vel.y)}), acc=({adjust(s0.acc.x)}, {adjust(s0.acc.y)})')
    print(f'    score1_ball:   pos=({adjust(s1.pos.x)}, {adjust(s1.pos.y)}), vel=({adjust(s1.vel.x)}, {adjust(s1.vel.y)}), acc=({adjust(s1.acc.x)}, {adjust(s1.acc.y)})')
    print(f'    forbid_ball:   pos=({adjust(fb.pos.x)}, {adjust(fb.pos.y)}), vel=({adjust(fb.vel.x)}, {adjust(fb.vel.y)}), acc=({adjust(fb.acc.x)}, {adjust(fb.acc.y)})')
    print(f'    player1_ball:  pos=({adjust(p1.pos.x)}, {adjust(p1.pos.y)}), vel=({adjust(p1.vel.x)}, {adjust(p1.vel.y)}), acc=({adjust(p1.acc.x)}, {adjust(p1.acc.y)})')
    print(f'    player2_ball:  pos=({adjust(p2.pos.x)}, {adjust(p2.pos.y)}), vel=({adjust(p2.vel.x)}, {adjust(p2.vel.y)}), acc=({adjust(p2.acc.x)}, {adjust(p2.acc.y)})')
    print(f'    player3_ball:  pos=({adjust(p3.pos.x)}, {adjust(p3.pos.y)}), vel=({adjust(p3.vel.x)}, {adjust(p3.vel.y)}), acc=({adjust(p3.acc.x)}, {adjust(p3.acc.y)})')


def adjust (felt):
    if felt > PRIME_HALF:
        return (felt - PRIME)/FP
    else:
        return felt/FP
