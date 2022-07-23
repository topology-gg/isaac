import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const civ_states = await db
        .collection ('u0' + '_civ_state')
        .find ({'_chain.valid_to' : null})
        .sort({ 'civ_idx': -1 })
        .toArray ()

    res.status(200).json({ 'civ_states': civ_states })
}
