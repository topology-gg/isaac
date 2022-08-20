"""Start the isaac indexer"""

import os
import sys
import asyncio
import math
from argparse import ArgumentParser
from datetime import datetime

from pymongo import MongoClient
# from dotenv import load_dotenv

from apibara import NewEvents, IndexerRunner, NewBlock, Info, Client
from apibara.indexer.runner import IndexerRunnerConfiguration
from apibara.model import EventFilter

from isaac_api.contract import (
    extract_counter_from_event,

    decode_forward_world_event,
    decode_give_undeployed_device_occurred_event,
    decode_activate_universe_occurred_event,
    decode_universe_activation_occurred_event,
    decode_universe_deactivation_occurred_event,
    decode_player_deploy_device_occurred_event,
    decode_player_pickup_device_occurred_event,
    decode_terminate_universe_occurred_event,
    decode_player_deploy_utx_occurred_event,
    decode_player_pickup_utx_occurred_event,

    decode_resource_update_at_harvester_occurred_event,
    decode_resource_update_at_transformer_occurred_event,
    decode_resource_update_at_upsf_occurred_event,
    decode_energy_update_at_device_occurred_event,

    decode_impulse_applied_occurred_event,
    decode_player_transfer_undeployed_device_occurred_event,

    decode_ask_to_queue_occurred_event,
    decode_give_invitation_occurred_event
)

# load_dotenv ()

CIV_SIZE = 20
UNIVERSE_COUNT = 1
DEVICE_TYPE_COUNT = 16

ORIGIN_BLOCK_TO_INDEX = 303261 - 1
INDEXER_ID = os.getenv('ISAAC_INDEXER_ID', 'isaac')

ISAAC_UNIVERSE_ADDRESSES = {
    0 : '0x03df9fa61c7f69d0b9e5da0ed94ceafed7c6f9ffa56b3828d515768ef861bb56'
}
ISAAC_LOBBY_ADDRESS = '0x06ea0fc5dcf98f2cb9f4b97fc355cd1f92e0ee83fde75c0f6117602a54cf6bda'

PG_TYPES = [0,1]
HARVESTER_TYPES = [2,3,4,5,6]
TRANSFORMER_TYPES = [7,8,9,10,11]
UTX_TYPES = [12,13]
UPSF_TYPE = 14
NDPE_TYPE = 15

LOBBY_EVENT_LIST = [
    'universe_activation_occurred',
    'universe_deactivation_occurred',
    'ask_to_queue_occurred',
    'give_invitation_occurred'
]

DEVICE_DIMENSION_MAP = {
    0 : 1,
    1 : 3,
    2 : 1,
    3 : 1,
    4 : 1,
    5 : 1,
    6 : 1,
    7 : 2,
    8 : 2,
    9 : 2,
    10 : 2,
    11 : 2,
    12 : 1,
    13 : 1,
    14 : 5,
    15 : 5
}

def _create_mongo_client_and_db():
    mongo_connection_url = os.getenv ("ISAAC_MONGO_URL")
    mongo_db_name = os.getenv ("ISAAC_MONGO_DB_NAME")

    mongo = MongoClient (mongo_connection_url)
    isaac_db = mongo [mongo_db_name]

    #
    # Check database status before processing events
    #
    db_status = isaac_db.command ("serverStatus")
    print (f'> MongoDB connected: {db_status["host"]}')

    MONGO = mongo

    return mongo, isaac_db

def find_if_from_univ (adr):
    for (k,v) in ISAAC_UNIVERSE_ADDRESSES.items():
        if int(adr[2:], 16) == int(v, 16):
            return k
    return None

#
# Handle events
#

def extract_priority_from_event (event):
    # priority: universe > lobby

    if event.name in LOBBY_EVENT_LIST:
        return 0
    else:
        return 1


