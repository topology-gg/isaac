import { MongoClient } from 'mongodb'

const UNIVERSE = 'universe0'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const civ_state = db
        .collection ('universe0' + '_civ_state')
        .find ()
        .toArray ()

        // .find ({'most_recent' : 1})
        // .project ({ 'civ_index': 1, 'active': 1, 'most_recent': 1 })

    res.status(200).json({ 'civ_state': civ_state })
}
