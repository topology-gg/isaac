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
PLANET_DIM = 100
SCALE_FP = 10**20

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_fade ():

    starknet = await Starknet.empty()
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_perlin.cairo',
        constructor_calldata = []
    )

    N = 50
    for _ in range(N):
        x_rand = random.randint (0, PLANET_DIM-1)

        ret = await contract.mock_fade( x_rand * math.floor(SCALE_FP/PLANET_DIM)  ).call()
        got = parse_fp_felt (ret.result.res)
        expected = fade (x_rand / PLANET_DIM)

        LOGGER.info (f"x_rand={x_rand}; fade() got={got}, expected={expected}")

        scale = 10000
        got_scaled_floor = math.floor (got * scale)
        expected_scaled_floor = math.floor (expected * scale)
        assert got_scaled_floor == expected_scaled_floor


@pytest.mark.asyncio
async def test_perlin ():

    #
    # Generate contract values and compare against expected values
    # on Face 0
    #
    N = 50

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

            for _ in range (N):
                element_rand = 0
                x_rand = random.randint (0, PLANET_DIM-1)
                y_rand = random.randint (0, PLANET_DIM-1)
                grid_rand = contract.Vec2 (face_offset[0] + x_rand, face_offset[1] + y_rand)
                ret = await contract.mock_get_adjusted_perlin_value(face, grid_rand, element_rand).call() # fe_raw == 0

                # LOGGER.info (f"> got pv_bottom_left_fp  = Vec2 ({parse_fp_felt(ret.main_call_events[0].vec.x)}, {parse_fp_felt(ret.main_call_events[0].vec.y)})")
                # LOGGER.info (f"> got pv_top_left_fp     = Vec2 ({parse_fp_felt(ret.main_call_events[1].vec.x)}, {parse_fp_felt(ret.main_call_events[1].vec.y)})")
                # LOGGER.info (f"> got pv_bottom_right_fp = Vec2 ({parse_fp_felt(ret.main_call_events[2].vec.x)}, {parse_fp_felt(ret.main_call_events[2].vec.y)})")
                # LOGGER.info (f"> got pv_top_right_fp    = Vec2 ({parse_fp_felt(ret.main_call_events[3].vec.x)}, {parse_fp_felt(ret.main_call_events[3].vec.y)})")

                # LOGGER.info (f"> got rv_bottom_left  = Vec2 ({parse_felt(ret.main_call_events[4].vec.x)}, {parse_felt(ret.main_call_events[4].vec.y)})")
                # LOGGER.info (f"> got rv_top_left     = Vec2 ({parse_felt(ret.main_call_events[5].vec.x)}, {parse_felt(ret.main_call_events[5].vec.y)})")
                # LOGGER.info (f"> got rv_bottom_right = Vec2 ({parse_felt(ret.main_call_events[6].vec.x)}, {parse_felt(ret.main_call_events[6].vec.y)})")
                # LOGGER.info (f"> got rv_top_right    = Vec2 ({parse_felt(ret.main_call_events[7].vec.x)}, {parse_felt(ret.main_call_events[7].vec.y)})")

                # LOGGER.info (f"> got u = { parse_fp_felt(ret.main_call_events[8].x) }")
                # LOGGER.info (f"> got v = { parse_fp_felt(ret.main_call_events[9].x) }")
                # LOGGER.info (f"> got lerp_fin = { parse_fp_felt(ret.main_call_events[10].x) }")

                got = ret.result.res
                expected = generate_perlin_on_face_given_normalized_grid_and_element (face, (x_rand, y_rand), element_rand)
                assert got == expected

                LOGGER.info (f"> Face {face} ({x_rand},{y_rand}) element {element_rand}: Expected: {expected}; Got: {got}")
                LOGGER.info ("")

            # for x in range (PLANET_DIM):
                # for y in range (PLANET_DIM):

                    # grid = contract.Vec2 (face_offset[0] + x, face_offset[1] + y)
                    # ret = await contract.mock_get_adjusted_perlin_value(face, grid, element_type).call()

                    # LOGGER.info (f"ret.main_call_events: {ret}")
                    # for event in ret.main_call_events:
                    #     event_vec_parsed = (parse_fp_felt(event.vec.x), parse_fp_felt(event.vec.y))
                        # LOGGER.info (f"> event vector: {event_vec_parsed}")

                    # got = ret.result.res
                    # expected = math.floor(arr2d[y][x])
                    # expected = generate_perlin_on_face_given_normalized_grid (face, (x,y))

                    # LOGGER.info (f"> Face 0 ({x},{y}); Contract: {got}; Expected: {expected}")
                    # LOGGER.info (f"> Face {face} ({x},{y}); Expected: {expected}")

                    # assert got == math.floor (expected)
                    # log.append (expected)

            # LOGGER.info (f'> Face {face}, min {min(log)}, max {max(log)}')

    #
    # Generate expected values for the entire face 0
    # and export to JSON
    #
    if not TEST_CONTRACT:
        gen = {}

        for element in [0,2,4,6,8]:
            min_val = 1000
            max_val = 0
            for face in range(6):
                arr2d = generate_perlin_on_face (face, element)
                gen [face] = arr2d

                for row in arr2d:
                    for ele in row:
                        if ele < min_val:
                            min_val = ele
                        elif ele > max_val:
                            max_val = ele

            gen['min'] = min_val
            gen['max'] = max_val
            LOGGER.info (f'element {element}: max {max_val}, min {min_val}')

            with open(f'perlin_planet_dim_{PLANET_DIM}_element_{element}.json', 'w') as file:
                json.dump(gen, file)

##############################