async def handle_events(info: Info, block_events: NewEvents):
    block_number = block_events.block.number

    #
    # sort events based on event_counter value in ascending order
    #
    event_priority_counter_tuples = []
    for event in block_events.events:
        counter = extract_counter_from_event (event)
        priority = extract_priority_from_event (event)
        event_priority_counter_tuples.append ( (event, priority, counter) )
    event_priority_counter_tuples.sort (key = lambda e: e[2], reverse=False)
    event_priority_counter_tuples.sort (key = lambda e: e[1], reverse=True)

    debug = "\n".join ([ f"{t[0].name}_p{t[1]}_c{t[2]}" for t in event_priority_counter_tuples ])
    # print (f'\n*** Block {block_number}: handling events:\n{debug}\n')
    print (f'\n*** Block {block_number}\n')

    for (event, _, counter) in event_priority_counter_tuples:
        from_adr = hex ( int.from_bytes(event.address, "big") )
        from_univ = find_if_from_univ (from_adr)
        print (f'  - got event (counter={counter}): name={event.name}, address={from_adr}, block_number={block_number}, from_univ={from_univ}')

        if event.name == 'forward_world_macro_occurred':
            await handle_forward_world_macro_occurred (info, event, from_univ, block_number)

        elif event.name == 'give_undeployed_device_occurred':
            await handle_give_undeployed_device_occurred (info, event, from_univ, block_number)

        elif event.name == 'activate_universe_occurred':
            await handle_activate_universe_occurred (info, event, from_univ, block_number)

        elif event.name == 'universe_activation_occurred':
            await handle_universe_activation_occurred (info, event)

        elif event.name == 'universe_deactivation_occurred':
            await handle_universe_deactivation_occurred (info, event)

        elif event.name == 'player_deploy_device_occurred':
            await handle_player_deploy_device_occurred (info, event, from_univ)

        elif event.name == 'player_pickup_device_occurred':
            await handle_player_pickup_device_occurred (info, event, from_univ)

        elif event.name == 'terminate_universe_occurred':
            await handle_terminate_universe_occurred (info, event, from_univ)

        elif event.name == 'player_deploy_utx_occurred':
            await handle_player_deploy_utx_occurred (info, event, from_univ)

        elif event.name == 'player_pickup_utx_occurred':
            await handle_player_pickup_utx_occurred (info, event, from_univ)

        elif event.name == 'resource_update_at_harvester_occurred':
            await handle_resource_update_at_harvester_occurred (info, event, from_univ)

        elif event.name == 'resource_update_at_transformer_occurred':
            await handle_resource_update_at_transformer_occurred (info, event, from_univ)

        elif event.name == 'resource_update_at_upsf_occurred':
            await handle_resource_update_at_upsf_occurred (info, event, from_univ)

        elif event.name == 'energy_update_at_device_occurred':
            await handle_energy_update_at_device_occurred (info, event, from_univ)

        elif event.name == 'ask_to_queue_occurred':
            await handle_ask_to_queue_occurred (info, event)

        elif event.name == 'give_invitation_occurred':
            await handle_give_invitation_occurred (info, event)

        elif event.name == 'impulse_applied_occurred':
            await handle_impulse_applied_occurred (info, event, from_univ, block_number)

        elif event.name == 'player_transfer_undeployed_device_occurred':
            await handle_player_transfer_undeployed_device_occurred (info, event, from_univ)

        # print()

async def handle_player_transfer_undeployed_device_occurred (info, event, univ):
    #
    # Decode event
    #
    src_account, dst_account, device_type, device_amount = decode_player_transfer_undeployed_device_occurred_event (event)
    print (f'> src_account={src_account}, dst_account={dst_account}, device_type={device_type}, device_amount={device_amount}\n')

    #
    # Update collection 'u{}_player_balances'
    #
    await info.storage.find_one_and_update (
        f'u{univ}_player_balances',
        {'account' : str(src_account)},
        {'$inc' : {str(device_type) : -1*device_amount}}
    )
    await info.storage.find_one_and_update (
        f'u{univ}_player_balances',
        {'account' : str(dst_account)},
        {'$inc' : {str(device_type) : +1*device_amount}}
    )


async def handle_impulse_applied_occurred (info, event, univ, block_number):
    #
    # Decode event
    #
    # impulse, plnt_q_before_impulse = decode_impulse_applied_occurred_event (event)
    impulse = decode_impulse_applied_occurred_event (event)
    impulse_json = impulse.to_json ()
    print(f'> impulse_json={impulse_json}\n')
    # plnt_q_before_impulse_json = plnt_q_before_impulse.to_json ()

    #
    # Update collection 'impulses'
    #

    macro_states = await info.storage.find (
        collection = f'u{univ}_macro_states',
        filter = {},
        skip = 0,
        limit = 0
    )
    macro_states = list (macro_states)
    macro_states.sort (key = lambda doc : doc ['block_number'], reverse = True)
    most_recent_macro_state = macro_states[0]

    await info.storage.insert_one (
        f'u{univ}_impulses',
        {
            'block_number' : block_number,
            'impulse_applied' : impulse_json,
            'most_recent_planet_q' : most_recent_macro_state['dynamics']['planet']['q']
        }
    )

    print (f"  -- impulse applied: Vec2({impulse_json['x']},{impulse_json['y']}), block_number={block_number}")
    print (f"  -- most recent macro state: {most_recent_macro_state}")


