# Isaac Backend

## Getting Started

### Install dependencies

Ensure that you have `python`, `pip`, and `poetry` installed.
For local development, also install `docker` and `docker-compose`.

### Start the Apibara server

Start the Apibara server and MongoDB database.

```sh
docker-compose up
```

Check everything was started correctly by, for example, listing the registered
indexers. We expect this output to be empty.

```sh
apibara indexer list
```

### Start the indexer

Start the indexer by running the following command:

```sh
poetry run isaac start
```

After the indexer started, you can find it in the list of registered indexers.

```sh
apibara indexer list
```

Notice that you can stop the indexer at any time and restart it later, the
indexer will automatically start indexing from where it left off.

You can restart indexing from scratch by passing the `--restart` flag.

```sh
poetry run isaac start --restart
```

You can check that the indexer is storing data by connecting directly to the
Mongo database. Use [MongoDB Compass](https://www.mongodb.com/products/compass) to
connect, specifying `mongo://isaac:isaac@localhost:27017` as the connection url.
