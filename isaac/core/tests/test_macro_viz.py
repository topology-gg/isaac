import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging
import json

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

def adjust_from_felt_fp (felt):
	if felt > PRIME_HALF:
		return (felt - PRIME) / SCALE_FP
	else:
		return felt / SCALE_FP

@pytest.mark.asyncio
async def test_macro ():

    # This test does not verify anyting; instead, it requests macro dynamics from the universe contract
    # for visualization purposes

    #
    # Initialize starknet and deploy contract
    #
    starknet = await Starknet.empty()
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_macro.cairo',
        constructor_calldata = []
    )
    LOGGER.info (f'> Deployed mock_macro.cairo.')

    #
    # Reset macro state in storage
    #
    await contract.reset_macro().invoke()
    LOGGER.info (f'> reset_macro() completed.')

    #
    # Record initial state
    #
    macro_state_s = []
    ret = await contract.macro_state_curr_read().call()
    s = ret.result.macro_state
    state = {
        'sun0' : {
            'q': {'x' : adjust_from_felt_fp(s.sun0.q.x), 'y' : adjust_from_felt_fp(s.sun0.q.y)}
        },
        'sun1' : {
            'q': {'x' : adjust_from_felt_fp(s.sun1.q.x), 'y' : adjust_from_felt_fp(s.sun1.q.y)}
        },
        'sun2' : {
            'q': {'x' : adjust_from_felt_fp(s.sun2.q.x), 'y' : adjust_from_felt_fp(s.sun2.q.y)}
        },
        'plnt' : {
            'q': {'x' : adjust_from_felt_fp(s.plnt.q.x), 'y' : adjust_from_felt_fp(s.plnt.q.y)}
        }
    }
    macro_state_s.append(state)
    LOGGER.info (f"> Recorded initial state: {state}")

    #
    # Forward the macro for ~48 physical-hours worth of L2 blocks, record each state
    #
    ITERATION_PER_TX = 40
    N_OF_TX = (1440 // ITERATION_PER_TX) + 1

    for tx_idx in range (N_OF_TX):

        ret = await contract.forward_macro_sequentially(idx = 0, len = ITERATION_PER_TX).invoke ()
        LOGGER.info (f"> Transaction #{tx_idx} forwarded macro by {ITERATION_PER_TX} times, with each state emitted via an event.")
        LOGGER.info (f"> n_steps: {ret.call_info.execution_resources.n_steps}")

        event_s = ret.main_call_events
        for event in event_s:
            s = event.dynamics
            state = {
                'sun0' : {
                    'q': {'x' : adjust_from_felt_fp(s.sun0.q.x), 'y' : adjust_from_felt_fp(s.sun0.q.y)}
                },
                'sun1' : {
                    'q': {'x' : adjust_from_felt_fp(s.sun1.q.x), 'y' : adjust_from_felt_fp(s.sun1.q.y)}
                },
                'sun2' : {
                    'q': {'x' : adjust_from_felt_fp(s.sun2.q.x), 'y' : adjust_from_felt_fp(s.sun2.q.y)}
                },
                'plnt' : {
                    'q': {'x' : adjust_from_felt_fp(s.plnt.q.x), 'y' : adjust_from_felt_fp(s.plnt.q.y)}
                }
            }
            macro_state_s.append(state)

    # N = 1440 # 48 hours / 2 minutes = 1440 blocks
    # N = 100
    # for i in range(N):

    #     await contract.mock_forward_world_macro().invoke()
    #     ret = await contract.macro_state_curr_read().call()
    #     s = ret.result.macro_state
    #     state = {
    #         'sun0' : {
    #             'q': {'x' : s.sun0.q.x, 'y' : s.sun0.q.y}
    #         },
    #         'sun1' : {
    #             'q': {'x' : s.sun1.q.x, 'y' : s.sun1.q.y}
    #         },
    #         'sun2' : {
    #             'q': {'x' : s.sun2.q.x, 'y' : s.sun2.q.y}
    #         },
    #         'plnt' : {
    #             'q': {'x' : s.plnt.q.x, 'y' : s.plnt.q.y}
    #         }
    #     }
    #     macro_state_s.append(state)
    # LOGGER.info (f"> Forwarded macro by {N} times, with each state recorded.")

    #
    # Export as JSON
    #
    path = 'artifacts/test_macro_viz_states.json'
    json_string = json.dumps(macro_state_s)
    with open(path, 'w') as f:
        json.dump (json_string, f)
    LOGGER.info (f"> Exported macro state record to {path}.")