async def handle_ask_to_queue_occurred (info, event):
    #
    # Decode event
    #
    account, queue_idx = decode_ask_to_queue_occurred_event (event)
    print(f'account={account}, queue_idx={queue_idx}\n')

    #
    # Update collection `lobby_queue`
    # -- document structure: {queue_idx, account, expired}
    #
    await info.storage.insert_one (
        'lobby_queue',
        {
            'queue_idx' : queue_idx,
            'account' : str(account),
            'expired' : 0
        }
    )


async def handle_give_invitation_occurred (info, event):
    #
    # Decode event
    #
    account = decode_give_invitation_occurred_event (event)
    print(f'> account={account}\n')

    return


async def handle_resource_update_at_harvester_occurred (info, event, univ):

    #
    # Decode event
    #
    device_id, new_quantity = decode_resource_update_at_harvester_occurred_event (event)
    print(f'> device_id={device_id}, new_quantity={new_quantity}\n')
    # print (f'    -- resource update at harvester: device_id={device_id}, new_quantity={new_quantity}')

    #
    # Update collection 'u{i}_deployed_harvesters'
    # -- document structure: {id, device_type, resource, energy}
    #
    await info.storage.find_one_and_update (
        collection = f'u{univ}_deployed_harvesters',
        filter = {'id' : str(device_id)},
        update = {
            '$set' : {'resource' : new_quantity}
        }
    )


async def handle_resource_update_at_transformer_occurred (info, event, univ):

    #
    # Decode event
    #
    device_id, new_quantity_pre, new_quantity_post = decode_resource_update_at_transformer_occurred_event (event)
    print(f'> device_id={device_id}, new_quantity_pre={new_quantity_pre}, new_quantity_post={new_quantity_post}\n')
    # print (f'    -- resource update at transformer: device_id={device_id}, new_quantity_pre={new_quantity_pre}, new_quantity_post={new_quantity_post}')

    #
    # Update collection 'u{i}_deployed_transformers'
    # -- document structure: {id, device_type, resource_pre, resource_post, energy}
    #
    await info.storage.find_one_and_update (
        collection = f'u{univ}_deployed_transformers',
        filter = {'id' : str(device_id)},
        update = {
            '$set' : {'resource_pre'  : new_quantity_pre},
            '$set' : {'resource_post' : new_quantity_post}
        }
    )


async def handle_resource_update_at_upsf_occurred (info, event, univ):

    #
    # Decode event
    #
    device_id, element_type, new_quantity = decode_resource_update_at_upsf_occurred_event (event)
    print(f'> device_id={device_id}, element_type={element_type}, new_quantity={new_quantity}\n')
    # print (f'    -- resource update at upsf: device_id={device_id}, element_type={element_type}, new_quantity={new_quantity}')

    #
    # Update collection 'u{i}_deployed_upsfs'
    # -- document structure: {id, resource_0, resource_1, ..., resource_9}
    #
    await info.storage.find_one_and_update (
        collection = f'u{univ}_deployed_upsfs',
        filter = {'id' : str(device_id)},
        update = {
            '$set' : {f'resource_{element_type}' : new_quantity}
        }
    )


async def handle_energy_update_at_device_occurred (info, event, univ):

    #
    # Decode event
    #
    device_id, new_quantity = decode_energy_update_at_device_occurred_event (event)
    print(f'> device_id={device_id}, new_quantity={new_quantity}\n')

    #
    # Find device type and determine if harvester / transformer / upsf / ndpe
    #
    result = await info.storage.find_one (
        f'u{univ}_deployed_devices',
        {'id' : str(device_id)}
    )
    device_type = int (result ['type'])
    # print (f'    -- energy update at device: device_type={device_type}, device_id={device_id}, new_quantity={new_quantity}')

    #
    # Update collection according to device_type
    #
    if (device_type in PG_TYPES):
        await info.storage.find_one_and_update (
            f'u{univ}_deployed_pgs',
            {'id' : str(device_id)},
            {'$set' : {'energy' : new_quantity}}
        )

    elif (device_type in HARVESTER_TYPES):
        await info.storage.find_one_and_update (
            f'u{univ}_deployed_harvesters',
            {'id' : str(device_id)},
            {'$set' : {'energy' : new_quantity}}
        )

    elif (device_type in TRANSFORMER_TYPES):
        await info.storage.find_one_and_update (
            f'u{univ}_deployed_transformers',
            {'id' : str(device_id)},
            {'$set' : {'energy' : new_quantity}}
        )

    elif (device_type == UPSF_TYPE):
        await info.storage.find_one_and_update (
            f'u{univ}_deployed_upsfs',
            {'id' : str(device_id)},
            {'$set' : {'energy' : new_quantity}}
        )

    elif (device_type == NDPE_TYPE):
        await info.storage.find_one_and_update (
            f'u{univ}_deployed_ndpes',
            {'id' : str(device_id)},
            {'$set' : {'energy' : new_quantity}}
        )

    else:
        raise Exception ('Invalid device type')


