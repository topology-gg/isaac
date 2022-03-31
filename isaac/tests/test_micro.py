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
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 1')
    LOGGER.info (f'> admin gives three users 1 iron harvester, 1 iron refinery, and {N_UTB} utb each; admin checks ledger.')
    LOGGER.info (f'> ------------')
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
    LOGGER.info ('\n')

    #
    # 2. two users deploy their iron harvester & refinery
    #    => admin checks GridStat and emap
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 2')
    LOGGER.info (f'> user 1 & 2 each deploys their iron harvester & refinery; admin checks GridStat and the enumerable map for deployed devices.')
    LOGGER.info (f'> ------------')
    user1_harvester_grid = (150, 150)
    user1_refinery_grid  = (155, 150)
    user2_harvester_grid = (99, 100)
    user2_refinery_grid  = (100, 99)
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
    LOGGER.info (f'> user1_harvester_grid has {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 2
    assert ret.result.grid_stat.deployed_device_owner == int(users[1]['account'].contract_address)
    user1_harvester_id = ret.result.grid_stat.deployed_device_id

    ret = await contract.admin_read_grid_stats( contract.Vec2(user1_refinery_grid[0], user1_refinery_grid[1]) ).call()
    LOGGER.info (f'> user1_refinery_grid has {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 7
    assert ret.result.grid_stat.deployed_device_owner == int(users[1]['account'].contract_address)
    user1_refinery_id = ret.result.grid_stat.deployed_device_id

    ret = await contract.admin_read_grid_stats( contract.Vec2(user2_harvester_grid[0], user2_harvester_grid[1]) ).call()
    LOGGER.info (f'> user2_harvester_grid has {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 2
    assert ret.result.grid_stat.deployed_device_owner == int(users[2]['account'].contract_address)
    user2_harvester_id = ret.result.grid_stat.deployed_device_id

    ret = await contract.admin_read_grid_stats( contract.Vec2(user2_refinery_grid[0], user2_refinery_grid[1]) ).call()
    LOGGER.info (f'> user2_refinery_grid has {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 7
    assert ret.result.grid_stat.deployed_device_owner == int(users[2]['account'].contract_address)
    user2_refinery_id = ret.result.grid_stat.deployed_device_id

    ret = await contract.admin_read_device_deployed_emap_size().call()
    LOGGER.info (f'> device_deployed_emap_size = {ret.result.size}')
    assert ret.result.size == 4

    for i in range(ret.result.size):
        ret = await contract.admin_read_device_deployed_emap(i).call()
        LOGGER.info (f'> deployed-device emap entry at {i}: {ret.result}')
    LOGGER.info ('\n')

    #
    # 3. user1 and user2 deploy their utb's contiguously to connect their harvester-refinery pair
    #    => admin checks GridStat and emap
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 3')
    LOGGER.info (f'> user1 and user2 deploy their utb contiguously to connect their harvester-refinery pair; admin checks GridStat and emap.')
    LOGGER.info (f'> ------------')

    # user1 needs to connect (150, 150) and (155, 150)
    await users[1]['signer'].send_transaction(
        account = users[1]['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            users[1]['account'].contract_address, # caller
            4, 151, 152, 153, 154, # locs_x
            4, 150, 150, 150, 150, # locs_y
            150, 150, 155, 150
        ])

    # get utb-set label
    labels = []
    for x,y in zip ([151, 152, 153, 154], [150, 150, 150, 150]):
        ret = await contract.admin_read_grid_stats(
            contract.Vec2(x,y)
        ).call()
        assert ret.result.grid_stat.populated == 1
        assert ret.result.grid_stat.deployed_device_type == 12 # utb
        assert ret.result.grid_stat.deployed_device_owner ==users[1]['account'].contract_address
        labels.append(ret.result.grid_stat.deployed_device_id)
    assert len( set(labels) ) == 1 # all utb in this utb-set has the same label
    label = labels[0]
    LOGGER.info (f'> user1 connected her devices with utb-set of label {label}.')

    for i in range(2):
        ret = await contract.admin_read_device_deployed_emap(i).call()
        assert ret.result.emap_entry.tethered_to_utb == 1
        assert ret.result.emap_entry.utb_label == label
        LOGGER.info (f'> deployed-device emap entry at {i}: {ret.result}')
    LOGGER.info (f'> user1 deployed his devices.')
    LOGGER.info ('')

    # user2 needs to connect (99, 100) and (100, 99)
    await users[2]['signer'].send_transaction(
        account = users[2]['account'], to = contract.contract_address,
        selector_name = 'mock_utb_deploy',
        calldata=[
            users[2]['account'].contract_address, # caller
            5, 99, 100, 101, 101, 101, # locs_x
            5, 101, 101, 101, 100, 99, # locs_y
            99, 100, 100, 99
        ])

    # get utb-set label
    labels = []
    for x,y in zip ([99, 100, 101, 101, 101], [101, 101, 101, 100, 99]):
        ret = await contract.admin_read_grid_stats(
            contract.Vec2(x,y)
        ).call()
        assert ret.result.grid_stat.populated == 1
        assert ret.result.grid_stat.deployed_device_type == 12 # utb
        assert ret.result.grid_stat.deployed_device_owner ==users[2]['account'].contract_address
        labels.append(ret.result.grid_stat.deployed_device_id)
    assert len( set(labels) ) == 1 # all utb in this utb-set has the same label
    label = labels[0]
    LOGGER.info (f'> user2 connected her devices with utb-set of label {label}.')

    for i in range(2,4):
        ret = await contract.admin_read_device_deployed_emap(i).call()
        assert ret.result.emap_entry.tethered_to_utb == 1
        assert ret.result.emap_entry.utb_label == label
        LOGGER.info (f'> deployed-device emap entry at {i}: {ret.result}')
    LOGGER.info (f'> user2 deployed his devices.')
    LOGGER.info ('\n')

    #
    # 4. (should raise exception) user3 picks up deployed devices owned by others
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 4')
    LOGGER.info (f"> (should raise exception) user3 picks up deployed devices owned by others")
    LOGGER.info (f'> ------------')
    for (x,y) in [(150,150), (155,150), (99,100), (100,99)] + [(151,150), (152,150), (153,150), (154,150)] + [(99,101), (100,101), (101,101), (101,100), (101,99)]:
        with pytest.raises(Exception) as e_info:
            await users[3]['signer'].send_transaction(
                account = users[3]['account'], to = contract.contract_address,
                selector_name = 'mock_device_pickup_by_grid',
                calldata=[
                    users[3]['account'].contract_address, # caller
                    x, y # grid
                ])
        LOGGER.info (f'> user3 attempted to pick up the device at grid ({x},{y}) which she does not own -> exception raised as expected.')
    LOGGER.info ('\n')

    #
    # 5. (should raise exception) user3 deploys iron harvester on the grids with deployed devices
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 5')
    LOGGER.info (f"> (should raise exception) user3 deploys iron harvester on the grid of user1's deployed harvester")
    LOGGER.info (f'> ------------')

    for (x,y) in [(150,150), (155,150), (99,100), (100,99)] + [(151,150), (152,150), (153,150), (154,150)] + [(99,101), (100,101), (101,101), (101,100), (101,99)]:
        with pytest.raises(Exception) as e_info:
            await users[3]['signer'].send_transaction(
                account = users[3]['account'], to = contract.contract_address,
                selector_name = 'mock_device_deploy',
                calldata=[
                    users[3]['account'].contract_address,
                    2, # DEVICE_FE_HARV
                    x, y # grid
                ])
        LOGGER.info (f'> user3 attempted to deploy device at grid ({x},{y}) which is populated already -> exception raised as expected.')
    LOGGER.info ('\n')

    #
    # 6. user3 deploys her iron harvester & refinery
    #    => admin checks GridStat and emap
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 6')
    LOGGER.info (f"> user3 deploys her iron harvester & refinery; admin checks GridStat and emap")
    LOGGER.info (f'> ------------')
    user3_harvester_grid = (153, 152)
    user3_refinery_grid = (153, 148)
    await users[3]['signer'].send_transaction(
        account = users[3]['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            users[3]['account'].contract_address,
            2, # DEVICE_FE_HARV
            user3_harvester_grid[0],
            user3_harvester_grid[1]
        ])
    await users[3]['signer'].send_transaction(
        account = users[3]['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            users[3]['account'].contract_address,
            7, # DEVICE_FE_REFN
            user3_refinery_grid[0],
            user3_refinery_grid[1]
        ])

    ret = await contract.admin_read_grid_stats( contract.Vec2(user3_harvester_grid[0], user3_harvester_grid[1]) ).call()
    LOGGER.info (f'> user3_harvester_grid has {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 2
    assert ret.result.grid_stat.deployed_device_owner == int(users[3]['account'].contract_address)
    user3_harvester_id = ret.result.grid_stat.deployed_device_id

    ret = await contract.admin_read_grid_stats( contract.Vec2(user3_refinery_grid[0], user3_refinery_grid[1]) ).call()
    LOGGER.info (f'> user3_refinery_grid has {ret.result}')
    assert ret.result.grid_stat.populated == 1
    assert ret.result.grid_stat.deployed_device_type == 7
    assert ret.result.grid_stat.deployed_device_owner == int(users[3]['account'].contract_address)
    user3_refinery_id = ret.result.grid_stat.deployed_device_id

    ret = await contract.admin_read_device_deployed_emap(4).call()
    assert ret.result.emap_entry.grid == contract.Vec2 (user3_harvester_grid[0], user3_harvester_grid[1])
    assert ret.result.emap_entry.type == 2
    assert ret.result.emap_entry.id == user3_harvester_id
    ret = await contract.admin_read_device_deployed_emap(5).call()
    assert ret.result.emap_entry.grid == contract.Vec2 (user3_refinery_grid[0], user3_refinery_grid[1])
    assert ret.result.emap_entry.type == 7
    assert ret.result.emap_entry.id == user3_refinery_id
    LOGGER.info ('\n')

    #
    # 7. (should raise exception) user3 deploys her utb's incontiguously
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 7')
    LOGGER.info (f"> (should raise exception) user3 deploys her utb's incontiguously")
    LOGGER.info (f'> ------------')
    # user3 is supposed to connect (200,100) and (199,99)
    with pytest.raises(Exception) as e_info:
        await users[3]['signer'].send_transaction(
            account = users[3]['account'], to = contract.contract_address,
            selector_name = 'mock_utb_deploy',
            calldata=[
                users[3]['account'].contract_address, # caller
                2, 154, 155, # locs_x
                2, 152, 152, # locs_y
                user3_harvester_grid[0], user3_harvester_grid[1], user3_refinery_grid[0], user3_refinery_grid[1]
            ])
    LOGGER.info (f'> user3 attempted to deploy incontiguous utb set -> exception raised as expected.')
    LOGGER.info ('\n')

    #
    # 8. (should raise exception) user3 deploys her utb's contiguously to connect their harvester-refinery pair but crossing over
    #                              user1's utb path
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 8')
    LOGGER.info (f"> (should raise exception) user3 deploys her utb's contiguously to connect their harvester-refinery pair but crossing over user1's utb path")
    LOGGER.info (f'> ------------')
    with pytest.raises(Exception) as e_info:
        await users[3]['signer'].send_transaction(
            account = users[3]['account'], to = contract.contract_address,
            selector_name = 'mock_utb_deploy',
            calldata=[
                users[3]['account'].contract_address, # caller
                2, 153, 153, 153, # locs_x
                2, 151, 150, 149, # locs_y
                user3_harvester_grid[0], user3_harvester_grid[1], user3_refinery_grid[0], user3_refinery_grid[1]
            ])
    LOGGER.info (f"> user3 attempted to deploy utb-set crossing over other's deployed utb-set -> exception raised as expected.")
    LOGGER.info ('\n')

    #
    # 9. (should raise exception) user1 attempt to deploy another iron harvester (device balance already depleted)
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 9')
    LOGGER.info (f"> (should raise exception) user1 attempt to deploy another iron harvester (device balance already depleted)")
    LOGGER.info (f'> ------------')
    with pytest.raises(Exception) as e_info:
        await users[1]['signer'].send_transaction(
            account = users[1]['account'], to = contract.contract_address,
            selector_name = 'mock_device_deploy',
            calldata=[
                users[1]['account'].contract_address,
                2, # DEVICE_FE_HARV
                250, 150
            ])
    LOGGER.info (f'> user1 attempt to deploy another iron harvester but already deployed device balance -> exception raised as expected.')
    LOGGER.info ('\n')

    #
    # 10. Check ledger for correct amount of undeployed devices
    #
    # 10-1 user1 has 0 type2 left, 0 type7 left, and 6 type12 left
    # 10-2 user2 has 0 type2 left, 0 type7 left, and 5 type12 left
    # 10-3 user3 has 0 type2 left, 0 type7 left, and 10 type12 left
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 10')
    LOGGER.info (f"> Check ledger for correct amount of undeployed devices")
    LOGGER.info (f'> ------------')
    expectations = [(1,2,0), (1,7,0), (1,12,6)] + [(2,2,0), (2,7,0), (2,12,5)] + [(3,2,0), (3,7,0), (3,12,10)] # (user#, type#, amount left)
    for expectation in expectations:
        ret = await contract.admin_read_device_undeployed_ledger(
            owner = users[expectation[0]]['account'].contract_address,
            type = expectation[1]
        ).call()
        assert ret.result.amount == expectation[2]
        LOGGER.info (f"> user{expectation[0]}'s undeployed amount {expectation[2]} of type {expectation[1]} matches expectation.")

    # 11. TODO: forward_world_micro ()

    # 12. TODO: user3 picks up her devices

    # #############################
    # # Test `mock_device_deploy()`
    # #############################
    # print('> Testing mock_device_deploy()')




    # LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: grid {grid} on face {face} and edge {edge}, output: {ret.result}')
