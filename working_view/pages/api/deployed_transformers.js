import { MongoClient } from 'mongodb'

const UNIVERSE = 'universe0'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const deployed_transformers = await db
        .collection('universe0' + '_deployed_transformers')
        .find()
        .toArray()

    res.status(200).json({ 'deployed_transformers': deployed_transformers })
}