async def handle_player_deploy_utx_occurred (info, event, univ):
    #
    # Decode event
    #
    owner, utx_label, utx_device_type, src_device_grid, dst_device_grid, locs_len, locs = decode_player_deploy_utx_occurred_event (event)
    print(f'> owner={owner}, utx_label={utx_label}, utx_device_type={utx_device_type}, src_device_grid={src_device_grid}, dst_device_grid={dst_device_grid}, locs_len={locs_len}, locs={locs}\n')
    # print (f'    owner={owner}, utx_label={utx_label}, utx_device_type={utx_device_type}, src_device_grid={src_device_grid}, dst_device_grid={dst_device_grid}, locs_len={locs_len}, locs={locs}')

    #
    # Update collection 'u{}_player_balances'
    #
    await info.storage.find_one_and_update (
        f'u{univ}_player_balances',
        {'account' : str(owner)},
        {'$inc' : {str(utx_device_type) : -1*locs_len}}
    )

    #
    # Update collection 'u{}_deployed_devices'
    # -- document structure: {device_id, owner, type, grid}
    #
    for i in range (locs_len):
        await info.storage.insert_one (
            f'u{univ}_deployed_devices',
            {
                'owner' : str(owner),
                'id'    : str(utx_label),
                'type'  : str(utx_device_type),
                'grid'  : locs[i]
            }
        )

    #
    # Update collection 'u{}_utx_sets'
    # -- document structure: {label, type, grids}
    #
    await info.storage.insert_one (
        f'u{univ}_utx_sets',
        {
            'label' : str(utx_label),
            'type'  : str(utx_device_type),
            'grids' : locs,
            'src_grid' : src_device_grid.to_json (),
            'dst_grid' : dst_device_grid.to_json (),
            'tethered' : 1
        }
    )


async def handle_player_pickup_utx_occurred (info, event, univ):
    #
    # Decode event
    #
    owner, grid = decode_player_pickup_utx_occurred_event (event)
    print(f'> owner={owner}, grid={grid}\n')

    #
    # Update collection 'u{}_deployed_devices'
    #
    ## first find one based on given grid; use result to learn id & type
    result = await info.storage.find_one (
        f'u{univ}_deployed_devices',
        {
            'grid'  : grid.to_json ()
        }
    )
    ## SAFEGUARD: if for some reason the result is None, don't continue
    ## (experienced once with Open Alpha Civ#1 with a tx attempted to pickup something that was already picked up,
    ##  yet the tx didn't revert and event was still emitted)
    if not result:
        print(f'>>> Exception: errorneous event encountered; this result should not have been None')
        return

    utx_label_str = result ['id']
    utx_device_type = result ['type']

    ## then find all document matching the id to learn how many will be picked up
    result_iter = await info.storage.find (
        collection = f'u{univ}_deployed_devices',
        filter = {'id' : utx_label_str},
        skip = 0,
        limit = 0
    )
    pickedup_count = sum(1 for _ in result_iter) # ref: https://stackoverflow.com/questions/3345785/getting-number-of-elements-in-an-iterator-in-python
    # print (f'  -- picking up {pickedup_count} utx of type {utx_device_type}')

    ## delete all documents matching the id; under the hood delete_many uses pymongo's update_many
    result = await info.storage.delete_many (
        f'u{univ}_deployed_devices',
        {
            'id'    : utx_label_str
        }
    )

    # result = await info.storage.find_one_and_delete ( # delete one
    #     f'u{univ}_deployed_devices',
    #     {
    #         'owner' : str(owner),
    #         'grid'  : grid.to_json ()
    #     }
    # )
    # utx_label_str = result ['id']
    # utx_device_type = result ['type']
    # result = await info.storage.delete_many ( # delete the rest
    #     f'u{univ}_deployed_devices',
    #     {
    #         'owner' : str(owner),
    #         'id'    : utx_label_str
    #     }
    # )
    # pickedup_count = result.deleted_count + 1

    #
    # Update collection 'u{}_player_balances'
    #
    ## return picked-up amount back to balance
    await info.storage.find_one_and_update (
        f'u{univ}_player_balances',
        {'account' : str(owner)},
        {'$inc' : {str(utx_device_type) : pickedup_count}}
    )

    #
    # Update collection 'u{}_utx_sets'
    # -- document structure: {label, type, grids}
    #
    result = await info.storage.delete_many (
        f'u{univ}_utx_sets',
        {
            'label' : utx_label_str
        }
    )
    # assert result.modified_count == 1


