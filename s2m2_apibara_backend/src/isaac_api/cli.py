"""Start the isaac indexer"""

import asyncio
from functools import wraps

import click

from isaac_api.apibara import ApplicationManager


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
    async with ApplicationManager.insecure_channel("localhost:7171") as app_manager:
        app = await app_manager.delete_application(application_id)
        print(app)


@cli.command()
@click.argument("application-id", type=str)
@coro
async def start(application_id):
    """Start indexing the given application"""
    async with ApplicationManager.insecure_channel("localhost:7171") as app_manager:
        app = await app_manager.get_application(application_id)
        print(app)
