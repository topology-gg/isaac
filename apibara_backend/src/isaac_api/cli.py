"""Start the isaac indexer"""

import asyncio
import os
import sys
from argparse import ArgumentParser


from pymongo import MongoClient
from dotenv import load_dotenv
from apibara import IndexerManagerClient
from apibara.client import contract_event_filter
from apibara.model import NewBlock, NewEvents, Reorg
from apibara.starknet import get_selector_from_name

from isaac_api.contract import decode_forward_world_event


load_dotenv()



async def start(argv):
    """Start indexing the given indexer"""
    parser = ArgumentParser()
    parser.add_argument('indexer_id')
    parser.add_argument('--reset', action='store_true')
    parser.add_argument('--server-url', default='localhost:7171')

    args = parser.parse_args(argv)

    indexer_id = args.indexer_id

    mongo, isaac_db = _create_mongo_client_and_db()
    macro_states = isaac_db.macro_states

    isaac_contract_address = bytes.fromhex("0758e8e3153a61474376838aeae42084dae0ef55e0206b19b2a85e039d1ef180")
    # Connect to Apibara server
    async with IndexerManagerClient.insecure_channel("localhost:7171") as app_manager:
        filters = [
            contract_event_filter('forward_world_macro_occurred', address=isaac_contract_address),
            contract_event_filter('universe_activation_occurred', address=isaac_contract_address),
            contract_event_filter('universe_deactivation_occurred', address=isaac_contract_address),
        ]

        # Check if the given indexer exists
        app = await app_manager.get_indexer(indexer_id)
        if app is not None:
            print(f'Indexer with id "{indexer_id}" already exist.')
            if args.reset:
                print(f'Reset flag specified. Deleting and restarting.')
                await app_manager.delete_indexer(indexer_id)
                app = await app_manager.create_indexer(indexer_id, 200_000, filters)
        else:
            print(f'Creating indexer with id "{indexer_id}".')
            app = await app_manager.create_indexer(indexer_id, 200_000, filters)

        # Connect as indexer. Apibara will start sending historical events at first,
        # then live block events.
        response_iter, client = await app_manager.connect_indexer()

        await client.connect_indexer(indexer_id)

        async for response in response_iter:
            # New block and reorg are mostly used for reporting.
            # They are emitted only for live blocks.
            if isinstance(response, NewBlock):
                print(f"New Block: {response.new_head.number}")
            elif isinstance(response, Reorg):
                print(f"Reorg    : {response.new_head.number}")
            elif isinstance(response, NewEvents):
                # Inform Apibara server that we processed the block.
                print(f"New Event: {response.block_number}")

                # Block can contain more than one event
                for event in response.events:
                    event.topics[0] # contains the hash of the event name.
                    event.data # contains the parameters of the event

                # Old indexer code. Use as reference.
                # Decode raw event data into Isaac-specific data.
                assert len(response.events) == 1
                event = response.events[0]
                dynamics, phi = decode_forward_world_event(event)

                print("Sun 0  = ", dynamics.sun0.q.x, dynamics.sun0.q.y)
                print("Sun 1  = ", dynamics.sun1.q.x, dynamics.sun1.q.y)
                print("Sun 2  = ", dynamics.sun2.q.x, dynamics.sun2.q.y)
                print("Planet = ", dynamics.planet.q.x, dynamics.planet.q.y)
                print("phi    = ", phi)

                # Update data stored in the database.
                with mongo.start_session() as sess:
                    with sess.start_transaction() as tx:
                        # Clamp block range of previous value
                        macro_states.update_one(
                            {"_chain.valid_to": None},
                            {"$set": {"_chain.valid_to": response.block_number}},
                        )

                        macro_states.insert_one(
                            {
                                "phi": phi.to_bytes(32, "big"),
                                "dynamics": dynamics.to_json(),
                                "block_number": response.block_number,
                                "_chain": {
                                    "valid_from": response.block_number,
                                    "valid_to": None,
                                },
                            }
                        )

                # Inform Apibara server that we processed the block.
                await client.ack_block(response.block_hash)


def _create_mongo_client_and_db():
    mongo_connection_url = os.getenv("ISAAC_MONGO_URL")
    mongo_db_name = os.getenv("ISAAC_MONGO_DB_NAME")

    mongo = MongoClient(mongo_connection_url)
    isaac_db = mongo[mongo_db_name]

    # Check database status before processing events
    db_status = isaac_db.command("serverStatus")
    print(f'MongoDB connected: {db_status["host"]}')

    return mongo, isaac_db


def main():
    asyncio.run(start(sys.argv[1:]))
