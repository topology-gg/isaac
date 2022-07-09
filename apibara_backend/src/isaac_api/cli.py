"""Start the isaac indexer"""

import os
import sys
import asyncio
from argparse import ArgumentParser
from datetime import datetime

from pymongo import MongoClient
from dotenv import load_dotenv

from apibara import NewEvents, IndexerRunner, NewBlock, Info, Client
from apibara.model import EventFilter

from isaac_api.contract import (
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
    decode_energy_update_at_device_occurred_event
)

load_dotenv ()

CIV_SIZE = 1
UNIVERSE_COUNT = 1
DEVICE_TYPE_COUNT = 16
ORIGIN_BLOCK_TO_INDEX = 262160 - 1
INDEXER_ID = 'isaac-alpha'

ISAAC_UNIVERSE_ADDRESSES = {
    0 : '0x0018ded891e678b9de30a154dbb47e4e3bb5eb4914295152f044e2b9cdb77e12'
}
ISAAC_LOBBY_ADDRESS = '0x0731a4412220eda41636f55303004a9316ce6ffa31ea7273ca9a664faa4747e1'

PG_TYPES = [0,1]
HARVESTER_TYPES = [2,3,4,5,6]
TRANSFORMER_TYPES = [7,8,9,10,11]
UTX_TYPES = [12,13]
UPSF_TYPE = 14
NDPE_TYPE = 15

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
class IsaacEventHandler:

    def __init__(self, db, mongo):
        self._db = db
        self._mongo = mongo

    async def handle_events(self, _info: Info, block_events: NewEvents):
        block_number = block_events.block_number
        for event in block_events.events:
            from_adr = hex ( int.from_bytes(event.address, "big") )
            from_univ = find_if_from_univ (from_adr)
            print (f'  - got event: name={event.name}, address={from_adr}, block_number={block_number}, from_univ={from_univ}')

            if event.name == 'forward_world_macro_occurred':
                self.handle_forward_world_macro_occurred (event, from_univ, block_number)

            elif event.name == 'give_undeployed_device_occurred':
                self.handle_give_undeployed_device_occurred (event, from_univ)

            elif event.name == 'activate_universe_occurred':
                self.handle_activate_universe_occurred (event, from_univ)

            elif event.name == 'universe_activation_occurred':
                self.handle_universe_activation_occurred (event)

            elif event.name == 'universe_deactivation_occurred':
                self.handle_universe_deactivation_occurred (event)

            elif event.name == 'player_deploy_device_occurred':
                self.handle_player_deploy_device_occurred (event, from_univ)

            elif event.name == 'player_pickup_device_occurred':
                self.handle_player_pickup_device_occurred (event, from_univ)

            elif event.name == 'terminate_universe_occurred':
                self.handle_terminate_universe_occurred (event, from_univ)

            elif event.name == 'player_deploy_utx_occurred':
                self.handle_player_deploy_utx_occurred (event, from_univ)

            elif event.name == 'player_pickup_utx_occurred':
                self.handle_player_pickup_utx_occurred (event, from_univ)

            elif event.name == 'resource_update_at_harvester_occurred':
                self.handle_resource_update_at_harvester_occurred (event, from_univ)

            elif event.name == 'resource_update_at_transformer_occurred':
                self.handle_resource_update_at_transformer_occurred (event, from_univ)

            elif event.name == 'resource_update_at_upsf_occurred':
                self.handle_resource_update_at_upsf_occurred (event, from_univ)

            elif event.name == 'energy_update_at_device_occurred':
                self.handle_energy_update_at_device_occurred (event, from_univ)

            print()


    def handle_resource_update_at_harvester_occurred (self, event, univ):

        #
        # Decode event
        #
        device_id, new_quantity = decode_resource_update_at_harvester_occurred_event (event)
        print (f'    -- resource update at harvester: device_id={device_id}, new_quantity={new_quantity}')
        #
        # Update collection 'u{i}_deployed_harvesters'
        # -- document structure: {id, device_type, resource, energy}
        #
        self._db [f'u{univ}_deployed_harvesters'].update_one (
            filter = {'id' : str(device_id)},
            update = {
                '$set' : {'resource' : new_quantity}
            }
        )


    def handle_resource_update_at_transformer_occurred (self, event, univ):

        #
        # Decode event
        #
        device_id, new_quantity_pre, new_quantity_post = decode_resource_update_at_transformer_occurred_event (event)
        print (f'    -- resource update at transformer: device_id={device_id}, new_quantity_pre={new_quantity_pre}, new_quantity_post={new_quantity_post}')

        #
        # Update collection 'u{i}_deployed_transformers'
        # -- document structure: {id, device_type, resource_pre, resource_post, energy}
        #
        self._db [f'u{univ}_deployed_transformers'].update_one (
            filter = {'id' : str(device_id)},
            update = {
                '$set' : {'resource_pre'  : new_quantity_pre},
                '$set' : {'resource_post' : new_quantity_post}
            }
        )


    def handle_resource_update_at_upsf_occurred (self, event, univ):

        #
        # Decode event
        #
        device_id, element_type, new_quantity = decode_resource_update_at_upsf_occurred_event (event)
        print (f'    -- resource update at upsf: device_id={device_id}, element_type={element_type}, new_quantity={new_quantity}')

        #
        # Update collection 'u{i}_deployed_upsfs'
        # -- document structure: {id, resource_0, resource_1, ..., resource_9}
        #
        self._db [f'u{univ}_deployed_upsfs'].update_one (
            filter = {'id' : str(device_id)},
            update = {
                '$set' : {f'resource_{element_type}' : new_quantity}
            }
        )


    def handle_energy_update_at_device_occurred (self, event, univ):

        #
        # Decode event
        #
        device_id, new_quantity = decode_energy_update_at_device_occurred_event (event)

        #
        # Find device type and determine if harvester / transformer / upsf / ndpe
        #
        result = self._db [f'u{univ}_deployed_devices'].find_one (
            {'id' : str(device_id)}
        )
        device_type = int (result ['type'])
        print (f'    -- energy update at device: device_type={device_type}, device_id={device_id}, new_quantity={new_quantity}')

        #
        # Update collection according to device_type
        #
        if (device_type in PG_TYPES):
            result = self._db [f'u{univ}_deployed_pgs'].update_one (
                {'id' : str(device_id)},
                {'$set' : {'energy' : new_quantity}}
            )
            assert result.matched_count == 1

        elif (device_type in HARVESTER_TYPES):
            result = self._db [f'u{univ}_deployed_harvesters'].update_one (
                {'id' : str(device_id)},
                {'$set' : {'energy' : new_quantity}}
            )
            assert result.matched_count == 1

        elif (device_type in TRANSFORMER_TYPES):
            result = self._db [f'u{univ}_deployed_transformers'].update_one (
                {'id' : str(device_id)},
                {'$set' : {'energy' : new_quantity}}
            )
            assert result.matched_count == 1

        elif (device_type == UPSF_TYPE):
            result = self._db [f'u{univ}_deployed_upsfs'].update_one (
                {'id' : str(device_id)},
                {'$set' : {'energy' : new_quantity}}
            )
            assert result.matched_count == 1

        elif (device_type == NDPE_TYPE):
            result = self._db [f'u{univ}_deployed_ndpes'].update_one (
                {'id' : str(device_id)},
                {'$set' : {'energy' : new_quantity}}
            )
            assert result.matched_count == 1

        else:
            raise Exception ('Invalid device type')


    def handle_player_deploy_utx_occurred (self, event, univ):
        #
        # Decode event
        #
        owner, utx_label, utx_device_type, src_device_grid, dst_device_grid, locs_len, locs = decode_player_deploy_utx_occurred_event (event)
        print (f'    owner={owner}, utx_label={utx_label}, utx_device_type={utx_device_type}, src_device_grid={src_device_grid}, dst_device_grid={dst_device_grid}, locs_len={locs_len}, locs={locs}')

        #
        # Update collection 'u{}_player_balances'
        #
        self._db [f'u{univ}_player_balances'].update_one (
            {'account' : str(owner)},
            {'$inc' : {str(utx_device_type) : -1*locs_len}}
        )

        #
        # Update collection 'u{}_deployed_devices'
        # -- document structure: {device_id, owner, type, grid}
        #
        db_name = f'u{univ}_deployed_devices'
        for i in range (locs_len):
            self._db [db_name].insert_one (
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
        self._db [f'u{univ}_utx_sets'].insert_one (
            {
                'label' : str(utx_label),
                'type'  : str(utx_device_type),
                'grids' : locs
            }
        )


    def handle_player_pickup_utx_occurred (self, event, univ):
        #
        # Decode event
        #
        owner, grid = decode_player_pickup_utx_occurred_event (event)
        print (f'    owner={owner}, grid={grid}')

        #
        # Update collection 'u{}_deployed_devices'
        #
        db_name = f'u{univ}_deployed_devices'
        result = self._db [db_name].find_one_and_delete ( # delete one
            {
                'owner' : str(owner),
                'grid'  : grid.to_json ()
            }
        )
        utx_label_str = result ['id']
        utx_device_type = result ['type']
        result = self._db [db_name].delete_many ( # delete the rest
            {
                'owner' : str(owner),
                'id'    : utx_label_str
            }
        )
        pickedup_count = result.deleted_count + 1

        #
        # Update collection 'u{}_player_balances'
        #
        self._db [f'u{univ}_player_balances'].update_one (
            {'account' : str(owner)},
            {'$inc' : {str(utx_device_type) : pickedup_count}}
        )

        #
        # Update collection 'u{}_utx_sets'
        # -- document structure: {label, type, grids}
        #
        result = self._db [f'u{univ}_utx_sets'].delete_one (
            {
                'label' : utx_label_str,
                'type'  : str(utx_device_type)
            }
        )
        assert result.deleted_count == 1


    def handle_terminate_universe_occurred (self, event, univ):
        #
        # Decode event
        #
        bool_universe_terminable, bool_destruction, bool_universe_max_age_reached, bool_universe_escape_condition_met = decode_terminate_universe_occurred_event (event)
        print (f'    terminable={bool_universe_terminable}, destruction={bool_destruction}, max_age_reached={bool_universe_max_age_reached}, escaped={bool_universe_escape_condition_met}')


    def handle_player_deploy_device_occurred (self, event, univ):
        #
        # Decode event
        #
        owner, device_id, device_type, grid = decode_player_deploy_device_occurred_event (event)

        #
        # Update collection 'u{}_deployed_devices'
        # -- document structure: {device_id, owner, type, grid}
        #
        db_name = f'u{univ}_deployed_devices'
        self._db [db_name].insert_one (
            {
                'owner' : str(owner),
                'id'    : str(device_id),
                'type'  : str(device_type),
                'grid'  : grid.to_json ()
            }
        )

        #
        # Update collection for maintaining resource & energy balance
        #
        if (device_type in PG_TYPES):
            self._db [f'u{univ}_deployed_pgs'].insert_one (
                {
                    'id' : str(device_id),
                    'type'  : str(device_type),
                    'energy' : 0
                }
            )

        elif (device_type in HARVESTER_TYPES):
            self._db [f'u{univ}_deployed_harvesters'].insert_one (
                {
                    'id' : str(device_id),
                    'type'  : str(device_type),
                    'resource' : 0,
                    'energy' : 0
                }
            )

        elif (device_type in TRANSFORMER_TYPES):
            self._db [f'u{univ}_deployed_transformers'].insert_one (
                {
                    'id' : str(device_id),
                    'type'  : str(device_type),
                    'resource_pre' : 0,
                    'resource_post' : 0,
                    'energy' : 0
                }
            )

        elif (device_type == UPSF_TYPE):
            self._db [f'u{univ}_deployed_upsfs'].insert_one (
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
            self._db [f'u{univ}_deployed_ndpes'].insert_one (
                {
                    'id' : str(device_id),
                    'energy' : 0
                }
            )

        #
        # Update collection 'u{}_player_balances'
        #
        self._db [f'u{univ}_player_balances'].update_one (
            {'account' : str(owner)},
            {'$inc' : {str(device_type) : -1}}
        )


    def handle_player_pickup_device_occurred (self, event, univ):
        #
        # Decode event
        #
        owner, grid = decode_player_pickup_device_occurred_event (event)

        #
        # Update collection 'u{}_deployed_devices'
        # -- document structure: {device_id, owner, type, grid}
        #
        db_name = f'u{univ}_deployed_devices'
        result = self._db [db_name].find_one_and_delete (
            {
                'owner' : str(owner),
                'grid' : grid.to_json ()
            }
        )
        print (f'  -- deleted: {result}')
        device_type_str = result ['type']

        #
        # Update collection for maintaining resource & energy balance
        # TODO
        #

        #
        # Update collection 'u{}_player_balances'
        #
        self._db [f'u{univ}_player_balances'].update_one (
            {'account' : str(owner)},
            {'$inc' : {device_type_str : +1}}
        )


    def handle_forward_world_macro_occurred (self, event, univ, block_number):
        #
        # Decode event
        #
        dynamics, phi = decode_forward_world_event (event)

        #
        # Update database
        #
        db_name = f'u{univ}_macro_states'
        with self._mongo.start_session () as sess:
            with sess.start_transaction () as tx:
                self._db [db_name].update_one ( # Clamp block range of previous value
                    {"_chain.valid_to" : None},
                    {"$set" : {"_chain.valid_to": block_number}},
                )
                self._db [db_name].insert_one (
                    {
                        "phi" : phi.to_bytes(32, "big"),
                        "dynamics" : dynamics.to_json(),
                        "block_number" : block_number,
                        "_chain" : {
                            "valid_from" : block_number,
                            "valid_to" : None,
                        },
                    }
                )


    def handle_give_undeployed_device_occurred (self, event, univ):
        #
        # Decode event
        #
        event_counter, to_account, device_type, device_amount = decode_give_undeployed_device_occurred_event (event)
        print (f"    -- event_counter={event_counter}, to_account={to_account}, device_type={device_type}, device_amount={device_amount}")

        #
        # Update database
        #
        db_name = f'u{univ}_player_balances'
        self._db [db_name].update_one (
            filter = {'account' : str(to_account)},
            update = {
                '$inc' : {str(device_type) : device_amount}
            },
            upsert = True
        )


    def handle_activate_universe_occurred (self, event, univ):
        #
        # Decode event
        #
        event_counter, civ_idx = decode_activate_universe_occurred_event (event)
        print (f"    -- event_counter={event_counter}, civ_idx={civ_idx}")

        #
        # Update database
        #
        db_name = f'u{univ}_civ_state'
        self._db [db_name].update_one (
            filter = {"most_recent" : 1},
            update = {
                "$set" : {"most_recent" : 0}
            }
        )
        self._db [db_name].insert_one (
            {
                "civ_idx" : civ_idx,
                "active"  : 1,
                "most_recent" : 1
            }
        )


    def handle_universe_activation_occurred (self, event):
        #
        # Decode event
        #
        event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_activation_occurred_event (event)
        print (f"    -- event_counter={event_counter}, universe_idx={universe_idx}, universe_adr={universe_adr}, arr_player_adr_len={arr_player_adr_len}, arr_player_adr={arr_player_adr}")
        univ = universe_idx-777

        #
        # Update database
        # Record in player_balances ~ {account, 0, 1, 2, ..., 15}, where 0-15 is the enumeration of device types
        #
        assert arr_player_adr_len == CIV_SIZE
        for account in arr_player_adr:
            for i in range(DEVICE_TYPE_COUNT):
                self._db [f'u{univ}_player_balances'].update_one (
                    filter = {
                        'account' : str(account),
                        str(i) : {'$exists' : False}
                    },
                    update = {'$set' : {str(i) : 0}}
                )


    def handle_universe_deactivation_occurred (self, event):
        #
        # Decode event
        #
        event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_deactivation_occurred_event (event)
        print (f"    -- event_counter={event_counter}, universe_idx={universe_idx}, universe_adr={universe_adr}, arr_player_adr_len={arr_player_adr_len}, arr_player_adr={arr_player_adr}")
        univ = universe_idx-777

        #
        # Update collection 'u{}_player_balances'
        #
        assert arr_player_adr_len == CIV_SIZE
        for account in arr_player_adr:
            result = self._db [f'u{univ}_player_balances'].delete_one ({'account' : str(account)})
            assert result.deleted_count == 1
        record_count_after_deactivation = self._db [f'u{univ}_player_balances'].count_documents ({})
        assert record_count_after_deactivation == 0

        #
        # Clear collection 'u{}_deployed_devices'
        #
        self._db [f'u{univ}_deployed_devices'].delete_many ({})

        #
        # Update collection 'u{}_civ_state'
        #
        self._db [f'u{univ}_civ_state'].update_one (
            {"active" : 1},
            {"$set" : {"active" : 0}},
        )



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
async def start (args):

    parser = ArgumentParser()
    parser.add_argument("--reset", action="store_true", default=False)
    args = parser.parse_args()

    if args.reset:
        async with Client.connect() as client:
            existing = await client.indexer_client().get_indexer(INDEXER_ID)
            if existing:
                await client.indexer_client().delete_indexer(INDEXER_ID)
                print('> Indexer deleted. Starting from beginning.')

    mongo, isaac_db = _create_mongo_client_and_db ()
    db = {}
    # for i in range(UNIVERSE_COUNT):
    #     db [f'u{i}_macro_states']     = isaac_db.universe0_macro_states
    #     db [f'u{i}_player_balances']  = isaac_db.universe0_player_balances
    #     db [f'u{i}_civ_state']        = isaac_db.universe0_civ_state
    #     db [f'u{i}_deployed_devices'] = isaac_db.universe0_civ_state

    i=0
    db [f'u{i}_macro_states']     = isaac_db.universe0_macro_states
    db [f'u{i}_player_balances']  = isaac_db.universe0_player_balances
    db [f'u{i}_civ_state']        = isaac_db.universe0_civ_state
    db [f'u{i}_deployed_devices'] = isaac_db.universe0_deployed_devices
    db [f'u{i}_utx_sets']         = isaac_db.universe0_utx_sets
    db [f'u{i}_deployed_pgs']          = isaac_db.universe0_deployed_pgs
    db [f'u{i}_deployed_harvesters']   = isaac_db.universe0_deployed_harvesters
    db [f'u{i}_deployed_transformers'] = isaac_db.universe0_deployed_transformers
    db [f'u{i}_deployed_upsfs']        = isaac_db.universe0_deployed_upsfs
    db [f'u{i}_deployed_ndpes']        = isaac_db.universe0_deployed_ndpes

    isaac_event_handler = IsaacEventHandler (db = db, mongo = mongo)

    runner = IndexerRunner (
        indexer_id = INDEXER_ID,
        new_events_handler = isaac_event_handler.handle_events,
    )
    runner.add_block_handler (handle_block)

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
            )
        ],
        index_from_block = ORIGIN_BLOCK_TO_INDEX
    )

    await runner.run()

def main():
    asyncio.run (start(sys.argv[1:]))

