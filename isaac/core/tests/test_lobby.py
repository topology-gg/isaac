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
UNIVERSE_COUNT = 3
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
async def test_lobby (account_factory, starknet, block_info_mock):

    accounts = account_factory

    # Testing strategy
    # 0. deploy mock-universes and hook them up with lobby; deploy mock-dao and hook it up with lobby
    # 1. test players joining queue working fine
    # 2. test yagi proving can-dispatch and execute-dispatch
    # 3. check player addresses in activated mock-universe matching expected
    # 4. let mock-universe call lobby's `universe_report_play()`

    contract_universes = []
    for _ in range(UNIVERSE_COUNT):
        contract = await starknet.deploy (source = 'contracts/mocks/mock_skeletal_universe.cairo', constructor_calldata = [])
        contract_universes.append (contract)
    LOGGER.info (f'> {UNIVERSE_COUNT} universe contracts deployed')

    lobby_constructor_calldata = [UNIVERSE_COUNT] + [c.contract_address for c in contract_universes] # array length followed by array elements
    contract_lobby = await starknet.deploy (source = 'contracts/lobby/lobby.cairo', constructor_calldata = lobby_constructor_calldata)
    LOGGER.info (f'> Lobby contract deployed with universe addresses recorded at {contract_lobby.contract_address}')

    contract_dao = await starknet.deploy (source = 'contracts/mocks/mock_skeletal_dao.cairo', constructor_calldata = [])
    await contract_dao.set_subject_address_once(contract_lobby.contract_address).invoke()
    LOGGER.info (f'> DAO contract deployed at {contract_dao.contract_address}; lobby address registered as subject address')

    for contract in contract_universes:
        await contract.set_lobby_address_once(contract_lobby.contract_address).invoke()
    LOGGER.info (f'> Register lobby address in every universe contract.')

    await contract_lobby.set_dao_address_once(contract_dao.contract_address).invoke()
    LOGGER.info (f'> Register dao address in lobby contract.')
    LOGGER.info('')

    ## Test invoking anyone_ask_to_queue() from 0x0 address => should revert
    LOGGER.info(f'> Test 0: asking to join queue from 0x0 address should revert.')
    with pytest.raises(Exception) as e_info:
        await contract_lobby.anyone_ask_to_queue().invoke()

    ## can-dispatch should return false
    LOGGER.info(f'> Test 1: can-dispatch should return 0 at start.')
    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 0

    ## users[0] and users[1] join queue
    LOGGER.info(f'> Test 2: Two players join queue; can-dispatch should still return 0.')
    for player in users[0:2]:
        await player['signer'].send_transaction(
            account = player['account'], to = contract_lobby.contract_address,
            selector_name = 'anyone_ask_to_queue',
            calldata=[]
        )

    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 0

    ## users[1] attempts joining the queue again => should fail
    LOGGER.info(f'> Test 3: A player attempts to rejoin queue => tx should fail.')
    with pytest.raises(Exception) as e_info:
        await users[1]['signer'].send_transaction(
            account = users[1]['account'], to = contract_lobby.contract_address,
            selector_name = 'anyone_ask_to_queue',
            calldata=[]
        )

    ## confirm storage `queue_address_to_index`, `queue_head_index` and `queue_tail_index` match expected
    LOGGER.info(f'> Test 4: Confirm queue address=>index, head index, and tail index all match expected.')
    ret = await contract_lobby.queue_address_to_index_read(users[0]['account'].contract_address).call()
    users0_idx = ret.result.idx
    ret = await contract_lobby.queue_address_to_index_read(users[1]['account'].contract_address).call()
    users1_idx = ret.result.idx
    assert (users0_idx, users1_idx) == (1, 2) # queue idx starts from 1; 0 is reserved from not-in-queue

    ret = await contract_lobby.queue_head_index_read().call()
    head_idx = ret.result.head_idx
    ret = await contract_lobby.queue_tail_index_read().call()
    tail_idx = ret.result.tail_idx
    assert (head_idx, tail_idx) == (0, 2)

    ## users[2] joins queue
    LOGGER.info(f'> Test 5: The 3rd player joins queue; can-dispatch should return 1 now.')
    await users[2]['signer'].send_transaction(
        account = users[2]['account'], to = contract_lobby.contract_address,
        selector_name = 'anyone_ask_to_queue',
        calldata=[]
    )
    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 1

    ## users[3] and users[4] join queue
    LOGGER.info(f'> Test 6: The 4th and 5th player join queue; can-dispatch should still return 1; check queue head & tail')
    for user in users[3:5]:
        await user['signer'].send_transaction(
            account = user['account'], to = contract_lobby.contract_address,
            selector_name = 'anyone_ask_to_queue',
            calldata=[]
        )
    ret = await contract_lobby.can_dispatch_player_to_universe().call()
    assert ret.result.bool == 1

    ret = await contract_lobby.queue_head_index_read().call()
    head_idx = ret.result.head_idx
    ret = await contract_lobby.queue_tail_index_read().call()
    tail_idx = ret.result.tail_idx
    assert (head_idx, tail_idx) == (0, 5)

    ## set l2 block
    block_info_mock.set_block_number(345)

    ## dispatch players to universe
    LOGGER.info(f"> Test 7: Invoke dispatch function once; check queue head & tail; check universe-0's civilization addresses, civ index, genesis block")
    ret_dispatch = await contract_lobby.anyone_dispatch_player_to_universe().invoke()
    # LOGGER.info(f"-- events: {ret_dispatch.main_call_events}")

    ret = await contract_lobby.queue_head_index_read().call()
    head_idx = ret.result.head_idx
    ret = await contract_lobby.queue_tail_index_read().call()
    tail_idx = ret.result.tail_idx
    assert (head_idx, tail_idx) == (3, 5)

    ret = await contract_universes[0].civilization_index_read().call()
    assert ret.result.civ_idx == 1

    ret = await contract_universes[0].l2_block_at_genesis_read().call()
    assert ret.result.number == 345

    ret = await contract_lobby.universe_active_read(UNIVERSE_INDEX_OFFSET + 0).call()
    assert ret.result.is_active == 1
    ret = await contract_lobby.universe_active_read(UNIVERSE_INDEX_OFFSET + 1).call()
    assert ret.result.is_active == 0
    ret = await contract_lobby.universe_active_read(UNIVERSE_INDEX_OFFSET + 2).call()
    assert ret.result.is_active == 0

    for i in range(3):
        ret = await contract_universes[0].civilization_player_idx_to_address_read(i).call()
        LOGGER.info(f'  universe 0: player address at idx {i} = {ret.result.address}')
        assert ret.result.address == users[i]['account'].contract_address

        ret = await contract_universes[0].civilization_player_address_to_bool_read(users[i]['account'].contract_address).call()
        assert ret.result.bool == 1 # active

    ## check the other universe
    LOGGER.info(f"> Test 8: Make sure universe-1's status is unchanged")

    ret = await contract_universes[1].civilization_index_read().call()
    assert ret.result.civ_idx == 0

    ret = await contract_universes[1].l2_block_at_genesis_read().call()
    assert ret.result.number == 0

    for i in range(3):
        ret = await contract_universes[1].civilization_player_idx_to_address_read(i).call()
        assert ret.result.address == 0

    ## prepare universe 0 - give the second player has-launch-ndpe
    await contract_universes[0].test_write_civilization_player_address_to_has_launched_ndpe(
        users[1]['account'].contract_address,
        1
    ).invoke()

    ## terminate universe, which should notify lobby; check accordingly
    LOGGER.info(f"> Test 9: Given users[1] launched ndpe, terminate universe; check universe civ empty; check dao votes against expected")
    ret = await contract_universes[0].test_terminate_universe_and_notify_lobby(
        bool_universe_escape_condition_met = 1
    ).invoke()

    for i in range(3):
        ret = await contract_universes[0].civilization_player_idx_to_address_read(i).call()
        assert ret.result.address == 0 # cleared

        ret = await contract_universes[0].civilization_player_address_to_bool_read(users[i]['account'].contract_address).call()
        assert ret.result.bool == 0 # inactive

    player_adr = users[0]['account'].contract_address
    ret = await contract_dao.view_player_votes_available(player_adr).call()
    LOGGER.info(f'  dao: player {player_adr} has {ret.result.votes} votes')
    assert ret.result.votes == 7

    player_adr = users[1]['account'].contract_address
    ret = await contract_dao.view_player_votes_available(player_adr).call()
    LOGGER.info(f'  dao: player {player_adr} has {ret.result.votes} votes')
    assert ret.result.votes == 25

    player_adr = users[2]['account'].contract_address
    ret = await contract_dao.view_player_votes_available(player_adr).call()
    LOGGER.info(f'  dao: player {player_adr} has {ret.result.votes} votes')
    assert ret.result.votes == 7

    player_adr = users[3]['account'].contract_address
    ret = await contract_dao.view_player_votes_available(player_adr).call()
    LOGGER.info(f'  dao: player {player_adr} has {ret.result.votes} votes')
    assert ret.result.votes == 0

    player_adr = users[4]['account'].contract_address
    ret = await contract_dao.view_player_votes_available(player_adr).call()
    LOGGER.info(f'  dao: player {player_adr} has {ret.result.votes} votes')
    assert ret.result.votes == 0