async def handle_terminate_universe_occurred (info, event, univ):
    #
    # Decode event
    #
    bool_universe_terminable, destruction_by_which_sun, bool_universe_max_age_reached, bool_universe_escape_condition_met = decode_terminate_universe_occurred_event (event)
    print(f'> bool_universe_terminable={bool_universe_terminable}, destruction_by_which_sun={destruction_by_which_sun}, bool_universe_max_age_reached={bool_universe_max_age_reached}, bool_universe_escape_condition_met={bool_universe_escape_condition_met}\n')
    # print (f'    terminable={bool_universe_terminable}, destruction_by_which_sun={destruction_by_which_sun}, max_age_reached={bool_universe_max_age_reached}, escaped={bool_universe_escape_condition_met}')

    #
    # Update collection 'u{}_civ_state'
    #
    suns = ['ORTA', 'BÖYÜK', 'BALACA']
    if destruction_by_which_sun != 0:
        crashed_sun = suns [destruction_by_which_sun-1]
        fate = f"Ev crashed into {crashed_sun}."
    elif bool_universe_max_age_reached == 1:
        fate = f"Ev survivied till the end of the universe."
    elif bool_universe_escape_condition_met == 1:
        fate = f"Ev escaped."

    await info.storage.find_one_and_update (
        f'u{univ}_civ_state',
        filter = {"most_recent" : 1},
        update = {
            "$set" : {"fate" : fate}
        }
    )


async def handle_player_deploy_device_occurred (info, event, univ):
    #
    # Decode event
    #
    owner, device_id, device_type, grid = decode_player_deploy_device_occurred_event (event)
    print(f'> owner={owner}, device_id={device_id}, device_type={device_type}, grid={grid}\n')

    #
    # Get device footprint
    #
    dim = DEVICE_DIMENSION_MAP [device_type]

    #
    # Update collection 'u{}_deployed_devices'
    # -- document structure: {device_id, owner, type, grid}
    #
    base_grid_json = grid.to_json ()
    for x in range(dim):
        for y in range(dim):
            await info.storage.insert_one (
                f'u{univ}_deployed_devices',
                {
                    'owner' : str(owner),
                    'id'    : str(device_id),
                    'type'  : str(device_type),
                    'grid'  : {
                        'x' : base_grid_json['x'] + x,
                        'y' : base_grid_json['y'] + y,
                    },
                    'base_grid' : base_grid_json
                }
            )

    #
    # Update collection for maintaining resource & energy balance
    #
    if (device_type in PG_TYPES):
        await info.storage.insert_one (
            f'u{univ}_deployed_pgs',
            {
                'id' : str(device_id),
                'type'  : str(device_type),
                'energy' : 0
            }
        )

    elif (device_type in HARVESTER_TYPES):
        await info.storage.insert_one (
            f'u{univ}_deployed_harvesters',
            {
                'id' : str(device_id),
                'type'  : str(device_type),
                'resource' : 0,
                'energy' : 0
            }
        )

    elif (device_type in TRANSFORMER_TYPES):
        await info.storage.insert_one (
            f'u{univ}_deployed_transformers',
            {
                'id' : str(device_id),
                'type'  : str(device_type),
                'resource_pre' : 0,
                'resource_post' : 0,
                'energy' : 0
            }
        )

    elif (device_type == UPSF_TYPE):
        await info.storage.insert_one (
            f'u{univ}_deployed_upsfs',
            {
                'id' : str(device_id),
                'resource_0' : 0,
                'resource_1' : 0,
                'resource_2' : 0,
                'resource_3' : 0,
                'resource_4' : 0,
                'resource_5' : 0,
                'resource_6' : 0,
                'resource_7' : 0,
                'resource_8' : 0,
                'resource_9' : 0,
                'energy' : 0
            }
        )

    elif (device_type == NDPE_TYPE):
        await info.storage.insert_one (
            f'u{univ}_deployed_ndpes',
            {
                'id' : str(device_id),
                'energy' : 0
            }
        )

    #
    # Update collection 'u{}_player_balances'
    #
    await info.storage.find_one_and_update (
        f'u{univ}_player_balances',
        {'account' : str(owner)},
        {'$inc' : {str(device_type) : -1}}
    )


