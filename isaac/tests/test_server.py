import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer

NUM_SIGNING_ACCOUNTS = 1
DUMMY_PRIVATE = 9812304879503423120395
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
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

    # Admin is usually accounts[0], user_1 = accounts[1].
    # To build a transaction to call func_xyz(arg_1, arg_2)
    # on a TargetContract:

    # await Signer.send_transaction(
    #   account=accounts[1],
    #   to=<TargetContract's address>,
    #   selector_name='func_xyz',
    #   calldata=[arg_1, arg_2],
    #   nonce=current_nonce)

    # Note that nonce is an optional argument.
    return starknet, accounts

@pytest.mark.asyncio
async def test_server (account_factory):

    starknet, accounts = account_factory
    contracts = {}

    #########################
    ## Contract deployment ##
    #########################
    print(f'> Deploying contracts:')

    contract = await starknet.deploy (
        source = 'contracts/server.cairo',
        constructor_calldata = []
    )

    ## Player makes a move
    user = users[0]
    await user['signer'].send_transaction(
        account=user['account'],
        to=contract.contract_address,
        selector_name='device_deploy_utb',
        calldata=[]
    )

    res = await contract.client_view_UTB_ledger(0).call()
    print(f'client_view_UTB_ledger() returns: {res.result}')

    res = await contract.client_view_UTB_ledger(0).call()
    print(f'client_view_UTB_ledger() returns: {res.result}')
