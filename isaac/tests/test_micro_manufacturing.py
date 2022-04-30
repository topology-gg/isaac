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

LOGGER = logging.getLogger(__name__)

NUM_SIGNING_ACCOUNTS = 2
DUMMY_PRIVATE = 9812304879503423120395
users = []

TEST_NUM_PER_CASE = 200
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100
SCALE_FP = 10**20

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
    player = users[1]

    starknet, accounts = account_factory
    LOGGER.info (f'> Deploying micro.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/micro.cairo',
        constructor_calldata = []
    )
    LOGGER.info ('')

    #
    # Admin gives player OPSF
    #
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            player['account'].contract_address,
            14, # OPSF
            1
        ]
    )

    #
    # Player deploys OPSF, and grab OPSF's device id
    #
    opsf_grid = {'x':50, 'y':150}
    await player['signer'].send_transaction(
        account = player['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            player['account'].contract_address,
            14, # OPSF
            opsf_grid['x'], opsf_grid['y']
        ])

    ret = await contract.admin_read_grid_stats( contract.Vec2(opsf_grid['x'], opsf_grid['y']) ).call()
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 14
    assert ret.result.grid_stat.deployed_device_owner == int(player['account'].contract_address)
    opsf_id = ret.result.grid_stat.deployed_device_id

    #
    # Test SPG manufacture before giving OPSF resources & energy
    #
    with pytest.raises(Exception) as e_info:
        await player['signer'].send_transaction(
            account = player['account'], to = contract.contract_address,
            selector_name = 'mock_opsf_build_device',
            calldata=[
                player['account'].contract_address,
                opsf_grid['x'], opsf_grid['y'],
                0, # manufacture SPG
                3
            ])
    LOGGER.info (f"> Player attempts to manufacture 3 x SPGs without having the resource or energy; transaction failed as expected.")

    #
    # Give OPSF resources, but not energy; player attempts building again; transaction failure expected
    #
    await contract.admin_write_opsf_deployed_id_to_resource_balances (
        opsf_id,
        3, # AL_REF
        50*3 + 77
    ).invoke()

    await contract.admin_write_opsf_deployed_id_to_resource_balances (
        opsf_id,
        7, # SI_REF
        100*3 + 99
    ).invoke()

    with pytest.raises(Exception) as e_info:
        await player['signer'].send_transaction(
            account = player['account'], to = contract.contract_address,
            selector_name = 'mock_opsf_build_device',
            calldata=[
                player['account'].contract_address,
                opsf_grid['x'], opsf_grid['y'],
                0, # manufacture SPG
                3
            ])
    LOGGER.info (f"> Player attempts to manufacture 3 x SPGs without having the energy; transaction failed as expected.")

    #
    # Give OPSF energy; player attempts building again; transaction should succeed
    #
    await contract.admin_write_device_deployed_id_to_energy_balance (
        opsf_id,
        1*3 + 555
    ).invoke()

    await player['signer'].send_transaction(
        account = player['account'], to = contract.contract_address,
        selector_name = 'mock_opsf_build_device',
        calldata=[
            player['account'].contract_address,
            opsf_grid['x'], opsf_grid['y'],
            0, # manufacture SPG
            3
        ])
    LOGGER.info (f"> Player attempts to manufacture 3 x SPGs; transaction succeeded as expected.")

    #
    # Check player's undeployed device balance, and check OPSF resource & energy balance
    #
    ret = await contract.admin_read_device_undeployed_ledger (
        player['account'].contract_address,
        0
    ).call()
    assert ret.result.amount == 3
    LOGGER.info (f"> Player has 3 x SPGs undeployed as expected.")

    ret = await contract.admin_read_opsf_deployed_id_to_resource_balances (
        opsf_id,
        3
    ).call()
    assert ret.result.balance == 77

    ret = await contract.admin_read_opsf_deployed_id_to_resource_balances (
        opsf_id,
        7
    ).call()
    assert ret.result.balance == 99

    ret = await contract.admin_read_device_deployed_id_to_energy_balance (
        opsf_id
    ).call()
    assert ret.result.energy == 555

    LOGGER.info (f"> OPSF has the precise amount of resource and energy left as expected.")