async def handle_player_pickup_device_occurred (info, event, univ):
    #
    # Decode event
    #
    owner, grid = decode_player_pickup_device_occurred_event (event)
    print(f'> owner={owner}, grid={grid}\n')

    #
    # Update collection 'u{}_deployed_devices'
    # -- document structure: {device_id, owner, type, grid}
    #
    selected_grid = grid.to_json ()
    result = await info.storage.find_one (
        f'u{univ}_deployed_devices',
        {
            'owner' : str(owner),
            'grid' : selected_grid
        }
    )
    device_base_grid = result['base_grid']
    device_type_str = result ['type']
    device_id_str = result ['id']
    device_type = int (device_type_str)
    dim = DEVICE_DIMENSION_MAP [ int(device_type_str) ]

    # print (f'  -- attempted to delete device at grid {grid.to_json ()}, type {device_type}, id {device_id_str}')
    result = await info.storage.delete_many ( # apibara's delete_many is pymongo's update_many
        f'u{univ}_deployed_devices',
        {
            'owner' : str(owner),
            'id' : device_id_str
        }
    )
    # print (f"  -- deleted device type {device_type_str}, base grid (x,y)=({device_base_grid['x']},{device_base_grid['y']})")

    #
    # Update collection for utx if device pick-up resulting in untethering
    #
    results_tethered_as_src = []
    results_tethered_as_dst = []
    for x in range (dim):
        for y in range (dim):
            search_x = device_base_grid['x'] + x
            search_y = device_base_grid['y'] + y
            search_grid = {
                'x' : search_x,
                'y' : search_y
            }
            # print (f'  -- searching grid (x,y)=({search_x},{search_y}) to check utx untethering')

            result_tethered_as_src = await info.storage.find ( # should return list; empty if none found
                collection = f'u{univ}_utx_sets',
                filter = {'src_grid' : search_grid},
                skip = 0,
                limit = 0
            )
            result_tethered_as_dst = await info.storage.find ( # should return list; empty if none found
                collection = f'u{univ}_utx_sets',
                filter = {'dst_grid' : search_grid},
                skip = 0,
                limit = 0
            )
            results_tethered_as_src += result_tethered_as_src
            results_tethered_as_dst += result_tethered_as_dst

    for utx_doc in results_tethered_as_src:
        result = await info.storage.find_one_and_update (
            collection = f'u{univ}_utx_sets',
            filter = {'label' : utx_doc['label']},
            update = {'$set' : {'tethered' : 0}}
        )
        # print (f'  -- device pickup results in utx untethered at source: {result}')

    for utx_doc in results_tethered_as_dst:
        result = await info.storage.find_one_and_update (
            collection = f'u{univ}_utx_sets',
            filter = {'label' : utx_doc['label']},
            update = {'$set' : {'tethered' : 0}}
        )
        # print (f'  -- device pickup results in utx untethered at destination: {result}')


    #
    # Update collection for maintaining resource & energy balance
    #
    if (device_type in PG_TYPES):
        await info.storage.delete_many (
            f'u{univ}_deployed_pgs',
            {'id' : device_id_str}
        )
        # print (f'  -- deleted a device of PG type')

    elif (device_type in HARVESTER_TYPES):
        await info.storage.delete_many (
            f'u{univ}_deployed_harvesters',
            {'id' : device_id_str}
        )
        # print (f'  -- deleted a device of HARVESTER type')

    elif (device_type in TRANSFORMER_TYPES):
        await info.storage.delete_many (
            f'u{univ}_deployed_transformers',
            {'id' : device_id_str}
        )
        # print (f'  -- deleted a device of TRANSFORMER type')

    elif (device_type == UPSF_TYPE):
        await info.storage.delete_many (
            f'u{univ}_deployed_upsfs',
            {'id' : device_id_str}
        )
        # print (f'  -- deleted an UPSF')

    elif (device_type == NDPE_TYPE):
        await info.storage.delete_many (
            f'u{univ}_deployed_ndpes',
            {'id' : device_id_str}
        )
        # print (f'  -- deleted an NDPE')

    #
    # Update collection 'u{}_player_balances'
    #
    await info.storage.find_one_and_update (
        f'u{univ}_player_balances',
        {'account' : str(owner)},
        {'$inc' : {device_type_str : +1}}
    )


