import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)

NUM_SIGNING_ACCOUNTS = 0
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
async def test_masyu (account_factory):

    # admin = users[0]

    starknet, accounts = account_factory

    LOGGER.info (f'> Deploying s2m.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/s2m.cairo',
        constructor_calldata = []
    )

    #
    # toy solutions
    #
    await contract.solve (
        [
            0,1,2,3,11,10,2,1,9,8
        ]

    ).invoke()


    # await admin['signer'].send_transaction(
    #     account = admin['account'], to = contract.contract_address,
    #     selector_name = 'admin_give_undeployed_device',
    #     calldata=[
    #         user['account'].contract_address,
    #         2, # DEVICE_FE_HARV
    #         1
    #     ]
    # )
