"""Start the isaac indexer"""

import asyncio
import os
from functools import wraps

import click
from pymongo import MongoClient
from dotenv import load_dotenv

from isaac_api.apibara import ApplicationManager, Event, NewBlock, NewEvents, Reorg
from isaac_api.contract import decode_forward_world_event


load_dotenv()


def coro(f):
    @wraps(f)
    def wrapper(*args, **kwargs):
        return asyncio.run(f(*args, **kwargs))

    return wrapper


@click.group()
def cli():
    pass


@cli.command()
@click.argument("application-id", type=str)
@click.option("--index-from-block", type=int)
@coro
async def create(application_id, index_from_block=None):
    """Create a new application"""
    async with ApplicationManager.insecure_channel("localhost:7171") as app_manager:
        new_app = await app_manager.create_application(application_id, index_from_block)
        print(new_app)


@cli.command()
@coro
async def list():
    """List all applications"""
    async with ApplicationManager.insecure_channel("localhost:7171") as app_manager:
        apps = await app_manager.list_application()
        print(apps)


@cli.command()
@click.argument("application-id", type=str)
@coro
async def delete(application_id):
    """Delete the given application"""
    _mongo, isaac_db = _create_mongo_client_and_db()

    async with ApplicationManager.insecure_channel("localhost:7171") as app_manager:
        app = await app_manager.delete_application(application_id)
        print(f'Deleted: {app}')
    # server should delete data, but delete it here for now
    macro_states = isaac_db.macro_states
    macro_states.delete_many({})


@cli.command()
@click.argument("application-id", type=str)
@coro
async def start(application_id):
    """Start indexing the given application"""
    mongo, isaac_db = _create_mongo_client_and_db()
    macro_states = isaac_db.macro_states

    # Connect to Apibara server
    async with ApplicationManager.insecure_channel("localhost:7171") as app_manager:
        # Check if the given application exists
        app = await app_manager.get_application(application_id)
        if app is None:
            print(f'Application with id "{application_id}" does not exist')
            return

        # Connect as indexer. Apibara will start sending historical events at first,
        # then live block events.
        response_iter, client = await app_manager.connect_indexer()

        await client.connect_application(application_id)

        isaac_address = bytes.fromhex(
            "0758e8e3153a61474376838aeae42084dae0ef55e0206b19b2a85e039d1ef180"
        )

        async for response in response_iter:
            # New block and reorg are mostly used for reporting.
            # They are emitted only for live blocks.
            if isinstance(response, NewBlock):
                print(f"New Block: {response.new_head.number}")
            elif isinstance(response, Reorg):
                print(f"Reorg    : {response.new_head.number}")
            elif isinstance(response, NewEvents):
                print(f"New Event: {response.block_number}")
                # Decode raw event data into Isaac-specific data.
                assert len(response.events) == 1
                event = response.events[0]
                assert event.address == isaac_address
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
                                'block_number': response.block_number,
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