"""Start the s2m2 indexer"""

import os
import sys
import asyncio
from argparse import ArgumentParser
from datetime import datetime

from pymongo import MongoClient
from dotenv import load_dotenv

from apibara import NewEvents, IndexerRunner, NewBlock, Info, Client
from apibara.indexer.runner import IndexerRunnerConfiguration
from apibara.model import EventFilter

from s2m2_api.contract import (
    decode_new_puzzle_occurred,
    decode_success_occurred
)

load_dotenv()

ORIGIN_BLOCK_TO_INDEX = 267_807 - 1
INDEXER_ID = 's2m2'
S2M2_ADDRESS = '0x02369dbd0ec5e3e152aef28d10042abdf7a22a316c667e2a880bd4c0978e448b'

def _create_mongo_client_and_db():
    mongo_connection_url = os.getenv ("S2M2_MONGO_URL")
    mongo_db_name = os.getenv ("S2M2_MONGO_DB_NAME")

    mongo = MongoClient (mongo_connection_url)
    s2m2_db = mongo [mongo_db_name]

    #
    # Check database status before processing events
    #
    db_status = s2m2_db.command ("serverStatus")
    print (f'> MongoDB connected: {db_status["host"]}')

    MONGO = mongo

    return mongo, s2m2_db


#
# Handle events
#
class S2M2EventHandler:

    def __init__(self, db, mongo):
        self._db = db
        self._mongo = mongo

    async def handle_events(self, _info: Info, block_events: NewEvents):
        block_number = block_events.block_number

        for event in block_events.events:
            from_adr = hex ( int.from_bytes(event.address, "big") )
            print (f'  - got event: name={event.name}, address={from_adr}')

            if event.name == 'new_puzzle_occurred':
                self.handle_new_puzzle_occurred (event)

            elif event.name == 'success_occurred':
                self.handle_success_occurred (event)

            elif event.name == 's2m_ended_occurred':
                self.handle_s2m_ended_occurred () # this event has no payload


    def handle_new_puzzle_occurred (self, event):
        #
        # Decode event
        #
        puzzle_id, arr_circles_len, arr_circles = decode_new_puzzle_occurred (event)

        #
        # Update collection
        #
        self._db ['puzzles'].insert_one (
            {
                'puzzle_id' : puzzle_id,
                'circles' : [
                    circle.to_json() for circle in arr_circles
                ],
                'solved' : 0,
                'solver' : 0,
                'solution' : []
            }
        )


    def handle_success_occurred (self, event):
        #
        # Decode event
        #
        solver, puzzle_id, arr_cell_indices_len, arr_cell_indices = decode_success_occurred (event)
        print (f'> success_occurred: solver={solver}, puzzle_id={puzzle_id}, arr_cell_indices_len={arr_cell_indices_len}, arr_cell_indices={arr_cell_indices}')

        #
        # Update collection
        #
        self._db ['puzzles'].update_one (
            filter = {'puzzle_id' : puzzle_id},
            update = {
                '$set' : {
                    'solved' : 1,
                    'solver' : str(solver),
                    'solution' : arr_cell_indices
                }
            }
        )


    def handle_s2m_ended_occurred ():
        #
        # Update collection
        #
        self._db['status'].update_one (
            {'active' : 1},
            {'$set' : {'active' : 0}}
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
    parser.add_argument("--server-url", default=None)
    args = parser.parse_args()

    if args.reset:
        async with Client.connect(args.server_url) as client:
            existing = await client.indexer_client().get_indexer(INDEXER_ID)
            if existing:
                await client.indexer_client().delete_indexer(INDEXER_ID)
                print('> Indexer deleted. Starting from beginning.')

    mongo, s2m2_db = _create_mongo_client_and_db ()
    db = {}
    db ['puzzles'] = s2m2_db.puzzles
    db ['status']  = s2m2_db.state
    db ['status'].insert_one (
        {'active' : 1}
    )

    s2m2_event_handler = S2M2EventHandler (db = db, mongo = mongo)
    runner = IndexerRunner (
        indexer_id = INDEXER_ID,
        new_events_handler = s2m2_event_handler.handle_events,
        config=IndexerRunnerConfiguration(
            apibara_url=args.server_url,
        )
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
                name    = 'new_puzzle_occurred',
                address = S2M2_ADDRESS.replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 'success_occurred',
                address = S2M2_ADDRESS.replace ('0x', '')
            ),
            EventFilter.from_event_name (
                name    = 's2m_ended_occurred',
                address = S2M2_ADDRESS.replace ('0x', '')
            )
        ],
        index_from_block = ORIGIN_BLOCK_TO_INDEX
    )

    await runner.run()

def main():
    asyncio.run (start(sys.argv[1:]))

