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

    # Test strategy:
    # - user receives 10 iron harvesters, 10 iron refineries, and 10 UTBs from admin
    # - user constructs: R1 <= H1 => R2 (one harvester fanning out to 2 refineries)
    # - user constructs: R3 <= H2 => R4 (one harvester fanning out to 2 refineries)
    # - user constructs: H3 => R5 <= H4 (two harvesters fanning in to 1 refinery)
    # - user constructs: H5 => R6 <= H6 (two harvesters fanning in to 1 refinery)
    # - forward world, check resource balance against expectation
    # - remove H1, forward world, check resource balance against expectation
    # - remove R3, forward world, check resource balance against expectation
    # - remove R5, forward world, check resource balance against expectation
    # - remove H5, forward world, check resource balance against expectation

    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST PREP')
    LOGGER.info (f'> ------------')

    LOGGER.info (f'> admin gives user:')
    LOGGER.info (f'  10 fe-harv (H), 10 fe-refn (R), 10 UTBs;')
    #
    # admin gives user 10 iron harvesters
    #
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            2, # DEVICE_FE_HARV
            10
        ])

    #
    # admin gives user 10 iron refineries
    #
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            7, # DEVICE_FE_REFN
            10
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
    # user deploys R1 <= H1 => R2
    #
    LOGGER.info (f'> user deploys: R1 <= H1 => R2')
    R1_grid = (177, 85) # 177-178, 85-86
    H1_grid = (180, 85)
    R2_grid = (182, 85) # 182-183, 85-86

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
            1, 179, # locs_x
            1, 85 , # locs_y
            180, 85, 178, 85
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 181, # locs_x
            1, 85 , # locs_y
            180, 85, 182, 85
        ])

    #
    # user deploys R3 <= H2 => R4
    #
    LOGGER.info (f'> user deploys: R3 <= H2 => R4')
    R3_grid = (177, 50)
    H2_grid = (180, 50)
    R4_grid = (182, 50)

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
            R3_grid[0], R3_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            7, # DEVICE_FE_REFN
            R4_grid[0], R4_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 179, # locs_x
            1, 50 , # locs_y
            180, 50, 178, 50
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 181, # locs_x
            1, 50 , # locs_y
            180, 50, 182, 50
        ])

    #
    # user deploys H3 => R5 <= H4
    #
    LOGGER.info (f'> user deploys: H3 => R5 <= H4')
    H3_grid = (178, 30)
    R5_grid = (180, 30) # 180-181, 30-31
    H4_grid = (183, 30)

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            7, # DEVICE_FE_REFN
            R5_grid[0], R5_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            H3_grid[0], H3_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            H4_grid[0], H4_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 179, # locs_x
            1, 30 , # locs_y
            178, 30, 180, 30
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 182, # locs_x
            1, 30 , # locs_y
            183, 30, 181, 30
        ])

    #
    # user deploys H5 => R6 <= H6
    #
    LOGGER.info (f'> user deploys: H5 => R6 <= H6')
    H5_grid = (178, 10)
    R6_grid = (180, 10) # 180-181, 10-11
    H6_grid = (183, 10)

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            7, # DEVICE_FE_REFN
            R6_grid[0], R6_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            H5_grid[0], H5_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            H6_grid[0], H6_grid[1]
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 179, # locs_x
            1, 10 , # locs_y
            178, 10, 180, 10
        ])

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            user_addr,
            1, 182, # locs_x
            1, 10 , # locs_y
            183, 10, 181, 10
        ])

    # collect ids of deployed devices
    device_ids = {}
    names = ['H1', 'R1', 'R2', 'H2', 'R3', 'R4', 'R5', 'H3', 'H4', 'R6', 'H5', 'H6']
    for i,name in enumerate(names):
        ret = await contract.admin_read_device_deployed_emap(i).call()
        device_ids[name] = ret.result.emap_entry.id
    #     LOGGER.info (f'> {name} id: {ret.result.emap_entry.id}')
    # LOGGER.info ('')

    # ret = await contract.admin_read_utb_set_deployed_emap_size().call()
    # for i in range(ret.result.size):
    #     ret = await contract.admin_read_utb_set_deployed_emap(i).call()
    #     LOGGER.info (f'> UTB: {ret.result.emap_entry}')
    # LOGGER.info ('')

    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 1')
    LOGGER.info (f'> run `forward_world_micro()` and check resource balances ')
    LOGGER.info (f'> ------------')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H1']).call()
    assert ret.result.balance == +500-2, 'H1 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H2']).call()
    assert ret.result.balance == +500-2, 'H2 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H3']).call()
    assert ret.result.balance == +500-1, 'H3 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H4']).call()
    assert ret.result.balance == +500-1, 'H4 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H5']).call()
    assert ret.result.balance == +500-1, 'H5 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H6']).call()
    assert ret.result.balance == +500-1, 'H6 resource balance is incorrect'

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R1']).call()
    assert ret.result.balances.balance_resource_before_transform == 1
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R2']).call()
    assert ret.result.balances.balance_resource_before_transform == 1
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R3']).call()
    assert ret.result.balances.balance_resource_before_transform == 1
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R4']).call()
    assert ret.result.balances.balance_resource_before_transform == 1
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R5']).call()
    assert ret.result.balances.balance_resource_before_transform == 2
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R6']).call()
    assert ret.result.balances.balance_resource_before_transform == 2
    assert ret.result.balances.balance_resource_after_transform == 0

    LOGGER.info (f'> all resource balances are correct.\n')

    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 2')
    LOGGER.info (f'> remove H1, then run `forward_world_micro()` and check resource balances ')
    LOGGER.info (f'> ------------')

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_pickup_by_grid',
        calldata=[
            user_addr,
            H1_grid[0], H1_grid[1]
        ])
    LOGGER.info (f'> H1 picked up.')

    # ret = await contract.admin_read_utb_set_deployed_emap_size().call()
    # for i in range(ret.result.size):
    #     ret = await contract.admin_read_utb_set_deployed_emap(i).call()
    #     LOGGER.info (f'> UTB: {ret.result.emap_entry}')
    # LOGGER.info ('')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H1']).call()
    assert ret.result.balance == 0, 'H1 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H2']).call()
    assert ret.result.balance == +500-2 +500-2, 'H2 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H3']).call()
    assert ret.result.balance == +500-1 +500-1, 'H3 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H4']).call()
    assert ret.result.balance == +500-1 +500-1, 'H4 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H5']).call()
    assert ret.result.balance == +500-1 +500-1, 'H5 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H6']).call()
    assert ret.result.balance == +500-1 +500-1, 'H6 resource balance is incorrect'

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R1']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R2']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R3']).call()
    assert ret.result.balances.balance_resource_before_transform == 1 +1 -1
    assert ret.result.balances.balance_resource_after_transform == +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R4']).call()
    assert ret.result.balances.balance_resource_before_transform == 1 +1 -1
    assert ret.result.balances.balance_resource_after_transform == +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R5']).call()
    assert ret.result.balances.balance_resource_before_transform == 2 +2 -1
    assert ret.result.balances.balance_resource_after_transform == +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R6']).call()
    assert ret.result.balances.balance_resource_before_transform == 2 +2 -1
    assert ret.result.balances.balance_resource_after_transform == +1

    LOGGER.info (f'> all resource balances are correct.\n')


    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 3')
    LOGGER.info (f'> remove R3, then run `forward_world_micro()` and check resource balances ')
    LOGGER.info (f'> ------------')

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_pickup_by_grid',
        calldata=[
            user_addr,
            R3_grid[0], R3_grid[1]
        ])
    LOGGER.info (f'> R3 picked up.')

    # ret = await contract.admin_read_utb_set_deployed_emap_size().call()
    # for i in range(ret.result.size):
    #     ret = await contract.admin_read_utb_set_deployed_emap(i).call()
    #     LOGGER.info (f'> UTB: {ret.result.emap_entry}')
    # LOGGER.info ('')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H1']).call()
    assert ret.result.balance == 0, 'H1 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H2']).call()
    assert ret.result.balance == +500-2 +500-2 +500-1, 'H2 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H3']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1, 'H3 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H4']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1, 'H4 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H5']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1, 'H5 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H6']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1, 'H6 resource balance is incorrect'

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R1']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R2']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R3']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R4']).call()
    assert ret.result.balances.balance_resource_before_transform == 1 +1 -1 +1 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R5']).call()
    assert ret.result.balances.balance_resource_before_transform == 2 +2 -1 +2 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R6']).call()
    assert ret.result.balances.balance_resource_before_transform == 2 +2 -1 +2 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1

    LOGGER.info (f'> all resource balances are correct.\n')


    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 4')
    LOGGER.info (f'> remove R5, then run `forward_world_micro()` and check resource balances ')
    LOGGER.info (f'> ------------')

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_pickup_by_grid',
        calldata=[
            user_addr,
            R5_grid[0], R5_grid[1]
        ])
    LOGGER.info (f'> R5 picked up.')

    # ret = await contract.admin_read_utb_set_deployed_emap_size().call()
    # for i in range(ret.result.size):
    #     ret = await contract.admin_read_utb_set_deployed_emap(i).call()
    #     LOGGER.info (f'> UTB: {ret.result.emap_entry}')
    # LOGGER.info ('')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H1']).call()
    assert ret.result.balance == 0, 'H1 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H2']).call()
    assert ret.result.balance == +500-2 +500-2 +500-1 +500-1, 'H2 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H3']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500, 'H3 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H4']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500, 'H4 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H5']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500-1, 'H5 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H6']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500-1, 'H6 resource balance is incorrect'

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R1']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R2']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R3']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R4']).call()
    assert ret.result.balances.balance_resource_before_transform == 1 +1 -1 +1 -1 +1 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1 +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R5']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R6']).call()
    assert ret.result.balances.balance_resource_before_transform == 2 +2 -1 +2 -1 +2 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1 +1

    LOGGER.info (f'> all resource balances are correct.\n')


    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 5')
    LOGGER.info (f'> remove H5, then run `forward_world_micro()` and check resource balances ')
    LOGGER.info (f'> ------------')

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_pickup_by_grid',
        calldata=[
            user_addr,
            H5_grid[0], H5_grid[1]
        ])
    LOGGER.info (f'> H5 picked up.')

    # ret = await contract.admin_read_utb_set_deployed_emap_size().call()
    # for i in range(ret.result.size):
    #     ret = await contract.admin_read_utb_set_deployed_emap(i).call()
    #     LOGGER.info (f'> UTB: {ret.result.emap_entry}')
    # LOGGER.info ('')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H1']).call()
    assert ret.result.balance == 0, 'H1 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H2']).call()
    assert ret.result.balance == +500-2 +500-2 +500-1 +500-1 +500-1, 'H2 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H3']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500 +500, 'H3 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H4']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500 +500, 'H4 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H5']).call()
    assert ret.result.balance == 0, 'H5 resource balance is incorrect'

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_ids['H6']).call()
    assert ret.result.balance == +500-1 +500-1 +500-1 +500-1 +500-1, 'H6 resource balance is incorrect'

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R1']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R2']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R3']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R4']).call()
    assert ret.result.balances.balance_resource_before_transform == 1 +1 -1 +1 -1 +1 -1 +1 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1 +1 +1

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R5']).call()
    assert ret.result.balances.balance_resource_before_transform == 0
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_ids['R6']).call()
    assert ret.result.balances.balance_resource_before_transform == 2 +2 -1 +2 -1 +2 -1 +1 -1
    assert ret.result.balances.balance_resource_after_transform == +1 +1 +1 +1

    LOGGER.info (f'> all resource balances are correct.\n')