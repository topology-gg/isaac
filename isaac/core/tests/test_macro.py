import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

import math
import numpy as np

N_TEST = 1
LOGGER = logging.getLogger(__name__)
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
SCALE_FP = 10**20
ABS_ERR_TOL = 1e-0

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_macro ():

    starknet = await Starknet.empty()

    print(f'> Deploying mock_macro.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_macro.cairo',
        constructor_calldata = []
    )

    # Test strategy
    # 1. from initial dynamics, forward by a random number of steps to obtain the testing dynamics
    # 2. generate a random radian value in FP representation
    # 3. feed testing dynamics + random radian to contract to obtain contract-1dt (1-step-forward) dynamics + radian
    # 4. forward the testing dynamics + radian by 1dt to obtain test-1dt dynamics + radian
    # 5. compare contract-1dt dynamics against test-1dt dynamics
    # 6. compare contract-1dt radian against test-1dt radian

    for i in range(N_TEST):
        #
        # 1. from initial dynamics, forward by a random number of steps to obtain the testing dynamics
        #
        s_init, constants = prepare ()

        sf_init = convert_array_to_fp_felt (s_init)
        state_init = contract.Dynamics (
            sun0 = contract.Dynamic (q = contract.Vec2(sf_init[0], sf_init[2]), qd = contract.Vec2(sf_init[1], sf_init[3])),
            sun1 = contract.Dynamic (q = contract.Vec2(sf_init[4], sf_init[6]), qd = contract.Vec2(sf_init[5], sf_init[7])),
            sun2 = contract.Dynamic (q = contract.Vec2(sf_init[8], sf_init[10]), qd = contract.Vec2(sf_init[9], sf_init[11])),
            plnt = contract.Dynamic (q = contract.Vec2(sf_init[12], sf_init[14]), qd = contract.Vec2(sf_init[13], sf_init[15])),
        )
        LOGGER.info (f"> initial macro state: {s_init}")
        LOGGER.info (f"> initial macro state in felts: {state_init}")

        n_rand = random.randint (0, 500)
        dt = 0.005
        dt_fp = int (dt * SCALE_FP)
        s_test = forward (state=s_init, constants=constants, N=n_rand, dt=dt)

        #
        # 2. generate a random radian value in FP representation
        #
        phi = round(random.uniform(0,1) * math.pi * 2, 20) # 20 deciimal places allowed in contract
        phi_fp = int(phi * SCALE_FP)

        #
        # 3. feed testing dynamics + random radian to contract to obtain contract-1dt (1-step-forward) dynamics + radian
        #
        sf = convert_array_to_fp_felt (s_test)
        state = contract.Dynamics (
            sun0 = contract.Dynamic (q = contract.Vec2(sf[0], sf[2]), qd = contract.Vec2(sf[1], sf[3])),
            sun1 = contract.Dynamic (q = contract.Vec2(sf[4], sf[6]), qd = contract.Vec2(sf[5], sf[7])),
            sun2 = contract.Dynamic (q = contract.Vec2(sf[8], sf[10]), qd = contract.Vec2(sf[9], sf[11])),
            plnt = contract.Dynamic (q = contract.Vec2(sf[12], sf[14]), qd = contract.Vec2(sf[13], sf[15])),
        )
        # LOGGER.info (f"> state to test = {state}")
        ret = await contract.mock_rk4(
            dt_fp,
            state
        ).call()
        sn = ret.result.state_nxt

        ret = await contract.mock_forward_planet_spin (
            phi_fp
        ).call()
        phi_nxt = ret.result.phi_nxt

        sn_list = [
            sn.sun0.q.x, sn.sun0.qd.x, sn.sun0.q.y, sn.sun0.qd.y,
            sn.sun1.q.x, sn.sun1.qd.x, sn.sun1.q.y, sn.sun1.qd.y,
            sn.sun2.q.x, sn.sun2.qd.x, sn.sun2.q.y, sn.sun2.qd.y,
            sn.plnt.q.x, sn.plnt.qd.x, sn.plnt.q.y, sn.plnt.qd.y
        ]
        s_contract_1dt = convert_array_from_fp_felt (sn_list)
        phi_contract_1dt = convert_from_fp_felt (phi_nxt)

        #
        # 4. forward the testing dynamics + radian by 1dt to obtain test-1dt dynamics + radian
        #
        s_test_1dt = forward (state=s_test, constants=constants, N=1, dt=dt)

        omega_dt = 624 / 100 * 6 / 100
        two_pi_approx = 6283185 / 1000000
        phi_test_1dt = (phi + omega_dt) % two_pi_approx

        #
        # 5. compare contract-1dt dynamics against test-1dt dynamics
        #
        for t,c in zip(s_test_1dt, s_contract_1dt):
            abs_err = abs(t-c)
            assert abs_err <= ABS_ERR_TOL

        #
        # 6. compare contract-1dt radian against test-1dt radian
        #
        abs_err = abs(phi_contract_1dt - phi_test_1dt)
        assert abs_err <= ABS_ERR_TOL

        LOGGER.info (f"> test {i+1}/{N_TEST} passed.\n")

#######

def convert_from_fp_felt (fp):
    if fp > PRIME_HALF:
        fp_scaled = fp - PRIME
    else:
        fp_scaled = fp
    val = fp_scaled / SCALE_FP
    return val

def convert_array_from_fp_felt (fp_array):
    ret = []
    for fp in fp_array:
        val = convert_from_fp_felt (fp)
        ret.append (val)
    return ret

