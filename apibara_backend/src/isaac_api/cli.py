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

async def start(argv):
    """Start indexing the given indexer"""
    parser = ArgumentParser()
    parser.add_argument('indexer_id')
    parser.add_argument('--reset', action='store_true')
    parser.add_argument('--server-url', default='localhost:7171')

    args = parser.parse_args(argv)

    indexer_id = args.indexer_id

    mongo, isaac_db = _create_mongo_client_and_db ()
    universe0_macro_states    = isaac_db.universe0_macro_states
    universe0_player_balances = isaac_db.universe0_player_balances
    universe0_civ_state       = isaac_db.universe0_civ_state

    isaac_universe0_address = bytes.fromhex ("009e86bbb24b17eb64d8d9c18767013f457e28621d610345414bbf453ffab64d")
    isaac_lobby_address = bytes.fromhex ("027313e9743ef91baa9cbdbabb8cba579f0a19c009ef7d0b8e77b5500804d24b")

    #
    # Connect to Apibara server
    #
    async with IndexerManagerClient.insecure_channel("localhost:7171") as app_manager:
        filters = [
            contract_event_filter('forward_world_macro_occurred',    address=isaac_universe0_address),
            contract_event_filter('give_undeployed_device_occurred', address=isaac_universe0_address),
            contract_event_filter('activate_universe_occurred',      address=isaac_universe0_address),

            contract_event_filter('universe_activation_occurred',   address=isaac_lobby_address),
            contract_event_filter('universe_deactivation_occurred', address=isaac_lobby_address)
        ]

        #
        # Check if the given indexer exists
        #
        app = await app_manager.get_indexer(indexer_id)
        if app is not None:
            print(f'Indexer with id "{indexer_id}" already exist.')
            if args.reset:
                print(f'Reset flag specified. Deleting and restarting.')
                await app_manager.delete_indexer(indexer_id)
                app = await app_manager.create_indexer(indexer_id, ORIGIN_BLOCK_TO_INDEX, filters)
        else:
            print(f'Creating indexer with id "{indexer_id}".')
            app = await app_manager.create_indexer(indexer_id, ORIGIN_BLOCK_TO_INDEX, filters)

        #
        # Connect as indexer.
        # Apibara will start sending historical events at first, then live block events.
        #
        response_iter, client = await app_manager.connect_indexer()

        await client.connect_indexer(indexer_id)

        async for response in response_iter:
            #
            # New block and reorg are mostly used for reporting.
            # They are emitted only for live blocks.
            #
            if isinstance(response, NewBlock):
                print(f"New Block: {response.new_head.number}")
            elif isinstance(response, Reorg):
                print(f"Reorg    : {response.new_head.number}")

            elif isinstance(response, NewEvents):
                #
                # Inform Apibara server that we processed the block.
                #
                print(f"New Event: {response.block_number}")
                # print(f"> response.events:")
                # for event in response.events:
                #     print(f"  -- big order: { int.from_bytes(event.topics[0], 'big') }")
                #     print()
                # print()

                # print(f"> give_undeployed_device_occurred == {get_selector_from_name ('give_undeployed_device_occurred')}")

                #
                # Iterate over all events in this block,
                # and handle according to event type
                #
                for event in response.events:

                    event_topic = int.from_bytes(event.topics[0], 'big')

                    #
                    # handle event: universe0::forward_world_macro_occurred
                    #
                    if event_topic == get_selector_from_name ('forward_world_macro_occurred'):
                        print("> event name: forward_world_macro_occurred")
                        print("> event from: universe0")
                        print()

                        #
                        # Decode event
                        #
                        dynamics, phi = decode_forward_world_event (event)

                        #
                        # Update database
                        #
                        with mongo.start_session () as sess:
                            with sess.start_transaction () as tx:
                                universe0_macro_states.update_one ( # Clamp block range of previous value
                                    {"_chain.valid_to" : None},
                                    {"$set" : {"_chain.valid_to": response.block_number}},
                                )
                                universe0_macro_states.insert_one (
                                    {
                                        "phi" : phi.to_bytes(32, "big"),
                                        "dynamics" : dynamics.to_json(),
                                        "block_number" : response.block_number,
                                        "_chain" : {
                                            "valid_from" : response.block_number,
                                            "valid_to" : None,
                                        },
                                    }
                                )

                    #
                    # handle event: universe0::give_undeployed_device_occurred
                    #
                    elif event_topic == get_selector_from_name ('give_undeployed_device_occurred'):
                        print("> event name: give_undeployed_device_occurred")
                        print("> event from: universe0")

                        #
                        # Decode event
                        #
                        event_counter, to_account, device_type, device_amount = decode_give_undeployed_device_occurred_event (event)
                        print (f"> event_counter={event_counter}, to_account={to_account}, device_type={device_type}, device_amount={device_amount}")
                        print ()

                        #
                        # Update database
                        #
                        universe0_player_balances.update_one (
                            filter = {'account' : str(to_account)},
                            update = {
                                '$inc' : {str(device_type) : device_amount}
                            }
                        )

                    #
                    # handle event: universe0::activate_universe_occurred
                    #
                    elif event_topic == get_selector_from_name ('activate_universe_occurred'):
                        print ("> event name: activate_universe_occurred")
                        print ("> event from: universe0")

                        #
                        # Decode event
                        #
                        event_counter, civ_idx = decode_activate_universe_occurred_event (event)
                        print (f"> event_counter={event_counter}, civ_idx={civ_idx}")
                        print ()

                        #
                        # Update database
                        #
                        universe0_civ_state.update_one (
                            filter = {"most_recent" : 1},
                            update = {
                                "$set" : {"most_recent" : 0}
                            }
                        )
                        universe0_civ_state.insert_one (
                            {
                                "civ_idx" : civ_idx,
                                "active"  : 1,
                                "most_recent" : 1
                            }
                        )

                    #
                    # handle event: lobby::universe_activation_occurred
                    #
                    elif event_topic == get_selector_from_name ('universe_activation_occurred'):
                        print("> event name: universe_activation_occurred")
                        print("> event from: lobby")

                        #
                        # Decode event
                        #
                        event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_activation_occurred_event (event)
                        print (f"> event_counter={event_counter}, universe_idx={universe_idx}, universe_adr={universe_adr}, arr_player_adr_len={arr_player_adr_len}, arr_player_adr={arr_player_adr}")
                        print ()

                        #
                        # Update database
                        # Record in player_balances ~ {account, 0, 1, 2, ..., 15}, where 0-15 is the enumeration of device types
                        #
                        assert arr_player_adr_len == CIV_SIZE
                        for account in arr_player_adr:
                            new_record = {
                                'account': str(account)
                            }

                            for i in range(DEVICE_TYPE_COUNT):
                                new_record [ str(i) ] = 0

                            universe0_player_balances.insert_one (
                                new_record
                            )


                    #
                    # handle event: lobby::universe_deactivation_occurred
                    #
                    elif event_topic == get_selector_from_name ('universe_deactivation_occurred'):
                        print("> event name: universe_deactivation_occurred")
                        print("> event from: lobby")
                        print()

                        #
                        # Decode event
                        #
                        event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_deactivation_occurred_event (event)

                        #
                        # Update database: both universe0_player_balances and universe0_civ_state
                        #
                        assert arr_player_adr_len == CIV_SIZE
                        for account in arr_player_adr:
                            result = universe0_player_balances.delete_one ({'account' : account})
                            assert result.deleted_count == 1
                        record_count_after_deactivation = universe0_player_balances.count_documents ({})
                        assert record_count_after_deactivation == 0

                        universe0_civ_state.update_one (
                            {"active" : 1},
                            {"$set" : {"active" : 0}},
                        )

                #
                # Inform Apibara server that we processed the block.
                #
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
