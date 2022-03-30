import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)

NUM_SIGNING_ACCOUNTS = 4
DUMMY_PRIVATE = 9812304879503423120395
users = []

TEST_NUM_PER_CASE = 100
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

    starknet, accounts = account_factory
    LOGGER.info (f'> Deploying micro.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/micro.cairo',
        constructor_calldata = []
    )
    LOGGER.info ('')

    #
    # 1. admin gives three users 1 iron harvester, 1 iron refinery, and N utb each.
    #    => admin checks ledger
    #
    N_UTB = 10
    LOGGER.info (f'> STEP 1: admin gives three users 1 iron harvester, 1 iron refinery, and {N_UTB} utb each; admin checks ledger.')
    for user in users[1:]:
        await admin['signer'].send_transaction(
            account = admin['account'], to = contract.contract_address,
            selector_name = 'admin_write_device_undeployed_ledger',
            calldata=[
                user['account'].contract_address,
                2, # DEVICE_FE_HARV
                1
            ]
        )
        await admin['signer'].send_transaction(
            account = admin['account'], to = contract.contract_address,
            selector_name = 'admin_write_device_undeployed_ledger',
            calldata=[
                user['account'].contract_address,
                7, # DEVICE_FE_REFN
                1
            ]
        )
        await admin['signer'].send_transaction(
            account = admin['account'], to = contract.contract_address,
            selector_name = 'admin_write_device_undeployed_ledger',
            calldata=[
                user['account'].contract_address,
                12, # DEVICE_UTB
                N_UTB
            ]
        )
    for i,user in enumerate(users[1:]):
        for device_type in [2, 7, 12]:
            ret = await contract.admin_read_device_undeployed_ledger(
                owner = user['account'].contract_address,
                type = device_type
            ).call()
            LOGGER.info (f'> user {i} has {ret.result.amount} undeployed device of type {device_type}')
            if device_type == 12:
                assert ret.result.amount == N_UTB
            else:
                assert ret.result.amount == 1
    LOGGER.info ('')

    #
    # 2. two users deploy their iron harvester & refinery
    #    => admin checks GridStat and emap
    #
    user1_harvester_grid = (150, 150)
    user1_refinery_grid  = (155, 150)
    user2_harvester_grid = (99, 100)
    user2_refinery_grid  = (100, 99)
    LOGGER.info (f'> STEP 2: user 1 & 2 each deploys their iron harvester & refinery; admin checks GridStat and the enumerable map for deployed devices.')
    await users[1]['signer'].send_transaction(
        account = users[1]['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            users[1]['account'].contract_address,
            2, # DEVICE_FE_HARV
            user1_harvester_grid[0],
            user1_harvester_grid[1]
        ])
    await users[1]['signer'].send_transaction(
        account = users[1]['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            users[1]['account'].contract_address,
            7, # DEVICE_FE_REFN
            user1_refinery_grid[0],
            user1_refinery_grid[1]
        ])
    await users[2]['signer'].send_transaction(
        account = users[2]['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            users[2]['account'].contract_address,
            2, # DEVICE_FE_HARV
            user2_harvester_grid[0],
            user2_harvester_grid[1]
        ])
    await users[2]['signer'].send_transaction(
        account = users[2]['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            users[2]['account'].contract_address,
            7, # DEVICE_FE_REFN
            user2_refinery_grid[0],
            user2_refinery_grid[1]
        ])

    ret = await contract.admin_read_grid_stats( contract.Vec2(user1_harvester_grid[0], user1_harvester_grid[1]) ).call()
    LOGGER.info (f'> user1_harvester_grid says {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 2
    assert ret.result.grid_stat.deployed_device_owner == int(users[1]['account'].contract_address)

    ret = await contract.admin_read_grid_stats( contract.Vec2(user1_refinery_grid[0], user1_refinery_grid[1]) ).call()
    LOGGER.info (f'> user1_refinery_grid says {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 7
    assert ret.result.grid_stat.deployed_device_owner == int(users[1]['account'].contract_address)

    ret = await contract.admin_read_grid_stats( contract.Vec2(user2_harvester_grid[0], user2_harvester_grid[1]) ).call()
    LOGGER.info (f'> user2_harvester_grid says {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 2
    assert ret.result.grid_stat.deployed_device_owner == int(users[2]['account'].contract_address)

    ret = await contract.admin_read_grid_stats( contract.Vec2(user2_refinery_grid[0], user2_refinery_grid[1]) ).call()
    LOGGER.info (f'> user2_refinery_grid says {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 7
    assert ret.result.grid_stat.deployed_device_owner == int(users[2]['account'].contract_address)

    ret = await contract.admin_read_device_deployed_emap_size().call()
    LOGGER.info (f'> device_deployed_emap_size = {ret.result}')
    assert ret.result.size == 4

    for i in range(ret.result.size):
        ret = await contract.admin_read_device_deployed_emap(i).call()
        LOGGER.info (f'> emap entry at {i}: {ret.result}')

    #
    # 3. two users deploy their utb's contiguously to connect their harvester-refinery pair
    #    => admin checks emap
    #

    # 4. (should raise exception) the third user picks up user1's deployed harvester and refinery

    # 5. (should raise exception) the third user picks up user1's deployed utb's

    # 6. (should raise exception) the third user deploys iron harvester on the grid of user1's deployed harvester

    # 7. (should raise exception) the third user deploys iron harvester on the grid of user1's utb

    # 8. the third user deploys her iron harvester & refinery
    #    => admin checks emap

    # 9. (should raise exception) the third user deploys her utb's contiguously to connect their harvester-refinery pair but crossing over
    #                             user1's utb path

    # 10. (should raise exception) user1 attempt to deploy another iron harvester

    # 11. TODO: pick up devices
    # 10. TODO: forward_world_micro ()

    # #############################
    # # Test `mock_device_deploy()`
    # #############################
    # print('> Testing mock_device_deploy()')




    # LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: grid {grid} on face {face} and edge {edge}, output: {ret.result}')
