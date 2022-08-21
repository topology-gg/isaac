from apibara import Client, IndexerRunner, Info, NewBlock, NewEvents
from apibara.indexer.runner import IndexerRunnerConfiguration
from apibara.model import EventFilter
from pymongo import MongoClient

indexer_id = "my-indexer"


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


async def handle_block(info: Info, block: NewBlock):
    """Handle a new _live_ block."""
    print(block.new_head)


async def run_indexer(server_url=None, mongo_url=None, restart=None):
    print("Starting Apibara indexer")
    if mongo_url is None:
        mongo_url = "mongodb://apibara:apibara@localhost:27017"

    if restart:
        async with Client.connect(server_url) as client:
            existing = await client.indexer_client().get_indexer(indexer_id)
            if existing:
                await client.indexer_client().delete_indexer(indexer_id)

            # Delete old database entries.
            # Notice that apibara maps indexer ids to database names by
            # doing `indexer_id.replace('-', '_')`.
            # In the future all data will be handled by Apibara and this step
            # will not be necessary.
            mongo = MongoClient(mongo_url)
            mongo.drop_database(indexer_id.replace("-", "_"))

    runner = IndexerRunner(
        config=IndexerRunnerConfiguration(
            apibara_url=server_url,
            storage_url=mongo_url,
        ),
        network_name="starknet-goerli",
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
                name="Transfer",
                address="0x0266b1276d23ffb53d99da3f01be7e29fa024dd33cd7f7b1eb7a46c67891c9d0",
            )
        ],
        index_from_block=201_000,
    )

    print("Initialization completed. Entering main loop.")

    await runner.run()
