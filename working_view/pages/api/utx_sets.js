import { MongoClient } from 'mongodb'

const UNIVERSE = 'universe0'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac')
    const utx_sets = await db
        .collection('u0' + '_utx_sets')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'utx_sets': utx_sets })
}
