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

#
# Handle events
#
async def handle_events(info: Info, block_events: NewEvents):
    block_number = block_events.block.number
    print(f'> Block {block_number}')

    for event in block_events.events:
        from_adr = hex ( int.from_bytes(event.address, "big") )
        print (f'  - got event: name={event.name}, address={from_adr}')

        if event.name == 'new_puzzle_occurred':
            await handle_new_puzzle_occurred (info, event)

        elif event.name == 'success_occurred':
            await handle_success_occurred (info, event)

        elif event.name == 's2m_ended_occurred':
            await handle_s2m_ended_occurred (info) # this event has no payload


async def handle_new_puzzle_occurred(info, event):
    #
    # Decode event
    #
    puzzle_id, arr_circles_len, arr_circles = decode_new_puzzle_occurred (event)

    #
    # Update collection
    #
    await info.storage.insert_one('puzzles',
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


async def handle_success_occurred(info, event):
    #
    # Decode event
    #
    solver, puzzle_id, arr_cell_indices_len, arr_cell_indices = decode_success_occurred (event)
    print (f'> success_occurred: solver={solver}, puzzle_id={puzzle_id}, arr_cell_indices_len={arr_cell_indices_len}, arr_cell_indices={arr_cell_indices}')

    #
    # Update collection
    #
    await info.storage.find_one_and_update(
        collection = 'puzzles',
        filter = {'puzzle_id' : puzzle_id},
        update = {
            '$set' : {
                'solved' : 1,
                'solver' : str(solver),
                'solution' : arr_cell_indices
            }
        }
    )


async def handle_s2m_ended_occurred (info):
    #
    # Update collection
    #
    await info.storage.find_one_and_update(
        collection='status',
        filter = {'active' : 1},
        update = {'$set' : {'active' : 0}}
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
    print(f'> new live block {block["block_number"]} at {block_time}')

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
