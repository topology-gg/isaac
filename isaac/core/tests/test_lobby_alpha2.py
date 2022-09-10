import pytest
import os
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
import asyncio
from Signer import Signer
import random
import logging

### Note: this test is based on the following parameters set in `design/constants.cairo`
CIV_SIZE = 3
UNIVERSE_COUNT = 1
UNIVERSE_INDEX_OFFSET = 777
###

LOGGER = logging.getLogger(__name__)
NUM_SIGNING_ACCOUNTS = CIV_SIZE
DUMMY_PRIVATE = 9812304879503423120395
users = []

## Note to test logging:
## `--log-cli-level=INFO` to show logs

### Reference: https://github.com/perama-v/GoL2/blob/main/tests/test_GoL2_infinite.py
# @pytest.fixture(scope='module', autouse=True)
@pytest.fixture
def event_loop():
    return asyncio.new_event_loop()

# @pytest.fixture(scope="module", autouse=True)
@pytest.fixture
async def starknet():
    starknet = await Starknet.empty()
    return starknet

# @pytest.fixture(scope='module', autouse=True)
@pytest.fixture
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
async def test_lobby (account_factory, starknet, block_info_mock):

    # accounts = account_factory
    starknet = await Starknet.empty()
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

    #
    # Deploy universe + lobby
    #
    contract_universe = await starknet.deploy (source = 'contracts/universe/universe.cairo', constructor_calldata = [])
    contract_lobby    = await starknet.deploy (source = 'contracts/lobby/lobby.cairo', constructor_calldata = [])
    LOGGER.info (f'> universe + lobby deployed')

    #
    # Configure universe + lobby minimally
    #
    await contract_universe.set_lobby_address_once (contract_lobby.contract_address).invoke ()
    await contract_lobby.set_universe_addresses_once ([contract_universe.contract_address]).invoke ()
    await contract_lobby.init_give_invitations_once (
        [user['account'].contract_address for user in users]
    ).invoke ()
    LOGGER.info (f'> universe + lobby configured')

    #
    # 3 players join queue
    #
    for i in range(NUM_SIGNING_ACCOUNTS):
        player = users[i]
        await player['signer'].send_transaction(
            account = player['account'], to = contract_lobby.contract_address,
            selector_name = 'anyone_ask_to_queue',
            calldata=[]
        )
    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 1

    #
    # dispatch players to universe
    #
    ret_dispatch = await contract_lobby.anyone_dispatch_player_to_universe().invoke()
    LOGGER.info(f"-- events: {ret_dispatch.main_call_events}")

    #
    # Confirm universe is active
    #
    ret = await contract_lobby.universe_active_read(777).call()
    LOGGER.info(ret)
    assert ret.result.is_active == 1
    ret = await contract_universe.civilization_index_read().call()
    LOGGER.info(ret)
    assert ret.result.civ_idx == 1
