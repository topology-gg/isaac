import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const lobby_queue = await db
        .collection ('lobby_queue')
        .find ({
            'expired': 0,
            '_chain.valid_to' : null
        })
        .sort ({ 'queue_idx': 1 })
        .toArray ()

    res.status(200).json({ 'lobby_queue': lobby_queue })
}
