import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const impulses = await db
        .collection('u0' + '_impulses')
        .find({'_chain.valid_to' : null})
        .sort({ 'block_number': -1 })
        .toArray()

    res.status(200).json({ 'impulses': impulses })
}