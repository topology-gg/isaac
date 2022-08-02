import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac')
    const civ_state = await db
        .collection ('u0' + '_civ_state')
        .find ({
            '_chain.valid_to' : null,
            'most_recent' : 1
        })
        .project ({ 'civ_idx': 1, 'active': 1, 'most_recent': 1 })
        .toArray ()

    res.status(200).json({ 'civ_state': civ_state })
}
