import logging
import os

from apibara.indexer import IndexerRunner, IndexerRunnerConfiguration, Info
from apibara.indexer.indexer import IndexerConfiguration
from apibara.protocol.proto.stream_pb2 import DataFinality
from apibara.starknet import Cursor, EventFilter, Filter, StarkNetIndexer, felt
from apibara.starknet.cursor import starknet_cursor
from apibara.starknet.proto.starknet_pb2 import Block, Event

from indexer.contract import decode_sns_register_occurred

# Print apibara logs
root_logger = logging.getLogger("apibara")
# change to `logging.DEBUG` to print more information
root_logger.setLevel(logging.INFO)
root_logger.addHandler(logging.StreamHandler())

STARDISC_ADDR = felt.from_hex(
    "0x0367846f4e87762424244c9891a5db6c242b270632ff2d82bfe1ed0907dfddf5"
)
REGISTER_KEY = felt.from_hex(
    "0x308010ef09193321250bb6821657039f1a7b72c4d2524a4115858c17877ecdd"
)
BIRTH_BLOCK = 307_806  # deploy tx hash: 0x84f9a339eb3f94d30bd5e333e241721f22366ba999687a205ae9dd26a61936


class StardiscIndexer(StarkNetIndexer):
    def __init__(self, id: str):
        self._indexer_id = id
        super().__init__()

    def indexer_id(self) -> str:
        return self._indexer_id

    def initial_configuration(self) -> Filter:
        # Return initial configuration of the indexer.
        return IndexerConfiguration(
            filter=Filter().add_event(
                EventFilter().with_from_address(STARDISC_ADDR).with_keys([REGISTER_KEY])
            ),
            starting_cursor=starknet_cursor(BIRTH_BLOCK),
            finality=DataFinality.DATA_STATUS_ACCEPTED,
        )

    async def handle_data(self, info: Info, data: Block):
        # Handle one block of data
        if not data.events:
            return

        for e in data.events:
            await self.handle_sns_register_occurred(info, e.event)

    async def handle_sns_register_occurred(self, info: Info, event: Event):
        addr, name = decode_sns_register_occurred(event)
        await info.storage.find_one_and_replace(
            collection="registry",
            filter={"addr": str(addr)},
            replacement={"addr": str(addr), "name": str(name)},
            upsert=True,
        )

    async def handle_invalidate(self, _info: Info, _cursor: Cursor):
        raise ValueError("data must be finalized")


async def run_indexer(server_url=None, mongo_url=None, restart=None):
    print("Starting Apibara indexer")

    runner = IndexerRunner(
        config=IndexerRunnerConfiguration(
            stream_url=server_url,
            storage_url=mongo_url,
        ),
        reset_state=restart,
    )

    indexer_id = os.getenv("INDEXER_ID", "stardisc")
    await runner.run(StardiscIndexer(indexer_id), ctx={"network": "starknet-testnet"})
