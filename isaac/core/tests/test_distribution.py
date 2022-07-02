import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

import math
import random
import matplotlib.pyplot as plt
import numpy as np
import json

LOGGER = logging.getLogger(__name__)
TEST_NUM_PER_CASE = 200
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 25
SCALE_FP = 10**20

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_perlin ():

    #
    # Generate contract values and compare against expected values
    # on Face 0
    #
    i = 0
    element_type = 0 # ELEMENT_FE_RAW
    N = 500
    random_indices = random.sample( [i for i in range(10000)], N )
    random_x = [idx%PLANET_DIM for idx in random_indices]
    random_y = [idx//PLANET_DIM for idx in random_indices]
    # for (y,x) in zip(random_y,random_x):

    TEST_CONTRACT = False
    if TEST_CONTRACT:

        LOGGER.info (f'> Deploying mock_distribution.cairo ..')
        starknet = await Starknet.empty()
        contract = await starknet.deploy (
        source = 'contracts/mocks/mock_distribution.cairo',
        constructor_calldata = [])

        for face in range (6):
            if face == 0: face_offset = (0, PLANET_DIM)
            elif face == 1: face_offset = (PLANET_DIM, 0)
            elif face == 2: face_offset = (PLANET_DIM, PLANET_DIM)
            elif face == 3: face_offset = (PLANET_DIM, PLANET_DIM*2)
            elif face == 4: face_offset = (PLANET_DIM*2, PLANET_DIM)
            elif face == 5: face_offset = (PLANET_DIM*3, PLANET_DIM)

            log = []
            for x in range (PLANET_DIM):
                for y in range (PLANET_DIM):
                    grid = contract.Vec2 (face_offset[0] + x, face_offset[1] + y)
                    # ret = await contract.mock_get_adjusted_perlin_value(face, grid, element_type).call()

                    # LOGGER.info (f"ret.main_call_events: {ret}")
                    # for event in ret.main_call_events:
                    #     event_vec_parsed = (parse_fp_felt(event.vec.x), parse_fp_felt(event.vec.y))
                        # LOGGER.info (f"> event vector: {event_vec_parsed}")

                    # got = ret.result.res
                    # expected = math.floor(arr2d[y][x])
                    expected = generate_perlin_on_face_given_normalized_grid (face, (x,y))

                    # LOGGER.info (f"> Face 0 ({x},{y}); Contract: {got}; Expected: {expected}")
                    LOGGER.info (f"> Face {face} ({x},{y}); Expected: {expected}")
                    # assert got == math.floor (expected)
                    log.append (expected)
            LOGGER.info (f'> Face {face}, min {min(log)}, max {max(log)}')


    #
    # Generate expected values for the entire face 0
    # and export to JSON
    #
    if not TEST_CONTRACT:
        gen = {}
        min_val = 1000
        max_val = 0
        for face in range(6):
            arr2d = generate_perlin_on_face (face)
            gen [face] = arr2d
            for row in arr2d:
                for ele in row:
                    if ele < min_val:
                        min_val = ele
                    elif ele > max_val:
                        max_val = ele

        gen['min'] = min_val
        gen['max'] = max_val

        with open(f'perlin_planet_dim_{PLANET_DIM}.json', 'w') as file:
            json.dump(gen, file)

##############################

def parse_fp_felt (felt):
    if felt > PRIME_HALF:
        return (PRIME-felt) / 10**20
    else:
        return felt / 10**20

def dot (vec1, vec2):
    # both vecs are 2-tuple
    return vec1[0]*vec2[0] + vec1[1]*vec2[1]

def lerp (t, v1, v2):
    # all input args are scalar; t is a float in [0,1]
    assert 0. <= t <= 1.
    return v1 + t*(v2-v1)

def fade (t):
    # t is a float in [0,1]
    assert 0. <= t <= 1.
    return ((6*t - 15)*t + 10)*t*t*t;

def mag (vec):
    return math.sqrt(vec[0]**2 + vec[1]**2)

#
# treat face corners as vertices, each carrying a random vector
#
def generate_perlin_value (random_vecs, positional_vecs, pos):
    # both random/positional_vecs have 4 elements, each element being a 2-tuple
    # pos is a 2-tuple, each element lying in [0,PLANET_DIM)
    # the length of positional_vec does not exceed sqrt(0.99^2 + 0.99^2)

    assert len(random_vecs) == 4
    assert len(positional_vecs) == 4

    for i in [0,1]:
        assert 0 <= pos[i] < PLANET_DIM

    MAX = math.sqrt(0.99**2 + 0.99**2)
    for each in positional_vecs:
        assert mag(each) <= MAX

    products = [dot(rv, pv) for (rv,pv) in zip(random_vecs, positional_vecs)]
    # for i in range(4):
    #     LOGGER.info (f"> {products[i]}")

    u = fade (pos[0]/100.)
    v = fade (pos[1]/100.)
    # LOGGER.info (f"> {u}")
    # LOGGER.info (f"> {v}")

    lerp_left  = lerp (v, products[0], products[1]) # bottom left, top left
    lerp_right = lerp (v, products[2], products[3]) # bottom right, top right
    lerp_fin = lerp (u, lerp_left, lerp_right)
    # LOGGER.info (f"> {lerp_left}")
    # LOGGER.info (f"> {lerp_right}")
    # LOGGER.info (f"> {lerp_fin}")

    # val = relu (lerp_fin) *666
    val = math.floor ( (lerp_fin + 1.6) * 100 )

    # LOGGER.info (f"> {val}")

    return val

def relu (x):
    return x if x>0 else 0

def get_rv_from_rn (rn):
    x = rn % 4
    if x == 0:
        return (1.0, 1.0)
    elif x == 1:
        return (-1.0, 1.0)
    elif x == 2:
        return (-1.0, -1.0)
    else:
        return (1.0, -1.0)

def get_random_vecs_from_face (face, rn_s):
    if face == 0:
        idx_s = [0,1,3,4]
    elif face == 1:
        idx_s = [2,3,6,7]
    elif face == 2:
        idx_s = [3,4,7,8]
    elif face == 3:
        idx_s = [4,5,8,9]
    elif face == 4:
        idx_s = [7,8,10,11]
    elif face == 5:
        idx_s = [10,11,12,13]
    else:
        raise
    rn_4 = [rn_s[idx] for idx in idx_s]

    return [get_rv_from_rn(rn) for rn in rn_4]

def get_positional_vecs_from_pos (pos):
    # bottom left, top left, bottom right, top right
    # vector originates from corners and goes to `pos`

    for i in [0,1]:
        assert 0 <= pos[i] <= (PLANET_DIM-1)

    vecs = [
        (pos[0]-0, pos[1]-0),
        (pos[0]-0, pos[1]-(PLANET_DIM-1)),
        (pos[0]-(PLANET_DIM-1), pos[1]-0),
        (pos[0]-(PLANET_DIM-1), pos[1]-(PLANET_DIM-1))
    ]

    return [(v0/PLANET_DIM, v1/PLANET_DIM) for (v0,v1) in vecs]

def generate_perlin_on_face_given_normalized_grid (face, normalized_grid):
    assert 0 <= face <= 5
    rn_s = [5, 9, 4, 13, 10, 7, 11, 2, 3, 12, 0, 6, 8, 1]
    pos = normalized_grid

    positional_vecs = get_positional_vecs_from_pos (pos)
    # for i in range(4):
    #     LOGGER.info (f"> positional_vecs[{i}]: {positional_vecs[i]}")

    random_vecs = get_random_vecs_from_face (face, rn_s)
    # for i in range(4):
    #     LOGGER.info (f"> {random_vecs[i]}")

    pv = generate_perlin_value (random_vecs, positional_vecs, pos)

    return pv

def generate_perlin_on_face (face):
    arr = []
    for y in range(PLANET_DIM):
        row = []
        for x in range(PLANET_DIM):
            pv = generate_perlin_on_face_given_normalized_grid (face, (x,y))
            row.append (pv)
        arr.append (row)

    return arr
