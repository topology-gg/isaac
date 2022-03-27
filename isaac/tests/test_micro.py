import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)
TEST_NUM_PER_CASE = 100
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100

@pytest.mark.asyncio
async def test_micro ():

    starknet = await Starknet.empty()
    print(f'> Deploying mock_micro.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_micro.cairo',
        constructor_calldata = []
    )

    #############################
    # Test `mock_device_deploy()`
    #############################
    print('> Testing mock_device_deploy()')




    # LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: grid {grid} on face {face} and edge {edge}, output: {ret.result}')
