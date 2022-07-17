import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('s2m2')
    const state = await db
        .collection ('state')
        .find ()
        .toArray ()

    res.status(200).json({ 'state': state })
}
