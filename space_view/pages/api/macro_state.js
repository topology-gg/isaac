import { MongoClient } from 'mongodb'

const UNIVERSE = 'universe0'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const macro_states = await db
        .collection(UNIVERSE + '_macro_states')
        .find()
        .project({ 'phi': 1, 'dynamics': 1, 'block_number': 1 })
        .sort({ 'block_number': -1 })
        .limit(100)
        .toArray()

    res.status(200).json({ 'macro_states': macro_states })
}