async def handle_forward_world_macro_occurred (info, event, univ, block_number):
    #
    # Decode event
    #
    dynamics, phi = decode_forward_world_event (event)
    print(f'> dynamics={dynamics}, phi={phi}\n')

    #
    # Update database
    #
    # await info.storage.find_one_and_update ( # Clamp block range of previous value
    #     f'u{univ}_macro_states',
    #     {"_chain.valid_to" : None},
    #     {"$set" : {"_chain.valid_to": block_number}},
    # )
    # await info.storage.insert_one (
    #     f'u{univ}_macro_states',
    #     {
    #         "phi" : phi.to_bytes(32, "big"),
    #         "dynamics" : dynamics.to_json(),
    #         "block_number" : block_number,
    #         "_chain" : {
    #             "valid_from" : block_number,
    #             "valid_to" : None,
    #         },
    #     }
    # )

    dynamics_json = dynamics.to_json()
    await info.storage.insert_one (
        f'u{univ}_macro_states',
        {
            "phi" : phi.to_bytes(32, "big"),
            "dynamics" : dynamics_json,
            "block_number" : block_number
        }
    )

    def distance (qa, qb):
        return math.sqrt ( (qa['x']-qb['x'])**2 + (qa['y']-qb['y'])**2 )

    sun0_q = dynamics_json['sun0']['q']
    sun1_q = dynamics_json['sun1']['q']
    sun2_q = dynamics_json['sun2']['q']
    plnt_q = dynamics_json['planet']['q']

    distance_0 = distance (sun0_q, plnt_q)
    distance_1 = distance (sun1_q, plnt_q)
    distance_2 = distance (sun2_q, plnt_q)

    print (f'    - distances to sun0 ({distance_0}), sun1 ({distance_1}), sun2 ({distance_2})')


async def handle_give_undeployed_device_occurred (info, event, univ, block_number):
    #
    # Decode event
    #
    event_counter, to_account, device_type, device_amount = decode_give_undeployed_device_occurred_event (event)
    print(f'> event_counter={event_counter}, to_account={to_account}, device_type={device_type}, device_amount={device_amount}\n')
    # print (f"    -- event_counter={event_counter}, to_account={to_account}, device_type={device_type}, device_amount={device_amount}")

    #
    # Update database
    #
    result = await info.storage.find_one (
        f'u{univ}_player_balances',
        {'account' : str(to_account)}
    )
    if result is None:
        # print (f'handle_give_undeployed_device_occurred NONE; performing insert_one')
        document = {
            'account' : str(to_account),
            'block_number' : block_number
        }
        for i in range(DEVICE_TYPE_COUNT):
            if i == device_type:
                document [str(i)] = device_amount
            else:
                document [str(i)] = 0
        await info.storage.insert_one (
            f'u{univ}_player_balances',
            document
        )
    else:
        # print (f'handle_give_undeployed_device_occurred not NONE; performing find_one_and_update')
        await info.storage.find_one_and_update (
            collection = f'u{univ}_player_balances',
            filter = {'account' : str(to_account)},
            update = {
                '$inc' : {str(device_type) : device_amount},
                '$set' : {'block_number' : block_number}
            }
        )


async def handle_activate_universe_occurred (info, event, univ, block_number):
    #
    # Decode event
    #
    event_counter, civ_idx = decode_activate_universe_occurred_event (event)
    print(f'> event_counter={event_counter}, civ_idx={civ_idx}\n')
    # print (f"    -- event_counter={event_counter}, civ_idx={civ_idx}")

    #
    # Update database
    #
    await info.storage.find_one_and_update (
        collection = f'u{univ}_civ_state',
        filter = {"most_recent" : 1},
        update = {
            "$set" : {"most_recent" : 0}
        }
    )
    await info.storage.insert_one (
        f'u{univ}_civ_state',
        {
            "civ_idx" : civ_idx,
            "active"  : 1,
            "most_recent" : 1,
            "birth_block_number" : block_number,
            "fate" : "Undetermined"
        }
    )


async def handle_universe_activation_occurred (info, event):

    #
    # Decode event
    #
    event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_activation_occurred_event (event)
    print(f'> event_counter={event_counter}, universe_idx={universe_idx}, universe_adr={universe_adr}, arr_player_adr_len={arr_player_adr_len}, arr_player_adr={arr_player_adr}\n')
    # print (f"    -- event_counter={event_counter}, universe_idx={universe_idx}, universe_adr={universe_adr}, arr_player_adr_len={arr_player_adr_len}, arr_player_adr={arr_player_adr}")
    univ = universe_idx-777

    #
    # Update collection `u{}_player_balances`
    # Record in player_balances ~ {account, 0, 1, 2, ..., 15}, where 0-15 is the enumeration of device types
    #
    assert arr_player_adr_len == CIV_SIZE
    for player_index, account in enumerate (arr_player_adr):

        await info.storage.find_one_and_update (
            f'u{univ}_player_balances',
            {'account' : str(account)},
            {'$set': {'player_index' : player_index}}
        )

        # result = await info.storage.find_one (
        #     f'u{univ}_player_balances',
        #     {'account' : str(account)}
        # )
        # if result is None:
        #     document = {'account' : str(account), 'player_index' : player_index}
        #     for i in range(DEVICE_TYPE_COUNT):
        #         document [str(i)] = 0
        #     await info.storage.insert_one (
        #         f'u{univ}_player_balances',
        #         document
        #     )

    #
    # Update collection `lobby_queue`
    # -- document structure: {queue_idx, account, expired}
    #
    for account in arr_player_adr:
        result = await info.storage.find_one_and_update (
            collection = 'lobby_queue',
            filter = {
                'account' : str(account),
                'expired' : 0
            },
            update = {'$set' : {'expired' : 1}}
        )


