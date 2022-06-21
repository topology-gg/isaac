from contextlib import asynccontextmanager
from dataclasses import dataclass

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
