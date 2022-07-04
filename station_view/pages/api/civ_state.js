import { MongoClient } from 'mongodb'

const UNIVERSE = 'universe0'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const latest_civ_state = await db
        .collection (UNIVERSE + '_civ_state')
        // .find_one ({'most_recent': 1})

    res.status(200).json({ 'latest_civ_state': latest_civ_state })
}
