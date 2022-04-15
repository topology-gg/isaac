import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)

NUM_SIGNING_ACCOUNTS = 2
DUMMY_PRIVATE = 9812304879503423120395
users = []

PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100

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
async def test_micro (account_factory):

    admin = users[0]
    user = users[1]
    user_addr = user['account'].contract_address

    starknet, accounts = account_factory
    LOGGER.info (f'> Deploying micro.cairo ..\n')
    contract = await starknet.deploy (
        source = 'contracts/micro.cairo',
        constructor_calldata = []
    )

    #
    # admin gives user 2 iron harvesters
    #
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            2, # DEVICE_FE_HARV
            2
        ])

    #
    # admin gives user 2 iron refineries
    #
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            7, # DEVICE_FE_REFN
            2
        ])

    #
    # admin gives user 10 UTBs
    #
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            12, # UTB
            10
        ])


    #
    # user deploys H1 => R1
    #
    LOGGER.info (f'> user deploys: H1 => R1')
    H1_grid = (150, 85)
    R1_grid = (153, 85) # 152-153, 85-86

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            H1_grid[0], H1_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            7, # DEVICE_FE_REFN
            R1_grid[0], R1_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            2, 151, 152, # locs_x
            2, 85, 85, # locs_y
            150, 85, 153, 85
        ])

    #
    # user deploys H2 => R2
    #
    LOGGER.info (f'> user deploys: H2 => R2')
    H2_grid = (110, 140)
    R2_grid = (110, 149) # 110-111, 149-150

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            H2_grid[0], H2_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            7, # DEVICE_FE_REFN
            R2_grid[0], R2_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            8, 110, 110, 110, 110, 110, 110, 110, 110, # locs_x
            8, 141, 142, 143, 144, 145, 146, 147, 148, # locs_y
            110, 140, 110, 149
        ])

    #
    # grab all utb grids and check correctness
    #

    ret = await contract.admin_read_utb_set_deployed_emap_size().call()
    size = ret.result.size
    for i in range(size):
        ret = await contract.admin_read_utb_set_deployed_emap(i).call()
        LOGGER.info (f"> emap entry: {ret.result.emap_entry}")

    ret = await contract.iterate_utb_deployed_emap_grab_all_utbs().call()
    LOGGER.info (f"> grids: {ret.result.grids}")

    grids = ret.result.grids
    assert grids[0] == contract.Vec2(151, 85)
    assert grids[1] == contract.Vec2(152, 85)

    assert grids[2] == contract.Vec2(110, 141)
    assert grids[3] == contract.Vec2(110, 142)
    assert grids[4] == contract.Vec2(110, 143)
    assert grids[5] == contract.Vec2(110, 144)
    assert grids[6] == contract.Vec2(110, 145)
    assert grids[7] == contract.Vec2(110, 146)
    assert grids[8] == contract.Vec2(110, 147)
    assert grids[9] == contract.Vec2(110, 148)

    LOGGER.info (f"> all fetched grids match expected.")