import pytest
import os
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
import asyncio
from Signer import Signer
import random
import logging

### Note: this test is based on the following parameters set in `design/constants.cairo`
CIV_SIZE = 1
UNIVERSE_COUNT = 1
UNIVERSE_INDEX_OFFSET = 777
###

LOGGER = logging.getLogger(__name__)
NUM_SIGNING_ACCOUNTS = 1
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
async def test_lobby (account_factory, starknet, block_info_mock):

    accounts = account_factory

    #
    # Deploy universe
    #
    contract_universe = await starknet.deploy (source = 'contracts/universe/universe.cairo', constructor_calldata = [])
    LOGGER.info (f'> 1 universe contracts deployed')

    #
    # Deploy and configure lobby
    #
    contract_lobby = await starknet.deploy (source = 'contracts/lobby/lobby.cairo', constructor_calldata = [])
    await contract_lobby.set_universe_addresses_once ([
        contract_universe.contract_address
    ]).invoke ()
    LOGGER.info (f'> Lobby contract deployed at {contract_lobby.contract_address}; universe addresses configured')

    #
    # Deploy and configure mock DAO
    #
    contract_dao = await starknet.deploy (source = 'contracts/mocks/mock_skeletal_dao.cairo', constructor_calldata = [])
    await contract_dao.set_subject_address_once(contract_lobby.contract_address).invoke()
    LOGGER.info (f'> DAO contract deployed at {contract_dao.contract_address}')

    #
    # Set lobby address in  universe
    #
    await contract_universe.set_lobby_address_once (contract_lobby.contract_address).invoke ()
    LOGGER.info (f'> Register lobby address in every universe contract.')

    #
    # Set dao address in lobby
    #
    await contract_lobby.set_dao_address_once(contract_dao.contract_address).invoke()
    LOGGER.info (f'> Register dao address in lobby contract.')
    LOGGER.info('')

    ###

    ## Test invoking anyone_ask_to_queue() from 0x0 address => should revert
    LOGGER.info(f'> Test 0: asking to join queue from 0x0 address should revert.')
    with pytest.raises(Exception) as e_info:
        await contract_lobby.anyone_ask_to_queue().invoke()

    ## can-dispatch should return false
    LOGGER.info(f'> Test 1: can-dispatch should return 0 at start.')
    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 0

    ## users[0] and users[1] join queue
    LOGGER.info(f'> Test 2: 1 player join queue; can-dispatch should return 1.')
    player = users[0]
    await player['signer'].send_transaction(
        account = player['account'], to = contract_lobby.contract_address,
        selector_name = 'anyone_ask_to_queue',
        calldata=[]
    )

    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 1

    ret = await contract_lobby.queue_head_index_read().call()
    head_idx = ret.result.head_idx
    ret = await contract_lobby.queue_tail_index_read().call()
    tail_idx = ret.result.tail_idx
    assert (head_idx, tail_idx) == (0, 1)

    ## set l2 block
    block_info_mock.set_block_number(345)

    ## dispatch players to universe
    LOGGER.info(f"> Test 7: Invoke dispatch function once; check queue head & tail; check universe-0's civilization addresses, civ index, genesis block")
    ret_dispatch = await contract_lobby.anyone_dispatch_player_to_universe().invoke()

    LOGGER.info(f"-- events: {ret_dispatch.main_call_events}")

    ret = await contract_universe.civilization_index_read().call()
    assert ret.result.civ_idx == 1

    ret = await contract_universe.l2_block_at_genesis_read().call()
    assert ret.result.number == 345

    ret = await contract_lobby.universe_active_read(UNIVERSE_INDEX_OFFSET + 0).call()
    assert ret.result.is_active == 1

    for i in range(1):
        ret = await contract_universe.civilization_player_idx_to_address_read(i).call()
        LOGGER.info(f'  universe 0: player address at idx {i} = {ret.result.address}')
        assert ret.result.address == users[i]['account'].contract_address

        ret = await contract_universe.civilization_player_address_to_bool_read(users[i]['account'].contract_address).call()
        assert ret.result.bool == 1 # active
