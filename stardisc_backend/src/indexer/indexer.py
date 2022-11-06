import os

from apibara import EventFilter, IndexerRunner, Info, NewEvents, NewBlock
from apibara.indexer import IndexerRunnerConfiguration

from indexer.contract import (
    decode_sns_register_occurred
)

indexer_id = os.getenv('INDEXER_ID', 'stardisc')
STARDISC_ADDR = '0x0367846f4e87762424244c9891a5db6c242b270632ff2d82bfe1ed0907dfddf5'
BIRTH_BLOCK = 307806 # deploy tx hash: 0x84f9a339eb3f94d30bd5e333e241721f22366ba999687a205ae9dd26a61936

async def handle_events(info: Info, block_events: NewEvents):
    """Handle a group of events grouped by block."""
    print(f"Received events for block {block_events.block.number}")
    for event in block_events.events:
        print(event)

    events = [
        {"address": event.address, "data": event.data, "name": event.name}
        for event in block_events.events
    ]

    # Insert multiple documents in one call.
    await info.storage.insert_many("events", events)

    for event in block_events.events:
        if event.name == 'sns_register_occurred':
            await handle_sns_register_occurred (info, event)


async def handle_sns_register_occurred (info, event):
    #
    # Decode event
    #
    addr, name = decode_sns_register_occurred (event)

    #
    # Update/insert record
    #
    # existing = await info.storage.find_one_and_update (
    #     collection = 'registry',
    #     filter = {'addr' : str(addr)},
    #     update = {
    #         '$set' : {'name' : str(name)}
    #     }
    # )

    # if not existing:
    #     await info.storage.insert_one (
    #         collection = 'registry',
    #         doc = {
    #             'addr' : str(addr),
    #             'name' : str(name)
    #         }
    #     )

    await info.storage.find_one_and_replace (
        collection = 'registry',
        filter = {'addr' : str(addr)},
        replacement = {
            'addr' : str(addr),
            'name' : str(name)
        },
        upsert = True
    )


async def handle_block(info: Info, block: NewBlock):
    """Handle a new _live_ block."""
    print(block.new_head)


async def run_indexer(server_url=None, mongo_url=None, restart=None):
    print("Starting Apibara indexer")

    runner = IndexerRunner(
        config=IndexerRunnerConfiguration(
            apibara_url=server_url,
            storage_url=mongo_url,
        ),
        reset_state=restart,
        indexer_id=indexer_id,
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
            EventFilter.from_event_name(
                name = "sns_register_occurred",
                address = STARDISC_ADDR,
            )
        ],
        index_from_block = BIRTH_BLOCK - 1,
    )

    print("Initialization completed. Entering main loop.")

    await runner.run()
