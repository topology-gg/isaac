import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
import random
import math
from lib import *

ERR_TOL = 1e-6

@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope='module')
async def contract_factory ():
    starknet = await Starknet.empty()
    contract = await starknet.deploy('contracts/physics_engine.cairo')
    return starknet, contract

@pytest.mark.asyncio
async def test_single_step (contract_factory):

    starknet, contract = contract_factory
    print()

    print(f'> Testing euler_step_single_circle_aabb_boundary() ...')
    TEST_COUNT = 20
    TEST_POS_RANGE = 400
    TEST_VEL_RANGE = 200
    TEST_ACC_RANGE = 100
    TEST_RAD_RANGE = 40
    DT = 0.06

    for i in range(TEST_COUNT):
        r = random.randint(5, TEST_RAD_RANGE)
        x = random.randint(r, TEST_POS_RANGE)
        y = random.randint(r, TEST_POS_RANGE)
        vx = random.randint(-TEST_VEL_RANGE, TEST_VEL_RANGE)
        vy = random.randint(-TEST_VEL_RANGE, TEST_VEL_RANGE)
        ax = random.randint(-TEST_ACC_RANGE, TEST_ACC_RANGE)
        ay = random.randint(-TEST_ACC_RANGE, TEST_ACC_RANGE)
        ret = await contract.euler_step_single_circle_aabb_boundary (
            int(DT * FP),
            contract.ObjectState( contract.Vec2(x*FP, y*FP), contract.Vec2(vx*FP, vy*FP), contract.Vec2(ax*FP, ay*FP) ),
            [r*FP, 0, TEST_POS_RANGE*FP, 0, TEST_POS_RANGE*FP]
        ).call()
        bool_has_collided_with_boundary = ret.result.bool_has_collided_with_boundary
        c_nxt = ret.result.c_nxt

        test_state = {
            'x' : x,
            'y' : y,
            'vx' : vx,
            'vy' : vy,
            'ax' : ax,
            'ay' : ay
        }
        params = {
            'r' : r,
            'x_min' : 0,
            'x_max' : TEST_POS_RANGE,
            'y_min' : 0,
            'y_max' : TEST_POS_RANGE
        }
        test_state_nxt, test_bool_has_collided_with_boundary = euler_single_step (DT, test_state, params)

        assert bool_has_collided_with_boundary == test_bool_has_collided_with_boundary
        check_against_err_tol (adjust(c_nxt.pos.x), test_state_nxt['x'], ERR_TOL)
        check_against_err_tol (adjust(c_nxt.pos.y), test_state_nxt['y'], ERR_TOL)
        check_against_err_tol (adjust(c_nxt.vel.x), test_state_nxt['vx'], ERR_TOL)
        check_against_err_tol (adjust(c_nxt.vel.y), test_state_nxt['vy'], ERR_TOL)
        check_against_err_tol (adjust(c_nxt.acc.x), test_state_nxt['ax'], ERR_TOL)
        check_against_err_tol (adjust(c_nxt.acc.y), test_state_nxt['ay'], ERR_TOL)

        print(f'  test #{i+1} passed.')

    print(f'> {TEST_COUNT} tests passed.')
    print(f'> Resource usage of the last test: {ret.call_info.cairo_usage}')
    print()