def convert_array_to_fp_felt (state):
    state_fp_felt = []
    for val in state:
        val_scaled = int (val * SCALE_FP)
        if val_scaled < 0:
            val_fp = val_scaled + PRIME
        else:
            val_fp = val_scaled
        state_fp_felt.append (val_fp)
    return state_fp_felt

def evaluate_3plus1body (state, constants):

    G  = constants['G']
    M1 = constants['M1']
    M2 = constants['M2']
    M3 = constants['M3']

    [x1, x1d, y1, y1d, x2, x2d, y2, y2d, x3, x3d, y3, y3d, x4, x4d, y4, y4d] = state # unpack state

    x1_diff = x1d
    y1_diff = y1d
    x2_diff = x2d
    y2_diff = y2d
    x3_diff = x3d
    y3_diff = y3d
    x4_diff = x4d
    y4_diff = y4d

    R12 = math.sqrt( (x2-x1)**2 + (y2-y1)**2 )
    R13 = math.sqrt( (x3-x1)**2 + (y3-y1)**2 )
    R23 = math.sqrt( (x2-x3)**2 + (y2-y3)**2 )

    R14 = math.sqrt( (x4-x1)**2 + (y4-y1)**2 )
    R24 = math.sqrt( (x4-x2)**2 + (y4-y2)**2 )
    R34 = math.sqrt( (x4-x3)**2 + (y4-y3)**2 )

    G_R12_3 = G / (R12**3)
    G_R13_3 = G / (R13**3)
    G_R23_3 = G / (R23**3)

    G_R14_3 = G / (R14**3)
    G_R24_3 = G / (R24**3)
    G_R34_3 = G / (R34**3)

    x1d_diff = G_R12_3 * M2 * (x2-x1) + G_R13_3 * M3 * (x3-x1)
    y1d_diff = G_R12_3 * M2 * (y2-y1) + G_R13_3 * M3 * (y3-y1)
    x2d_diff = G_R12_3 * M1 * (x1-x2) + G_R23_3 * M3 * (x3-x2)
    y2d_diff = G_R12_3 * M1 * (y1-y2) + G_R23_3 * M3 * (y3-y2)
    x3d_diff = G_R13_3 * M1 * (x1-x3) + G_R23_3 * M2 * (x2-x3)
    y3d_diff = G_R13_3 * M1 * (y1-y3) + G_R23_3 * M2 * (y2-y3)

    x4d_diff = G_R14_3 * M1 * (x1-x4) + G_R24_3 * M2 * (x2-x4) + G_R34_3 * M3 * (x3-x4)
    y4d_diff = G_R14_3 * M1 * (y1-y4) + G_R24_3 * M2 * (y2-y4) + G_R34_3 * M3 * (y3-y4)

    return np.array( [x1_diff, x1d_diff, y1_diff, y1d_diff,
                      x2_diff, x2d_diff, y2_diff, y2d_diff,
                      x3_diff, x3d_diff, y3_diff, y3d_diff,
                      x4_diff, x4d_diff, y4_diff, y4d_diff])


# reference: https://prappleizer.github.io/Tutorials/RK4/RK4_Tutorial.html
def rk4(dt, state, evaluate, constants):
    '''
    Given a vector state at t, calculate state at t+dt
    using rk4 method
    '''
    # LOGGER.info (f"rk4: state = {state}")
    k1 = dt * evaluate (state, constants)
    k2 = dt * evaluate (state + 0.5*k1, constants)
    k3 = dt * evaluate (state + 0.5*k2, constants)
    k4 = dt * evaluate (state + k3, constants)

    state_delta = (1/6.)*(k1+ 2*k2 + 2*k3 + k4)
    state_t_dt = state + state_delta

    return state_t_dt, state_delta


#
# Prepare initial state & constants
#
def prepare ():
    Q1_unit = (0.97000436, -0.24308753)
    V3_unit = (-0.93240737, -0.86473146)
    Q4_unit = (Q1_unit[0]/2, Q1_unit[1]/2)
    V4_unit = (V3_unit[0]/2.6, V3_unit[1]/2.6)

    # Note: when SCALE_CONST is C^2, SCALE_Q must be C^3, and SCALE_V must be sqrt(C),
    #       to scale quantities correctly
    C = 1.6
    SCALE_V = math.sqrt (C) # sqrt(4) = 2
    SCALE_Q = C**3 # 4^3 = 64
    SCALE_CONST = C**2 # 4^2 = 16

    Q1 = (Q1_unit[0]*SCALE_Q, Q1_unit[1]*SCALE_Q)
    Q4 = (Q4_unit[0]*SCALE_Q, Q4_unit[1]*SCALE_Q)
    V3 = (V3_unit[0]*SCALE_V, V3_unit[1]*SCALE_V)
    V4 = (V4_unit[0]*SCALE_V, V4_unit[1]*SCALE_V)

    constants = {
        'G'  : 1. * SCALE_CONST,
        'M1' : 1. * SCALE_CONST,
        'M2' : 1. * SCALE_CONST,
        'M3' : 1. * SCALE_CONST
    }

    state = np.array( [Q1[0], -V3[0]/2, Q1[1], -V3[1]/2,
                         -Q1[0], -V3[0]/2, -Q1[1], -V3[1]/2,
                         0, V3[0], 0, V3[1],
                         Q4[0], V4[0], Q4[1], V4[1]] )
    return state, constants

#
# Forward via integration
#
def forward (state, constants, N=105, dt=0.005):

    ss = [state]
    for i in range(N):
        s_1dt, _ = rk4 (dt, ss[-1], evaluate_3plus1body, constants)
        ss.append (s_1dt)

    return ss[-1]