async def handle_universe_deactivation_occurred (info, event):
    #
    # Decode event
    #
    event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_deactivation_occurred_event (event)
    print (f"> event_counter={event_counter}, universe_idx={universe_idx}, universe_adr={universe_adr}, arr_player_adr_len={arr_player_adr_len}, arr_player_adr={arr_player_adr}\n")
    univ = universe_idx-777

    #
    # Clear collection 'u{}_player_balances'
    #
    assert arr_player_adr_len == CIV_SIZE
    for account in arr_player_adr:
        result = await info.storage.delete_many (
            f'u{univ}_player_balances',
            {'account' : str(account)}
        )

    #
    # Clear collection 'u{}_deployed_devices'
    #
    await info.storage.delete_many (f'u{univ}_deployed_devices', {})

    #
    # Update collection 'u{}_civ_state'
    #
    await info.storage.find_one_and_update (
        f'u{univ}_civ_state',
        {"active" : 1},
        {"$set" : {"active" : 0}},
    )

    #
    # Clear collection 'u{}_macro_states'
    #
    await info.storage.delete_many (f'u{univ}_macro_states', {})

    #
    # Clear collections for all device types
    #
    await info.storage.delete_many (f'u{univ}_utx_sets', {})
    await info.storage.delete_many (f'u{univ}_deployed_pgs', {})
    await info.storage.delete_many (f'u{univ}_deployed_harvesters', {})
    await info.storage.delete_many (f'u{univ}_deployed_transformers', {})
    await info.storage.delete_many (f'u{univ}_deployed_upsfs', {})
    await info.storage.delete_many (f'u{univ}_deployed_ndpes', {})

    #
    # Clear collection 'u{}_impulses'
    #
    await info.storage.delete_many (f'u{univ}_impulses', {})


########################

#
# Handle block
#
async def handle_block (info: Info, block: NewBlock):
    # Use the provided RPC client to fetch the current block data.
    # The client is already initialized with the correct network based
    # on the indexer's settings.
    block = await info.rpc_client.get_block_by_hash(block.new_head.hash)
    block_time = datetime.fromtimestamp(block['accepted_time'])
    print(f'> new live block at {block_time}')



#
# Main
#
async def run_indexer (server_url=None, mongo_url=None, restart=None):

    if restart:
        async with Client.connect(server_url) as client:
            existing = await client.indexer_client().get_indexer(INDEXER_ID)
            if existing:
                await client.indexer_client().delete_indexer(INDEXER_ID)

    runner = IndexerRunner(
        config=IndexerRunnerConfiguration(
            apibara_url=server_url,
            storage_url=mongo_url,
        ),
        network_name="starknet-goerli",
        indexer_id=INDEXER_ID,
        new_events_handler=handle_events,
    )
    runner.add_block_handler(handle_block)

    # Create the indexer if it doesn't exist on the server,
    # otherwise it will resume indexing from where it left off.
    #
    # For now, this also helps the SDK map between human-readable
    # event names and StarkNet events.
    runner.create_if_not_exists(
        filters=[
            #
            # from universe.cairo
            #
            EventFilter.from_event_name (
                name    = 'forward_world_macro_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'give_undeployed_device_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'activate_universe_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'player_deploy_device_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'player_pickup_device_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'player_deploy_utx_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'player_pickup_utx_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'terminate_universe_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'resource_update_at_harvester_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'resource_update_at_transformer_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'resource_update_at_upsf_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'energy_update_at_device_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'impulse_applied_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'player_transfer_undeployed_device_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0].replace ('0x', '')
            ),

            #
            # from lobby.cairo
            #
            EventFilter.from_event_name (
                name    = 'universe_activation_occurred',
                address = ISAAC_LOBBY_ADDRESS.replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'universe_deactivation_occurred',
                address = ISAAC_LOBBY_ADDRESS.replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'ask_to_queue_occurred',
                address = ISAAC_LOBBY_ADDRESS.replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'give_invitation_occurred',
                address = ISAAC_LOBBY_ADDRESS.replace ('0x', '')
            )
        ],
        index_from_block = ORIGIN_BLOCK_TO_INDEX
    )

    await runner.run()
