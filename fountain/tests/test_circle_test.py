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
    contract = await starknet.deploy('contracts/core/physics_engine.cairo')
    print()

    c1 = contract.Vec2 (50*FP, 40*FP)
    c2 = contract.Vec2 (91*FP, 40*FP)
    r = 20*FP

    ret = await contract.test_circle_intersect(c1, r, c2, r).call()
    print(ret.result)
