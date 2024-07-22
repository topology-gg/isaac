import pytest
import os
import random
import math
from starkware.starknet.testing.starknet import Starknet
from lib import *
from visualizer import *
import asyncio
from Signer import Signer

NUM_SIGNING_ACCOUNTS = 1
DUMMY_PRIVATE = 49582320498
users = []

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
            "examples/libs/Account.cairo",
            constructor_calldata=[signer.public_key]
        )
        await account.initialize(account.contract_address).invoke()
        users.append({
            'signer' : signer,
            'account' : account
        })

        print(f'  Account {i} is: {account.contract_address} (decimal)')
    print()

    return starknet, accounts

@pytest.mark.asyncio
async def test_game_html (account_factory):

    starknet, accounts = account_factory
    contract = await starknet.deploy('examples/zeroxstrat_v1/game.cairo')
    print()

    # ret = await contract.submit_move_for_level (
    #     level = 0,
    #     move = contract.Vec2 ( int(59.186681154728 *FP), int(-196.33373824661 *FP) )
    # ).invoke()

    # move_x = 59186681154728
    # move_y = 3618502788666131213697322783095070105623107215331596699973091859802133773871
    calldata = [0, int(59.186681154728 *FP), PRIME+int(-196.33373824661 *FP)]
    user = users[0]
    print(f'calldata: {calldata}')
    # await user['signer'].send_transaction(
    #     account=user['account'],
    #     to=contract.contract_address,
    #     selector_name='submit_move_for_level',
    #     calldata=calldata
    # )

    # ret = await contract.view_solution_records_as_html().call()
    # felt_array = ret.result.arr
    # print(felt_array)
    # recovered_html = felt_array_to_ascii(felt_array)
    # print(recovered_html)



def felt_array_to_ascii (felt_array):
    ret = ""
    for felt in felt_array:
        ret += felt_to_ascii (felt)
    return ret


def felt_to_ascii (felt):
    bytes_object = bytes.fromhex( hex(felt)[2:] )
    ascii_string = bytes_object.decode("ASCII")
    return ascii_string