def parse_fp_felt (felt):
    if felt > PRIME_HALF:
        return (felt-PRIME) / 10**20
    else:
        return felt / 10**20


def parse_felt (felt):
    if felt > PRIME_HALF:
        return (PRIME-felt)
    else:
        return felt


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
def generate_perlin_value (random_vecs, positional_vecs, pos, element):
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

    # LOGGER.info (f"> expected pv_bottom_left  = {positional_vecs[0]}")
    # LOGGER.info (f"> expected pv_top_left     = {positional_vecs[1]}")
    # LOGGER.info (f"> expected pv_bottom_right = {positional_vecs[2]}")
    # LOGGER.info (f"> expected pv_top_right    = {positional_vecs[3]}")

    # LOGGER.info (f"> expected rv_bottom_left  = {random_vecs[0]}")
    # LOGGER.info (f"> expected rv_top_left     = {random_vecs[1]}")
    # LOGGER.info (f"> expected rv_bottom_right = {random_vecs[2]}")
    # LOGGER.info (f"> expected rv_top_right    = {random_vecs[3]}")

    products = [dot(rv, pv) for (rv,pv) in zip(random_vecs, positional_vecs)]
    # for i in range(4):
    #     LOGGER.info (f"> {products[i]}")

    u = fade (pos[0]/PLANET_DIM)
    v = fade (pos[1]/PLANET_DIM)
    # LOGGER.info (f"> expected u = {u}")
    # LOGGER.info (f"> expected v = {v}")

    lerp_left  = lerp (v, products[0], products[1]) # bottom left, top left
    lerp_right = lerp (v, products[2], products[3]) # bottom right, top right
    lerp_fin = lerp (u, lerp_left, lerp_right)

    # LOGGER.info (f"> expected lerp_fin = {lerp_fin}")

    # LOGGER.info (f"> {lerp_left}")
    # LOGGER.info (f"> {lerp_right}")
    # LOGGER.info (f"> {lerp_fin}")

    # val = relu (lerp_fin) *666

    ADJUST_OFFSETS = {
        0 : 9,
        2 : 5,
        4 : 4,
        6 : 3,
        8 : 2
    }
    val = math.floor ( (lerp_fin + ADJUST_OFFSETS[element])**2 )

    # LOGGER.info (f"> {val}")

    return val

def generate_perlin_value_bilinear (random_vecs, positional_vecs, pos):
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

    # Q11(x1,y1)、Q12(x1,y2)、Q21(x2,y1)、Q22(x2,y2)
    # a' = x2 - x1 、b' = y2 - y1、a = x - x1 、b= y - y1
    # P(x,y) = ( (a'-a)(b'-b)Q11 + a(b'-b)Q21 + b(a'-a)Q12 + abQ22 ) / ( a' * b' )
    q11 = products[0]
    q12 = products[1]
    q21 = products[2]
    q22 = products[3]
    a_ = PLANET_DIM
    b_ = PLANET_DIM
    a = pos[0]
    b = pos[1]
    val_bilinear = ( (a_-a)*(b_-b)*q11 + a*(b_-b)*q21 + b*(a_-a)*q12 + a*b*q22 ) / (a_*b_)

    val_adjusted = math.floor ( relu( (val_bilinear + 0.4)**3 ) * 90 )

    return val_adjusted


def relu (x):
    return x if x>0 else 0


def get_rv_from_idx_given_element (idx, element):

    RV = {
        0 : { # FE
            0 : (0, -5),
            1 : (-14, -22),
            2 : (-2, 28),
            3 : (9, 12)
        },
        2 : { # AL
            0 : (15, -5),
            1 : (-15, 8),
            2 : (-25, -12),
            3 : (2, 8)
        },
        4 : { # CU
            0 : (4, 6),
            1 : (-10, 10),
            2 : (-15, -30),
            3 : (20, -10)
        },
        6 : { # SI
            0 : (15, 25),
            1 : (-15, 8),
            2 : (-25, -12),
            3 : (-12, 8)
        },
        8 : { # PU
            0 : (-15, -15),
            1 : (-15, 8),
            2 : (20, 12),
            3 : (2, 8)
        }
    }

    return RV [element][idx]


def get_random_vecs_from_face_given_element (face, element):

    if face == 0:
        idx_s = [0, 1, 3, 0]
    elif face == 1:
        idx_s = [0, 3, 2, 3]
    elif face == 2:
        idx_s = [3, 0, 3, 0]
    elif face == 3:
        idx_s = [0, 1, 0, 2]
    elif face == 4:
        idx_s = [3, 0, 2, 2]
    elif face == 5:
        idx_s = [2, 2, 0, 1]
    else:
        raise

    return [get_rv_from_idx_given_element (idx,element) for idx in idx_s]

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

def generate_perlin_on_face_given_normalized_grid_and_element (face, normalized_grid, element):
    assert 0 <= face <= 5
    pos = normalized_grid

    positional_vecs = get_positional_vecs_from_pos (pos)
    # for i in range(4):
    #     LOGGER.info (f"> positional_vecs[{i}]: {positional_vecs[i]}")

    random_vecs = get_random_vecs_from_face_given_element (face, element)
    # for i in range(4):
    #     LOGGER.info (f"> {random_vecs[i]}")

    pv = generate_perlin_value (random_vecs, positional_vecs, pos, element)

    return pv

def generate_perlin_on_face (face, element):
    arr = []
    for y in range(PLANET_DIM):
        row = []
        for x in range(PLANET_DIM):
            pv = generate_perlin_on_face_given_normalized_grid_and_element (face, (x,y), element)
            row.append (pv)
        arr.append (row)

    return arr
