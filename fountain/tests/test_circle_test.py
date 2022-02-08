import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from random import choices
from lib import *

@pytest.mark.asyncio
async def test_circle_test ():

    starknet = await Starknet.empty()
    contract = await starknet.deploy('contracts/physics_engine.cairo')
    print()

    TEST_COUNT = 500
    TEST_POS_RANGE = 500
    TEST_RAD_RANGE = 100

    for i in range(TEST_COUNT):
        [x1,x2,y1,y2] = choices( list(range(TEST_POS_RANGE)), k=4 )
        r = choices( list(range(TEST_RAD_RANGE)), k=1)[0]
        bool_intersect = int( (x2-x1)**2 + (y2-y1)**2 <= (2*r)**2 )

        C1 = contract.Vec2 (x1*FP, y1*FP)
        C2 = contract.Vec2 (x2*FP, y2*FP)
        R = r*FP
        ret = await contract.test_circle_intersect(C1, R, C2, R).call()
        assert ret.result.bool_intersect == bool_intersect, f'Error occurred with {C1},{C2},{R}.'
        if (i+1)%50 == 0:
            print(f'  completed {i+1}/{TEST_COUNT} ...')

    print(f'> {TEST_COUNT} tests passed.')
    print(f'> Resource usage of the last test: {ret.call_info.cairo_usage}')
    print()