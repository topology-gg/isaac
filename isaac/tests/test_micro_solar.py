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

import test_macro

LOGGER = logging.getLogger(__name__)
TEST_NUM_PER_CASE = 200
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100
SCALE_FP = 10**20

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_micro_solar ():

    starknet = await Starknet.empty()

    LOGGER.info (f'> Deploying mock_micro_solar.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_micro_solar.cairo',
        constructor_calldata = [])

    #
    # Test sine function taylor-expanded to 7th order
    #
    # ratio_s = np.linspace(0, 1, num=19).tolist()
    # phi_s = [ round(ratio * math.pi * 2, 20) for ratio in ratio_s ] # 20 deciimal places allowed in contract
    # phi_fp_s = [ int(phi * SCALE_FP) for phi in phi_s ]
    # sin_math_s = [math.sin(phi) for phi in phi_s]

    # def recover_from_fp_felt (fp_felt):
    #     if fp_felt > PRIME_HALF:
    #         return (fp_felt-PRIME) / SCALE_FP
    #     else:
    #         return fp_felt / SCALE_FP

    # sin_contract_s = []
    # for phi_fp in phi_fp_s:
    #     ret = await contract.mock_sine_7th(phi_fp).call()
    #     sin_contract_s.append ( recover_from_fp_felt(ret.result.value) )

    # for sin_math, sin_contract in zip (sin_math_s, sin_contract_s):
    #     LOGGER.info (f"> expected: {sin_math} | got: {sin_contract}")

    #
    # Get initial state
    #
    s_init, constants = test_macro.prepare ()

    #
    # Forward initial state by random steps by N times, each time get solar exposure for a grid on each side
    #
    grids = [
        contract.Vec2(50, 150),
        contract.Vec2(150, 50),
        contract.Vec2(150, 150),
        contract.Vec2(150, 250),
        contract.Vec2(250, 150),
        contract.Vec2(350, 150)
    ]
    N = 10
    for n in range(N):
        LOGGER.info (f"> Test case {n+1}/{N}")
        #
        # Prepare a random macro state
        #
        n_rand = random.randint (0, 500)
        dt = 0.005
        s_test = test_macro.forward (state=s_init, constants=constants, N=n_rand, dt=dt)
        sf = test_macro.convert_array_to_fp_felt (s_test)
        state = contract.Dynamics (
            sun0 = contract.Dynamic (q = contract.Vec2(sf[0], sf[2]), qd = contract.Vec2(sf[1], sf[3])),
            sun1 = contract.Dynamic (q = contract.Vec2(sf[4], sf[6]), qd = contract.Vec2(sf[5], sf[7])),
            sun2 = contract.Dynamic (q = contract.Vec2(sf[8], sf[10]), qd = contract.Vec2(sf[9], sf[11])),
            plnt = contract.Dynamic (q = contract.Vec2(sf[12], sf[14]), qd = contract.Vec2(sf[13], sf[15])),
        )

        #
        # Prepare a random phi
        #
        phi = round(random.uniform(0,1) * math.pi * 2, 20) # 20 deciimal places allowed in contract
        phi_fp = int(phi * SCALE_FP)

        #
        # Obtain `macro_states_for_transform`
        #
        ret = await contract.mock_get_macro_states_for_transform (
            macro_state = state,
            phi = phi_fp
        ).call ()
        macro_states_for_transform = ret.result.macro_states_for_transform
        LOGGER.info (f"> macro_states_for_transform = {macro_states_for_transform}")

        #
        # For each grids of interest, obtain its solar exposure under `macro_states_for_transform`
        #
        for grid in grids:
            ret = await contract.mock_get_solar_exposure_fp (
                grid,
                macro_states_for_transform
            ).call()
            exposure_fp = ret.result.exposure_fp
            LOGGER.info (f"> solar exposure at grid {grid} = {exposure_fp / SCALE_FP}")
        LOGGER.info ("")



###############

# struct MacroDistanceSquares:
#     member distance_sq_to_sun0 : felt
#     member distance_sq_to_sun1 : felt
#     member distance_sq_to_sun2 : felt
# end


# struct MacroVectors:
#     member vector_plnt_to_sun0 : Vec2
#     member vector_plnt_to_sun1 : Vec2
#     member vector_plnt_to_sun2 : Vec2
# end

# struct PlanetSideSurfaceNormals:
#     member normal_side0 : Vec2
#     member normal_side2 : Vec2
#     member normal_side4 : Vec2
#     member normal_side5 : Vec2
# end

# struct MacroStatesForTransform:
#     member macro_distances : MacroDistanceSquares
#     member macro_vectors : MacroVectors
#     member planet_side_surface_normals : PlanetSideSurfaceNormals
# end