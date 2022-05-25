import pytest
import os
from starkware.starknet.testing.starknet import Starknet
from starkware.starknet.business_logic.state.state import BlockInfo
import asyncio
from Signer import Signer
import random
import logging

LOGGER = logging.getLogger(__name__)

YES = 1
NO = 0
NUM_SIGNING_ACCOUNTS = 4 ## 2 angel and 2 players
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
async def test_dao (account_factory, starknet, block_info_mock):

    accounts = account_factory
    angel_0  = users[0]
    angel_1  = users[1]
    player_0 = users[2]
    player_1 = users[3]

    contract_fsm_subject = await starknet.deploy (source = 'contracts/fsm.cairo', constructor_calldata = [111])
    LOGGER.info (f'> Deployed fsm.cairo for subject at {contract_fsm_subject.contract_address}')

    contract_fsm_charter = await starknet.deploy (source = 'contracts/fsm.cairo', constructor_calldata = [222])
    LOGGER.info (f'> Deployed fsm.cairo for charter at {contract_fsm_charter.contract_address}')

    contract_fsm_angel = await starknet.deploy (source = 'contracts/fsm.cairo', constructor_calldata = [333])
    LOGGER.info (f'> Deployed fsm.cairo for angel at {contract_fsm_angel.contract_address}')

    contract_charter = await starknet.deploy (source = 'contracts/charter.cairo', constructor_calldata = [])
    LOGGER.info (f'> Deployed charter.cairo at {contract_charter.contract_address}')

    contract_dao = await starknet.deploy (
        source = 'contracts/dao.cairo',
        constructor_calldata = [
            1234567, contract_charter.contract_address, angel_0['account'].contract_address,
            contract_fsm_subject.contract_address,
            contract_fsm_charter.contract_address,
            contract_fsm_angel.contract_address
        ]
    )
    LOGGER.info (f'> Deploy dao.cairo at {contract_dao.contract_address}')
    LOGGER.info ('')

    #
    # Register dao address in every fsm contract
    #
    LOGGER.info (f'> Initialize dao address in every fsm contract')
    await contract_fsm_subject.init_owner_dao_address_once(contract_dao.contract_address).invoke()
    await contract_fsm_charter.init_owner_dao_address_once(contract_dao.contract_address).invoke()
    await contract_fsm_angel.init_owner_dao_address_once(contract_dao.contract_address).invoke()

    #
    # Admin gives player_0 and player_1 100 voices each
    #
    LOGGER.info (f'> Admin gives 100 voices to each players')
    await contract_dao.admin_write_player_voices_available(player_0['account'].contract_address, 100).invoke()
    await contract_dao.admin_write_player_voices_available(player_1['account'].contract_address, 100).invoke()
    LOGGER.info ('')

    #
    # Set custom block number
    #
    block_info_mock.set_block_number(123)
    ret = await contract_fsm_subject.return_current_block_number().call()
    assert ret.result.number == 123

    #
    # Test probe_can_end_vote()
    #
    LOGGER.info (f'> Test 1: Call probe_can_end_vote()')
    ret = await contract_dao.probe_can_end_vote().call()
    can_end_vote = ret.result.bool
    assert can_end_vote == 0

    #
    # The wrong angel initiates a proposal
    #
    LOGGER.info (f'> Test 2: The wrong angel initiates a proposal')
    with pytest.raises(Exception) as e_info:
        await angel_1['signer'].send_transaction(
            account = angel_1['account'], to = contract_dao.contract_address,
            selector_name = 'angel_propose_new_subject',
            calldata=[0])

    #
    # The current angel initiates three proposals; charter unchanged, angel => angel_1
    #
    LOGGER.info (f'> Test 3: The current angel initiates three proposals')
    await angel_0['signer'].send_transaction(
        account = angel_0['account'], to = contract_dao.contract_address,
        selector_name = 'angel_propose_new_subject',
        calldata=[0]
    )
    await angel_0['signer'].send_transaction(
        account = angel_0['account'], to = contract_dao.contract_address,
        selector_name = 'angel_propose_new_charter',
        calldata=[contract_charter.contract_address]
    )
    await angel_0['signer'].send_transaction(
        account = angel_0['account'], to = contract_dao.contract_address,
        selector_name = 'angel_propose_new_angel',
        calldata=[angel_1['account'].contract_address]
    )

    #
    # View each proposal from respective FSM
    #
    LOGGER.info (f'> Test 4: View each proposal from respective FSM')
    ret = await contract_fsm_subject.current_proposal_read().call()
    LOGGER.info (f'> - subject proposal: {ret.result.proposal}')
    ret = await contract_fsm_charter.current_proposal_read().call()
    LOGGER.info (f'> - charter proposal: {ret.result.proposal}')
    ret = await contract_fsm_angel.current_proposal_read().call()
    LOGGER.info (f'> - angel proposal: {ret.result.proposal}')

    #
    # Forward block by 719 blocks, which is 1 block short of proposal period
    #
    block_info_mock.set_block_number(123 + 719)
    ret = await contract_fsm_subject.return_current_block_number().call()
    assert ret.result.number == 123 + 719

    #
    # Make two players vote such that
    # subject proposal fails, charter proposal passes, angel proposal passes,
    # leave both players with some votes for the next test
    #
    LOGGER.info (f'> Test 5: Both players cast their votes; check votes left afterwards for both players')

    ## vote on subject proposal, YES == NO
    await player_0['signer'].send_transaction(
        account = player_0['account'], to = contract_dao.contract_address,
        selector_name = 'player_vote_new_subject',
        calldata=[1, NO]
    )
    await player_1['signer'].send_transaction(
        account = player_1['account'], to = contract_dao.contract_address,
        selector_name = 'player_vote_new_subject',
        calldata=[1, YES]
    )

    ## vote on charter proposal, YES > NO
    await player_0['signer'].send_transaction(
        account = player_0['account'], to = contract_dao.contract_address,
        selector_name = 'player_vote_new_charter',
        calldata=[7, YES]
    )
    await player_1['signer'].send_transaction(
        account = player_1['account'], to = contract_dao.contract_address,
        selector_name = 'player_vote_new_charter',
        calldata=[2, NO]
    )

    ## vote on angel proposal, YES > NO
    await player_0['signer'].send_transaction(
        account = player_0['account'], to = contract_dao.contract_address,
        selector_name = 'player_vote_new_angel',
        calldata=[7, YES]
    )
    await player_1['signer'].send_transaction(
        account = player_1['account'], to = contract_dao.contract_address,
        selector_name = 'player_vote_new_angel',
        calldata=[3, NO]
    )

    #
    # Check player available votes against expected
    #
    ret = await contract_dao.player_voices_available_read(player_0['account'].contract_address).call()
    assert ret.result.voices == 100 - 1**2 - 7**2 - 7**2 # 1 voice left
    ret = await contract_dao.player_voices_available_read(player_1['account'].contract_address).call()
    assert ret.result.voices == 100 - 1**2 - 2**2 - 3**2 # 86 voices left

    #
    # Make sure can_end_vote is still false
    #
    ret = await contract_dao.probe_can_end_vote().call()
    can_end_vote = ret.result.bool
    assert can_end_vote == 0

    #
    # Cast nonexistent vote
    #
    LOGGER.info (f'> Test 6: Player 0 attempts to cast more votes than she can')
    with pytest.raises(Exception) as e_info:
        await player_0['signer'].send_transaction(
            account = player_0['account'], to = contract_dao.contract_address,
            selector_name = 'player_vote_new_subject',
            calldata=[2, NO]
        )

    #
    # Forward block by 1 more block, which reaches all proposal period
    #
    block_info_mock.set_block_number(123 + 719 + 1)
    ret = await contract_fsm_subject.return_current_block_number().call()
    assert ret.result.number == 123 + 719 + 1

    #
    # can_end_vote should be true now
    #
    ret = await contract_dao.probe_can_end_vote().call()
    can_end_vote = ret.result.bool
    assert can_end_vote == 1

    #
    # Cast a vote after proposal period reached
    #
    LOGGER.info (f'> Test 7: Player 1 attempts a vote outside proposal period')
    with pytest.raises(Exception) as e_info:
        await player_1['signer'].send_transaction(
            account = player_1['account'], to = contract_dao.contract_address,
            selector_name = 'player_vote_new_subject',
            calldata=[1, NO]
        )

    #
    # Execute proposals based on voting results
    #
    LOGGER.info (f"> Test 8: anyone_execute_end_vote(); check dao's votable addresses against expected")
    await contract_dao.anyone_execute_end_vote().invoke()
    ret = await contract_dao.votable_addresses_read().call()
    assert ret.result.addresses.subject == 1234567
    assert ret.result.addresses.charter == contract_charter.contract_address
    assert ret.result.addresses.angel == angel_1['account'].contract_address

    #
    # Make sure can_end_vote goes false now
    #
    ret = await contract_dao.probe_can_end_vote().call()
    can_end_vote = ret.result.bool
    assert can_end_vote == 0

    #
    # The old angel attempts to create proposal
    #
    LOGGER.info (f'> Test 9: Old angel attempts to create proposal, which should fail')
    with pytest.raises(Exception) as e_info:
        await angel_0['signer'].send_transaction(
            account = angel_0['account'], to = contract_dao.contract_address,
            selector_name = 'angel_propose_new_subject',
            calldata=[0]
        )

    #
    # The new angel attempts to create proposal
    #
    LOGGER.info (f'> Test 10: New angel attempts to create proposal, which should pass')
    await angel_1['signer'].send_transaction(
        account = angel_1['account'], to = contract_dao.contract_address,
        selector_name = 'angel_propose_new_subject',
        calldata=[0]
    )
