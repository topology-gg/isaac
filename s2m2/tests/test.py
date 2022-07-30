import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)

NUM_SIGNING_ACCOUNTS = 1
DUMMY_PRIVATE = 9812304879503423120395
users = []

PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2

## Note to test logging:
## `--log-cli-level=INFO` to show logs

### Reference: https://github.com/perama-v/GoL2/blob/main/tests/test_GoL2_infinite.py
@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope='module')
async def account_factory():
    starknet = await Starknet.empty()
    print()

    accounts = []
    print(f'> Deploying {NUM_SIGNING_ACCOUNTS} accounts...')
    for i in range(NUM_SIGNING_ACCOUNTS):
        signer = Signer(DUMMY_PRIVATE + i)
        account = await starknet.deploy(
            "contracts/libs/Account.cairo",
            constructor_calldata=[signer.public_key]
        )
        await account.initialize(account.contract_address).invoke()
        users.append({
            'signer' : signer,
            'account' : account
        })

        print(f'  Account {i} is: {hex(account.contract_address)}')
    print()

    return starknet, accounts

@pytest.mark.asyncio
async def test (account_factory):

    player = users[0]

    starknet, accounts = account_factory

    LOGGER.info (f'> Deploying s2m2.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/s2m2.cairo',
        constructor_calldata = []
    )

    #
    # toy solutions
    #

    incorrect_solution_revisit = [0,1,2,3,11,10,2,1,9,8]

    incorrect_solution_failing_black_white = list_a_to_b(0,7) + \
         list_a_to_b(15,9) + list_a_to_b(17,23) + list_a_to_b(31,25) + list_a_to_b(33,39) + \
         list_a_to_b(47,41) + list_a_to_b(49,55) + list_a_to_b(63,57) + [56, 48, 40, 32, 24, 16, 8]

    correct_solution = [
        0,1,9,10,2,3,4,5,13,12,11,19,27,26,18,17,25,33,34,35,
        43,51,52,44,36,28,20,21,22,14,6,7,15,23,31,30,29,37,45,46,38,39,47,55,54,
        62,61,60,59,58,57,56,48,49,50,42,41,40,32,24,16,8
    ]

    # ret = await contract.solve (
    #     correct_solution
    # ).invoke()

    # LOGGER.info (f'ret: {ret}')
    # LOGGER.info (f'ret.call_info.events: {ret.call_info.events}')

    await player['signer'].send_transaction (
        account = player['account'], to = contract.contract_address,
        selector_name = 'solve',
        calldata = [0] + [len(correct_solution)] + correct_solution
    )

    ret = await contract.has_unsolved_puzzle().call()
    LOGGER.info (f'> has_unsolved_puzzle: {ret.result}')

    ret = await contract.read_s2m_is_puzzle_solved(0).call()
    LOGGER.info (f'> read_s2m_is_puzzle_solved(0): {ret.result}')

    ret = await contract.read_s2m_puzzle_solved_count().call()
    LOGGER.info (f'> read_s2m_puzzle_solved_count: {ret.result}')

    ret = await contract.read_s2m_solver_record(player['account'].contract_address).call()
    LOGGER.info (f'> read_s2m_solver_record(player account): {ret.result}')


def list_a_to_b (a, b):
    if b>a:
        return [a + i for i in range(b-a+1)]
    else:
        return [a - i for i in range(a-b+1)]