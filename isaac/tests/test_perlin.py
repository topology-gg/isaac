import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)
TEST_NUM_PER_CASE = 200
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_perlin ():

    starknet = await Starknet.empty()

    print(f'> Deploying mock_perlin.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_perlin.cairo',
        constructor_calldata = []
    )

    grid = (0, 60)
    ret = await contract.mock_get_perlin_value(0, contract.Vec2(grid[0],grid[1])).call()
    print(f"> value at face=0, grid={grid}: {ret.result.res}")

    for event in ret.main_call_events:
        print (f"> event: {event}\n")

    # ret = await contract.mock_get_perlin_value(0, contract.Vec2(1,100)).call()
    # print(f"> value at face=0, grid=(1,100): {ret.result.res}")

