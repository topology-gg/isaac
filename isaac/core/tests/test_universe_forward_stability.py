import pytest
import os
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
import asyncio
from Signer import Signer
import random
import logging

### Note: this test is based on the following parameters set in `design/constants.cairo`
CIV_SIZE = 0
UNIVERSE_COUNT = 0
UNIVERSE_INDEX_OFFSET = 777
###

LOGGER = logging.getLogger(__name__)
NUM_SIGNING_ACCOUNTS = CIV_SIZE * 2
DUMMY_PRIVATE = 9812304879503423120395
users = []

## Note to test logging:
## `--log-cli-level=INFO` to show logs

### Reference: https://github.com/perama-v/GoL2/blob/main/tests/test_GoL2_infinite.py
@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

@pytest.fixture(scope="module")
async def starknet():
    starknet = await Starknet.empty()
    return starknet

@pytest.fixture(scope='module')
async def account_factory(starknet):
    accounts = []
    LOGGER.info (f'> Deploying {NUM_SIGNING_ACCOUNTS} accounts...')
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

        LOGGER.info(f'> Account {i} is: {account.contract_address}')
    LOGGER.info('')

    return accounts

@pytest.fixture
async def block_info_mock(starknet):
    class Mock:
        def __init__(self, current_block_info):
            self.block_info = current_block_info

        def update(self, block_number, block_timestamp):
            starknet.state.state.block_info = BlockInfo(
            block_number, block_timestamp,
            self.block_info.gas_price,
            self.block_info.sequencer_address
        )

        def reset(self):
            starknet.state.state.block_info = self.block_info

        def set_block_number(self, block_number):
            starknet.state.state.block_info = BlockInfo(
                block_number, self.block_info.block_timestamp,
                self.block_info.gas_price,
                self.block_info.sequencer_address
            )

        def set_block_timestamp(self, block_timestamp):
            starknet.state.state.block_info = BlockInfo(
                self.block_info.block_number, block_timestamp,
                self.block_info.gas_price,
                self.block_info.sequencer_address
            )

    return Mock(starknet.state.state.block_info)

@pytest.mark.asyncio
async def test_universe (starknet, block_info_mock):

    # accounts = account_factory

    ## set l2 block
    block_info_mock.set_block_number(100)

    ## deploy contract
    contract = await starknet.deploy (source = 'contracts/universe/universe.cairo', constructor_calldata = [])
    LOGGER.info (f'> Universe deployed at {contract.contract_address}')

    ## set lobby address to 0x0
    ret = await contract.set_lobby_address_once(0).invoke()

    ## activate universe with fake player addresses
    ret = await contract.activate_universe(
        [11, 22, 33]
    ).invoke()

    ## Forward by N times
    block = 100
    N = 10

    for i in range(N):

        ## advance block by 20
        block += 20
        block_info_mock.set_block_number(block)

        ## check if universe can be forwarded
        ret = await contract.can_forward_universe().call()
        # LOGGER.info (f'> can_forward_universe: {ret.result}')
        assert ret.result.bool == 1

        ## forward the universe
        ret = await contract.anyone_forward_universe().invoke()

        LOGGER.info (f"> universe forwarded {i+1}/{N}.")