@pytest.mark.asyncio
async def test_single_step_and_collision (contract_factory):

    starknet, contract = contract_factory
    print()
    print(f'> Testing euler_step_single_circle_aabb_boundary() and collision_pair_circles() together ...')

    #
    # Testing methodology
    # 1. place one circle randomly and set velocity as random value
    # 2. place the other circle at random position that is 1.1*(r1+r2) away from the first circle;
    #    set velocity as random value
    # 3. euler forward both circles by one step
    # 4. test collision function
    #

    TEST_COUNT = 20
    TEST_POS_RANGE = 400
    TEST_VEL_RANGE = 200
    TEST_ACC_RANGE = 100
    TEST_RAD_RANGE = 40
    DT = 0.06

    for i in range(TEST_COUNT):
        #
        # Construct random states for c1 and c2
        #
        state_1 = {
            'x' : random.randint(50,300),
            'y' : random.randint(50,300),
            'vx' : random.randint(-200,200),
            'vy' : random.randint(-200,200),
            'ax' : random.randint(-200,200),
            'ay' : random.randint(-200,200)
        }
        r1 = random.randint(5, TEST_RAD_RANGE)
        r2 = r1 # TODO: test two circles having different radius values
        theta = 2 * math.pi * random.random()
        distance_vec = ( 1.1*(r1+r2)*math.cos(theta), 1.1*(r1+r2)*math.sin(theta) )

        state_2 = {
            'x' : state_1['x'] + distance_vec[0],
            'y' : state_1['y'] + distance_vec[1],
            'vx' : random.randint(-200,200),
            'vy' : random.randint(-200,200),
            'ax' : random.randint(-200,200),
            'ay' : random.randint(-200,200)
        }

        #
        # Forward c1 and c2 by one euler step
        #
        params_1 = {'r' : r1, 'x_min' : 0, 'x_max' : TEST_POS_RANGE, 'y_min' : 0, 'y_max' : TEST_POS_RANGE}
        params_2 = {'r' : r2, 'x_min' : 0, 'x_max' : TEST_POS_RANGE, 'y_min' : 0, 'y_max' : TEST_POS_RANGE}
        state_1_cand, bool_state_1_collided_boundary = euler_single_step (DT, state_1, params_1)
        state_2_cand, bool_state_2_collided_boundary = euler_single_step (DT, state_2, params_2)

        #
        # Perform collision handling
        #
        state_1_nxt, state_2_nxt, bool_collided = collision_pair_circles (state_1, state_2, state_1_cand, state_2_cand, r1, r2)

        #
        # Prepare for contract calls
        #
        c1 = contract.ObjectState(
            contract.Vec2(state_1['x']*FP,  state_1['y']*FP),
            contract.Vec2(state_1['vx']*FP, state_1['vy']*FP),
            contract.Vec2(state_1['ax']*FP, state_1['ay']*FP)
        )
        c2 = contract.ObjectState(
            contract.Vec2(int(state_2['x']*FP), int(state_2['y']*FP)),
            contract.Vec2(state_2['vx']*FP, state_2['vy']*FP),
            contract.Vec2(state_2['ax']*FP, state_2['ay']*FP)
        )

        #
        # Call contract to forward both circles by one euler step
        #

        ret1 = await contract.euler_step_single_circle_aabb_boundary (
            int(DT * FP),
            c1,
            [r1*FP, 0, TEST_POS_RANGE*FP, 0, TEST_POS_RANGE*FP]
        ).call()
        ret2 = await contract.euler_step_single_circle_aabb_boundary (
            int(DT * FP),
            c2,
            [r2*FP, 0, TEST_POS_RANGE*FP, 0, TEST_POS_RANGE*FP]
        ).call()
        c1_cand = ret1.result.c_nxt
        c2_cand = ret2.result.c_nxt

        #
        # Call contract to perform collision handling
        #
        ret = await contract.collision_pair_circles (
            c1,
            c2,
            c1_cand,
            c2_cand,
            [ r1*FP, (r1+r1)**2*FP ]
        ).call()
        c1_nxt = ret.result.c1_nxt
        c2_nxt = ret.result.c2_nxt
        c1c2_has_collided = ret.result.has_collided

        #
        # Perform checks
        #
        assert ret1.result.bool_has_collided_with_boundary == bool_state_1_collided_boundary
        assert ret2.result.bool_has_collided_with_boundary == bool_state_2_collided_boundary
        assert c1c2_has_collided == bool_collided
        check_against_err_tol (adjust(c1_nxt.pos.x), state_1_nxt['x'], ERR_TOL)
        check_against_err_tol (adjust(c1_nxt.pos.y), state_1_nxt['y'], ERR_TOL)

        print(f'  test #{i+1} passed; collided={c1c2_has_collided}')

    print(f'> {TEST_COUNT} tests passed.')
    print(f'> Resource usage of the last test: {ret.call_info.cairo_usage}')
    print()


@pytest.mark.asyncio
async def test_friction_single_circle (contract_factory):

    starknet, contract = contract_factory
    print()

    print(f'> Testing friction_single_circle() ...')

    TEST_COUNT = 20
    TEST_RAD_RANGE = 40
    DT = 0.06

    for i in range(TEST_COUNT):
        #
        # Prepare stimulus and calculate correct answer
        #
        state = {
            'x' : random.randint(50,300),
            'y' : random.randint(50,300),
            'vx' : random.randint(-200,200),
            'vy' : random.randint(-200,200),
            'ax' : random.randint(-200,200),
            'ay' : random.randint(-200,200)
        }
        should_recalc = random.randint(0,1)
        a_friction = random.randint(1,50)
        state_nxt = friction_single_circle (DT, state, should_recalc, a_friction)

        #
        # Prepare and perform contract call
        #
        c = contract.ObjectState(
            contract.Vec2(state['x']*FP,  state['y']*FP),
            contract.Vec2(state['vx']*FP, state['vy']*FP),
            contract.Vec2(state['ax']*FP, state['ay']*FP)
        )
        ret = await contract.friction_single_circle (
            int(DT * FP),
            c,
            should_recalc,
            a_friction*FP
        ).call()
        c_nxt = ret.result.c_nxt

        #
        # Perform checks
        #
        check_against_err_tol(adjust(c_nxt.pos.x), state_nxt['x'], ERR_TOL)
        check_against_err_tol(adjust(c_nxt.pos.y), state_nxt['y'], ERR_TOL)
        check_against_err_tol(adjust(c_nxt.vel.x), state_nxt['vx'], ERR_TOL)
        check_against_err_tol(adjust(c_nxt.vel.y), state_nxt['vy'], ERR_TOL)
        check_against_err_tol(adjust(c_nxt.acc.x), state_nxt['ax'], ERR_TOL)
        check_against_err_tol(adjust(c_nxt.acc.y), state_nxt['ay'], ERR_TOL)
        print(f'  test #{i+1} passed.')

    print(f'> {TEST_COUNT} tests passed.')
    print(f'> Resource usage of the last test: {ret.call_info.cairo_usage}')
    print()

