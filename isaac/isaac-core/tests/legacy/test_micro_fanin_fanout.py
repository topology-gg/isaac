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
    user = users[1]
    user_addr = user['account'].contract_address

    starknet, accounts = account_factory
    LOGGER.info (f'> Deploying micro.cairo ..\n')
    contract = await starknet.deploy (
        source = 'contracts/micro.cairo',
        constructor_calldata = []
    )

    # Test strategy:
    # user receives 1 iron harvester, 2 aluminum harvesters, 1 iron refinery, 2 aluminum refineries, 1 OPSF, and many UTBs from admin.
    # user deploys all devices sparsely
    # user connects iron harvester => iron refinery => OPSF using UTBs
    # user connects aluminum harvester#1 => aluminum refinery#1 => OPSF
    # user connects aluminum harvester#2 => aluminum refinery#1
    # user connects aluminum harvester#2 => aluminum refinery#2 => OPSF
    # this results in:
    # - aluminum harvester#2 having fan-out = 2
    # - aluminum refinery #1 having fan-in = 2

    #
    # 1. admin gives user various devices at specific amounts; checks ledger
    #
    N_UTB = 300
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 1')
    LOGGER.info (f'> admin gives user:')
    LOGGER.info (f'  1 fe-harv, 1 fe-refn, 2 al-harv, 2 al-refn, 1 OPSF, {N_UTB} UTBs;')
    LOGGER.info (f'> check ledger to confirm these numbers remain undeployed.')
    LOGGER.info (f'> ------------')

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
            3, # DEVICE_AL_HARV
            2
        ]
    )
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            8, # DEVICE_AL_REFN
            2
        ]
    )
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            14, # OPSF
            1
        ]
    )
    await admin['signer'].send_transaction(
        account = admin['account'], to = contract.contract_address,
        selector_name = 'admin_write_device_undeployed_ledger',
        calldata=[
            user['account'].contract_address,
            12, # UTB
            N_UTB
        ]
    )

    ret = await contract.admin_read_device_undeployed_ledger(
        owner = user_addr, type = 2).call()
    assert ret.result.amount == 1
    ret = await contract.admin_read_device_undeployed_ledger(
        owner = user_addr, type = 7).call()
    assert ret.result.amount == 1
    ret = await contract.admin_read_device_undeployed_ledger(
        owner = user_addr, type = 3).call()
    assert ret.result.amount == 2
    ret = await contract.admin_read_device_undeployed_ledger(
        owner = user_addr, type = 8).call()
    assert ret.result.amount == 2
    ret = await contract.admin_read_device_undeployed_ledger(
        owner = user_addr, type = 14).call()
    assert ret.result.amount == 1
    ret = await contract.admin_read_device_undeployed_ledger(
        owner = user_addr, type = 12).call()
    assert ret.result.amount == N_UTB
    LOGGER.info (f"> user's undeployed device amounts are correct.\n")


    #
    # 2. user deploys all devices sparsely; check deployed-device emap
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 2')
    LOGGER.info (f'> user deploys all devices sparsely;')
    LOGGER.info (f'> check deployed-device emap.')
    LOGGER.info (f'> ------------')

    ## fe-harv at (180, 85)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            2, # DEVICE_FE_HARV
            180, 85
        ]
    )

    ## fe-refn at (185, 85)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            7, # DEVICE_FE_REFN
            185, 85
        ]
    )

    ## al-harv1 at (160, 130)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            3, # DEVICE_AL_HARV
            160, 130
        ]
    )

    ## al-refn1 at (170, 145)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            8, # DEVICE_AL_REFN
            170, 145
        ]
    )

    ## al-harv2 at (180, 180)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            3, # DEVICE_AL_HARV
            180, 180
        ]
    )

    ## al-refn2 at (190, 180)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            8, # DEVICE_AL_REFN
            190, 180
        ]
    )

    # OPSF at (200, 100)
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_device_deploy',
        calldata=[
            user_addr,
            14, # OPSF
            200, 100
        ]
    )
    LOGGER.info (f'> all devices are deployed.')

    ret = await contract.admin_read_device_undeployed_ledger(user_addr, 2).call()
    assert ret.result.amount == 0
    ret = await contract.admin_read_device_undeployed_ledger(user_addr, 7).call()
    assert ret.result.amount == 0
    ret = await contract.admin_read_device_undeployed_ledger(user_addr, 3).call()
    assert ret.result.amount == 0
    ret = await contract.admin_read_device_undeployed_ledger(user_addr, 8).call()
    assert ret.result.amount == 0
    ret = await contract.admin_read_device_undeployed_ledger(user_addr, 14).call()
    assert ret.result.amount == 0
    LOGGER.info (f'> undeployed device amounts are correct.')

    ret = await contract.admin_read_device_deployed_emap_size().call()
    assert ret.result.size == 7
    LOGGER.info (f'> deployed-device emap size is correct.\n')

    # for i in range(7):
    #     ret = await contract.admin_read_device_deployed_emap(i).call()
    #     LOGGER.info (f'> emap entry at {i}: {ret.result}')
    ret = await contract.admin_read_device_deployed_emap(0).call()
    fe_harv_id = ret.result.emap_entry.id
    ret = await contract.admin_read_device_deployed_emap(1).call()
    fe_refn_id = ret.result.emap_entry.id
    ret = await contract.admin_read_device_deployed_emap(2).call()
    al_harv_1_id = ret.result.emap_entry.id
    ret = await contract.admin_read_device_deployed_emap(3).call()
    al_refn_1_id = ret.result.emap_entry.id
    ret = await contract.admin_read_device_deployed_emap(4).call()
    al_harv_2_id = ret.result.emap_entry.id
    ret = await contract.admin_read_device_deployed_emap(5).call()
    al_refn_2_id = ret.result.emap_entry.id
    ret = await contract.admin_read_device_deployed_emap(6).call()
    opsf_id = ret.result.emap_entry.id


    #
    # 3. user connects iron harvester => iron refinery => OPSF using UTBs
    #    fe-harv at (180, 85), fe-refn at (185, 85), OPSF at (200, 100)
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 3')
    LOGGER.info (f'> user connects iron harvester => iron refinery => OPSF using UTBs')
    LOGGER.info (f'> ------------')
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata=[
            user_addr, 12,
            4, 181, 182, 183, 184, # locs_x
            4, 85 , 85 , 85 , 85, # locs_y
            180, 85, 185, 85
        ]
    )
    LOGGER.info (f'> connected iron harvester with iron refinery with 4 UTBs.')

    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata=[
            user_addr, 12,
            22, 187, 188, 189, 190, 191, 192, 193, 194, 195, 196, 197, 198, 199, 213, 212, 211, 210, 209, 208, 207, 206, 205, # locs_x
            22, 86 , 86 , 86 , 86 , 86 , 86 , 86 , 86 , 86 , 86 , 86 , 86 , 86 , 100, 100, 100, 100, 100, 100, 100, 100, 100, # locs_y
            186, 86, 204, 100
        ]
    )
    LOGGER.info (f'> connected iron refinery with OPSF with 22 UTBs.\n')

    #
    # 4. user connects aluminum harvester#1 => aluminum refinery#1 => OPSF
    #    al-harv-1 at (160, 130), al-refn-1 at (170, 145), OPSF at (200, 100)
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 4')
    LOGGER.info (f'> user connects iron harvester => iron refinery => OPSF using UTBs')
    LOGGER.info (f'> ------------')
    locs_x = [160 for y in range(131,146)] + [x for x in range(161,170)]
    locs_y = [y for y in range(131,146)] + [145 for x in range(161,170)]
    n_utb = len(locs_x)
    locs_x = [n_utb] + locs_x
    locs_y = [n_utb] + locs_y
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata = [user_addr, 12] + locs_x + locs_y + [160, 130, 170, 145]
    )
    LOGGER.info (f'> connected aluminum harvester #1 with aluminum refinery #1 with {n_utb} UTBs.')

    locs_x = [x for x in range(172,201)] + [200 for y in range(105,145)]
    locs_y = [145 for x in range(172,201)] + [y for y in range(105,145)][::-1]
    n_utb = len(locs_x)
    locs_x = [n_utb] + locs_x
    locs_y = [n_utb] + locs_y
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata = [user_addr, 12] + locs_x + locs_y + [171, 145, 200, 104]
    )
    LOGGER.info (f'> connected aluminum refinery #1 with OPSF with {n_utb} UTBs.\n')

    #
    # 5. user connects aluminum harvester#2 => aluminum refinery#1
    #    al-harv-2 at (180, 180), al-refn-1 at (170, 145)
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 5')
    LOGGER.info (f'> user connects aluminum harvester#2 => aluminum refinery#1')
    LOGGER.info (f'> ------------')
    ## deploy UTBs from (179, 180) => (170, 147)
    locs_x = [x for x in range(170,180)][::-1] + [170 for y in range(147,180)]
    locs_y = [180 for x in range(170,180)] + [y for y in range(147,180)][::-1]
    n_utb = len(locs_x)
    locs_x = [n_utb] + locs_x
    locs_y = [n_utb] + locs_y
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata = [user_addr, 12] + locs_x + locs_y + [180, 180, 170, 146]
    )
    LOGGER.info (f'> connected aluminum harvester #2 with aluminum refinery #1 with {n_utb} UTBs.\n')

    #
    # 6. user connects aluminum harvester#2 => aluminum refinery#2 => OPSF
    #    al-harv-2 at (180, 180), al-refn-2 at (190, 180), OPSF at (200, 100)
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 6')
    LOGGER.info (f'> user connects aluminum harvester#2 => aluminum refinery#2 => OPSF')
    LOGGER.info (f'> ------------')
    ## deploy UTBs from (181, 180) => (189, 180)
    locs_x = [x for x in range(181,190)]
    locs_y = [180 for x in range(181,190)]
    n_utb = len(locs_x)
    locs_x = [n_utb] + locs_x
    locs_y = [n_utb] + locs_y
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata = [user_addr, 12] + locs_x + locs_y + [180, 180, 190, 180]
    )
    LOGGER.info (f'> connected aluminum harvester #2 with aluminum refinery #2 with {n_utb} UTBs.')

    ## deploy UTBs from (192, 180) => (202, 180), then (202, 179) => (202, 105)
    locs_x = [x for x in range(192,203)] + [202 for y in range(105,180)]
    locs_y = [180 for x in range(192,203)] + [y for y in range(105,180)][::-1]
    n_utb = len(locs_x)
    locs_x = [n_utb] + locs_x
    locs_y = [n_utb] + locs_y
    await user['signer'].send_transaction(
        account = user['account'], to = contract.contract_address,
        selector_name = 'mock_utx_deploy',
        calldata = [user_addr, 12] + locs_x + locs_y + [191, 180, 202, 104]
    )
    LOGGER.info (f'> connected aluminum refinery #2 with OPSF with {n_utb} UTBs.\n')

    #
    # 7. Check initial resource amount at each device
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 7')
    LOGGER.info (f'> Check initial resource amount at each device')
    LOGGER.info (f'> ------------')

    for device_id in [fe_harv_id, al_harv_1_id, al_harv_2_id]:
        ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(device_id).call()
        assert ret.result.balance == 0

    for device_id in [fe_refn_id, al_refn_1_id, al_refn_2_id]:
        ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(device_id).call()
        assert ret.result.balances.balance_resource_before_transform == 0
        assert ret.result.balances.balance_resource_after_transform == 0

    for element_type in [0,1,2,3]:
        ret = await contract.admin_read_opsf_deployed_id_to_resource_balances(opsf_id, element_type).call()
        assert ret.result.balance == 0
    LOGGER.info (f'> resource balances at devices match expected.\n')

    #
    # 8. run `forward_world_micro()`, and check resource balances
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 8')
    LOGGER.info (f'> run `forward_world_micro()`, and check resource balances ')
    LOGGER.info (f'> ------------')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(fe_harv_id).call()
    LOGGER.info (f"> resource at fe harv: {ret.result.balance}")
    assert ret.result.balance == +500 - 1 # fanout = 1

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(al_harv_1_id).call()
    LOGGER.info (f"> resource at al harv #1: {ret.result.balance}")
    assert ret.result.balance == +500 - 1 # fanout = 1

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(al_harv_2_id).call()
    LOGGER.info (f"> resource at al harv #2: {ret.result.balance}")
    assert ret.result.balance == +500 - 2 # fanout = 2

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(fe_refn_id).call()
    LOGGER.info (f"> resource at fe refn: {ret.result.balances.balance_resource_before_transform} / {ret.result.balances.balance_resource_after_transform}")
    assert ret.result.balances.balance_resource_before_transform == 1 # fanin = 1
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(al_refn_1_id).call()
    LOGGER.info (f"> resource at al refn #1: {ret.result.balances.balance_resource_before_transform} / {ret.result.balances.balance_resource_after_transform}")
    assert ret.result.balances.balance_resource_before_transform == 2 # fanin = 2
    assert ret.result.balances.balance_resource_after_transform == 0

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(al_refn_2_id).call()
    LOGGER.info (f"> resource at al refn #2: {ret.result.balances.balance_resource_before_transform} / {ret.result.balances.balance_resource_after_transform}")
    assert ret.result.balances.balance_resource_before_transform == 1 # fanin = 1
    assert ret.result.balances.balance_resource_after_transform == 0

    for element_type in [0,1,2,3]:
        ret = await contract.admin_read_opsf_deployed_id_to_resource_balances(opsf_id, element_type).call()
        LOGGER.info (f"> resource of type {element_type} at OPSF: {ret.result.balance}")
        assert ret.result.balance == 0

    LOGGER.info (f"> all resource balances are correct.\n")

    #
    # 9. run `forward_world_micro()` again, and check resource balances
    #
    LOGGER.info (f'> ------------')
    LOGGER.info (f'> TEST 9')
    LOGGER.info (f'> run `forward_world_micro()` again, and check resource balances ')
    LOGGER.info (f'> ------------')

    await contract.mock_forward_world_micro().invoke()
    LOGGER.info (f'> forward_world_micro() invoked.')

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(fe_harv_id).call()
    LOGGER.info (f"> resource at fe harv: {ret.result.balance}")
    assert ret.result.balance == +500-1 +500 -1

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(al_harv_1_id).call()
    LOGGER.info (f"> resource at al harv #1: {ret.result.balance}")
    assert ret.result.balance == +500-1 +500 -1

    ret = await contract.admin_read_harvesters_deployed_id_to_resource_balance(al_harv_2_id).call()
    LOGGER.info (f"> resource at al harv #2: {ret.result.balance}")
    assert ret.result.balance == +500-2 +500 -2

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(fe_refn_id).call()
    LOGGER.info (f"> resource at fe refn: {ret.result.balances.balance_resource_before_transform} / {ret.result.balances.balance_resource_after_transform}")
    assert ret.result.balances.balance_resource_before_transform == 1 -1 +1
    assert ret.result.balances.balance_resource_after_transform == 0 +1 -1 # transported to OPSF

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(al_refn_1_id).call()
    LOGGER.info (f"> resource at al refn #1: {ret.result.balances.balance_resource_before_transform} / {ret.result.balances.balance_resource_after_transform}")
    assert ret.result.balances.balance_resource_before_transform == 2 -1 +2
    assert ret.result.balances.balance_resource_after_transform == 0 +1 -1 # transported to OPSF

    ret = await contract.admin_read_transformers_deployed_id_to_resource_balances(al_refn_2_id).call()
    LOGGER.info (f"> resource at al refn #2: {ret.result.balances.balance_resource_before_transform} / {ret.result.balances.balance_resource_after_transform}")
    assert ret.result.balances.balance_resource_before_transform == 1 -1 +1
    assert ret.result.balances.balance_resource_after_transform == 0 +1 -1 # transported to OPSF

    ret = await contract.admin_read_opsf_deployed_id_to_resource_balances(opsf_id, 0).call()
    LOGGER.info (f"> resource of type {element_type} at OPSF: {ret.result.balance}")
    assert ret.result.balance == 0
    ret = await contract.admin_read_opsf_deployed_id_to_resource_balances(opsf_id, 1).call()
    LOGGER.info (f"> resource of type {element_type} at OPSF: {ret.result.balance}")
    assert ret.result.balance == +1
    ret = await contract.admin_read_opsf_deployed_id_to_resource_balances(opsf_id, 2).call()
    LOGGER.info (f"> resource of type {element_type} at OPSF: {ret.result.balance}")
    assert ret.result.balance == 0
    ret = await contract.admin_read_opsf_deployed_id_to_resource_balances(opsf_id, 3).call()
    LOGGER.info (f"> resource of type {element_type} at OPSF: {ret.result.balance}")
    assert ret.result.balance == +2

    LOGGER.info (f"> all resource balances are correct.\n")