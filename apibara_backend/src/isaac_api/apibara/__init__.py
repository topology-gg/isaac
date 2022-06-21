from contextlib import asynccontextmanager
from dataclasses import dataclass
from datetime import datetime
from typing import List, Optional

from aiochannel import Channel
import grpc

import isaac_api.apibara.generated.apibara.application.application_service_pb2 as application_service_pb2
import isaac_api.apibara.generated.apibara.application.application_service_pb2_grpc as application_service_pb2_grpc


@dataclass
class Application:
    id: str
    index_from_block: int
    indexed_to_block: int

    @staticmethod
    def from_proto(p: application_service_pb2.Application):
        return Application(p.id, p.index_from_block, p.indexed_to_block)


@dataclass
class ApplicationConnected:
    application: Application

    @staticmethod
    def from_proto(p: application_service_pb2.ApplicationConnected):
        app = Application.from_proto(p.application)
        return ApplicationConnected(app)


@dataclass
class BlockHeader:
    hash: bytes
    parent_hash: Optional[bytes]
    number: int
    timestamp: datetime

    @staticmethod
    def from_proto(p: application_service_pb2.BlockHeader):
        dt = datetime.fromtimestamp(p.timestamp.seconds)
        return BlockHeader(bytes(p.hash), bytes(p.parent_hash), p.number, dt)

    def __str__(self) -> str:
        return f"BlockHeader(hash=0x{self.hash.hex()}, parent_hash=0x{self.parent_hash.hex()}, number={self.number}, timestamp={self.timestamp})"


@dataclass
class Event:
    address: bytes
    block_index: int
    topics: List[bytes]
    data: List[bytes]

    @staticmethod
    def from_proto(p: application_service_pb2.Event):
        topics = [bytes(t.value) for t in p.topics]
        data = [bytes(d.value) for d in p.data]
        return Event(bytes(p.address), p.block_index, topics, data)

    def __str__(self) -> str:
        return f"Event(address=0x{self.address.hex()}, block_index={self.block_index}, ...{len(self.topics)} topics, ...{len(self.data)} data)"


@dataclass
class NewBlock:
    new_head: BlockHeader

    @staticmethod
    def from_proto(p: application_service_pb2.NewBlock):
        new_head = BlockHeader.from_proto(p.new_head)
        return NewBlock(new_head)

    def __str__(self) -> str:
        return f"NewBlock(new_head={self.new_head})"


@dataclass
class Reorg:
    new_head: BlockHeader

    @staticmethod
    def from_proto(p: application_service_pb2.Reorg):
        new_head = BlockHeader.from_proto(p.new_head)
        return Reorg(new_head)

    def __str__(self) -> str:
        return f"Reorg(new_head={self.new_head})"


@dataclass
class NewEvents:
    block_hash: bytes
    block_number: int
    events: List[Event]

    @staticmethod
    def from_proto(p: application_service_pb2.NewEvents):
        events = [Event.from_proto(ev) for ev in p.events]
        return NewEvents(bytes(p.block_hash), p.block_number, events)

    def __str__(self) -> str:
        return f"NewEvents(block_hash=0x{self.block_hash.hex()}, block_number={self.block_number}, ...{len(self.events)} events)"


class ApplicationManager:
    @staticmethod
    @asynccontextmanager
    async def insecure_channel(url):
        async with grpc.aio.insecure_channel(url) as channel:
            yield ApplicationManager(channel)

    def __init__(self, channel) -> None:
        self._channel = channel
        self._stub = application_service_pb2_grpc.ApplicationManagerStub(self._channel)

    async def get_application(self, id):
        try:
            response = await self._stub.GetApplication(
                application_service_pb2.GetApplicationRequest(id=id)
            )
            if response and response.application:
                return Application.from_proto(response.application)
        except grpc.aio.AioRpcError as ex:
            if ex.code() == grpc.StatusCode.NOT_FOUND:
                return None
            raise

    async def create_application(self, id, index_from_block):
        response = await self._stub.CreateApplication(
            application_service_pb2.CreateApplicationRequest(
                id=id, index_from_block=index_from_block
            )
        )

        if response and response.application:
            return Application.from_proto(response.application)

    async def delete_application(self, id):
        response = await self._stub.DeleteApplication(
            application_service_pb2.DeleteApplicationRequest(id=id)
        )

        if response and response.application:
            return Application.from_proto(response.application)

    async def list_application(self):
        response = await self._stub.ListApplication(
            application_service_pb2.ListApplicationRequest()
        )

        if response and response.applications:
            return [Application.from_proto(app) for app in response.applications]

    async def connect_indexer(self):
        client = ConnectIndexerClient()
        response_iter = self._stub.ConnectIndexer(client._chan)

        return ConnectIndexerStream(response_iter), client


class ConnectIndexerClient:
    def __init__(self) -> None:
        self._chan = Channel()

    async def connect_application(self, id):
        connect = application_service_pb2.ConnectApplication(id=id)
        request = application_service_pb2.ConnectIndexerRequest(connect=connect)
        await self._chan.put(request)


class ConnectIndexerStream:
    def __init__(self, iter) -> None:
        self._iter = iter.__aiter__()

    def __aiter__(self):
        return self

    async def __anext__(self):
        response = await self._iter.__anext__()
        return self._parse_response(response)

    def _parse_response(self, response):
        if response.HasField("connected"):
            return ApplicationConnected.from_proto(response.connected)

        if response.HasField("new_block"):
            return NewBlock.from_proto(response.new_block)

        if response.HasField("reorg"):
            return Reorg.from_proto(response.reorg)

        if response.HasField("new_events"):
            return NewEvents.from_proto(response.new_events)

        raise RuntimeError(f"unknown ConnectIndexerResponse message:\n{response}")
