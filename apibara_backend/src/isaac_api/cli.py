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

from isaac_api.contract import decode_forward_world_event, decode_give_undeployed_device_occurred_event


load_dotenv()

CIV_SIZE = 1
DEVICE_TYPE_COUNT = 16

async def start(argv):
    """Start indexing the given indexer"""
    parser = ArgumentParser()
    parser.add_argument('indexer_id')
    parser.add_argument('--reset', action='store_true')
    parser.add_argument('--server-url', default='localhost:7171')

    args = parser.parse_args(argv)

    indexer_id = args.indexer_id

    mongo, isaac_db = _create_mongo_client_and_db()
    universe0_macro_states    = isaac_db.macro_states
    universe0_player_balances = isaac_db.player_balances
    universe0_civ_state       = isaac_db.universe0_states

    isaac_universe0_address = bytes.fromhex ("0x00a3b8dee21daab96058098a65c5cd9974fc5088d9f3d1f2bfcbe1a872a70dee")
    isaac_lobby_address = bytes.fromhex ("0x07da5da722f0adb725f727300c0c1ea8403120c8aa5b2e3e1d36aba926962c56")

    #
    # Connect to Apibara server
    #
    async with IndexerManagerClient.insecure_channel("localhost:7171") as app_manager:
        filters = [
            contract_event_filter('universe0_forward_world_macro_occurred',    address=isaac_universe0_address),
            contract_event_filter('universe0_give_undeployed_device_occurred', address=isaac_universe0_address),
            contract_event_filter('universe0_activate_universe_occurred',      address=isaac_universe0_address),

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
                app = await app_manager.create_indexer(indexer_id, 200_000, filters)
        else:
            print(f'Creating indexer with id "{indexer_id}".')
            app = await app_manager.create_indexer(indexer_id, 200_000, filters)

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

                #
                # Iterate over all events in this block,
                # and handle according to event type
                #
                for event in response.events:

                    #
                    # handle event: universe0::forward_world_macro_occurred
                    #
                    if event.topics[0] == get_selector_name ('universe0_forward_world_macro_occurred'):

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
                                    {"_chain.valid_to": None},
                                    {"$set": {"_chain.valid_to": response.block_number}},
                                )
                                universe0_macro_states.insert_one (
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

                    #
                    # handle event: universe0::give_undeployed_device_occurred
                    #
                    elif event.topics[0] == get_selector_name ('universe0_give_undeployed_device_occurred')

                        #
                        # Decode event
                        #
                        event_counter, to_account, device_type, device_amount = decode_give_undeployed_device_occurred_event (event)

                        #
                        # Construct new record for player_balances
                        # record in player_balances ~ {account, 0, 1, 2, ..., 15}, where 0-15 is the enumeration of device types
                        #
                        record = universe0_player_balances.find_one (
                            {
                                'account': to_account
                            }
                        )
                        old_device_amount = record [device_type]
                        new_record = {'account': to_account}
                        for i in range(DEVICE_TYPE_COUNT):
                            new_record [i] = 0
                        new_record [device_type] = old_device_amount + device_amount

                        #
                        # Update database
                        #
                        universe0_player_balances.replace_one(
                            {'account': to_account},
                            new_record,
                            upsert = False
                        )

                    #
                    # handle event: universe0::activate_universe_occurred
                    #
                    elif event.topics[0] == get_selector_name ('universe0_activate_universe_occurred'):

                        #
                        # Decode event
                        #
                        event_counter, civ_idx = decode_activate_universe_occurred_event (event)

                        #
                        # Update database
                        #
                        universe0_civ_state.insert_one (
                            {
                                "civ_idx" : civ_idx,
                                "active"  : 1,
                                "block_number": response.block_number
                            }
                        )

                    #
                    # handle event: lobby::universe_activation_occurred
                    #
                    elif event.topics[0] == get_selector_name ('universe_activation_occurred'):

                        #
                        # Decode event
                        #
                        event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr = decode_universe_activation_occurred_event (event)

                        #
                        # Update database
                        #
                        assert arr_player_adr_len == CIV_SIZE
                        for account in arr_player_adr:
                            new_record = {
                                'account': account
                            }

                            for i in range(DEVICE_TYPE_COUNT):
                                new_record [i] = 0

                            universe0_player_balances.insert_one (
                                new_record
                            )


                    #
                    # handle event: lobby::universe_deactivation_occurred
                    #
                    elif event.topics[0] == get_selector_name ('universe_deactivation_occurred'):

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

                        ## find the record with active:1 and turn it off
                        universe0_civ_state.update_one (
                            {"active" : 1},
                            {"$set": {"active" : 0}},
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
