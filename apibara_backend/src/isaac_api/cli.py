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
    decode_universe_deactivation_occurred_event
)

load_dotenv()

CIV_SIZE = 1
DEVICE_TYPE_COUNT = 16
ORIGIN_BLOCK_TO_INDEX = 258_728
INDEXER_ID = 'isaac-alpha'

ISAAC_UNIVERSE_ADDRESSES = {
    0 : '009e86bbb24b17eb64d8d9c18767013f457e28621d610345414bbf453ffab64d'
}
ISAAC_LOBBY_ADDRESS = '027313e9743ef91baa9cbdbabb8cba579f0a19c009ef7d0b8e77b5500804d24b'

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
        # Update database: both universe0_player_balances and universe0_civ_state
        #
        assert arr_player_adr_len == CIV_SIZE
        for account in arr_player_adr:
            result = self._db [f'u{univ}_player_balances'].delete_one ({'account' : account})
            assert result.deleted_count == 1
        record_count_after_deactivation = self._db [f'u{univ}_player_balances'].count_documents ({})
        assert record_count_after_deactivation == 0

        self._db [f'u{univ}_civ_state'].update_one (
            {"active" : 1},
            {"$set" : {"active" : 0}},
        )


########################


async def handle_events (_info: Info, block_events: NewEvents):
    print ('> new event at block {block_events.block_number}')

    for event in block_events.events:
        from_adr = hex ( int.from_bytes(event.address, "big") )
        from_univ = find_if_from_univ (from_adr)
        print (f'  - got event: name={event.name}, address={from_adr}, from_univ={from_univ}')

        if event.name == 'forward_world_macro_occurred':
            handle_forward_world_macro_occurred (event, from_univ)

        elif event.name == 'give_undeployed_device_occurred':
            handle_give_undeployed_device_occurred (event, from_univ)

        elif event.name == 'activate_universe_occurred':
            handle_activate_universe_occurred (event, from_univ)

        elif event.name == 'universe_activation_occurred':
            handle_universe_activation_occurred (event)

        elif event.name == 'universe_deactivation_occurred':
            handle_universe_deactivation_occurred (event)

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
    db ['u0_macro_states']    = isaac_db.universe0_macro_states
    db ['u0_player_balances'] = isaac_db.universe0_player_balances
    db ['u0_civ_state']       = isaac_db.universe0_civ_state
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
            EventFilter.from_event_name (
                name    = 'forward_world_macro_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0]
            ),
            EventFilter.from_event_name (
                name    = 'give_undeployed_device_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0]
            ),
            EventFilter.from_event_name (
                name    = 'activate_universe_occurred',
                address = ISAAC_UNIVERSE_ADDRESSES [0]
            ),
            EventFilter.from_event_name (
                name    = 'universe_activation_occurred',
                address = ISAAC_LOBBY_ADDRESS
            ),
            EventFilter.from_event_name (
                name    = 'universe_deactivation_occurred',
                address = ISAAC_LOBBY_ADDRESS
            )
        ],
        index_from_block = ORIGIN_BLOCK_TO_INDEX
    )

    await runner.run()

def main():
    asyncio.run (start(sys.argv[1:]))

