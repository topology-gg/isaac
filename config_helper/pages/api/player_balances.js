import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac_alpha')
    const player_balances = await db
        .collection('u0' + '_player_balances')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'player_balances': player_balances })
}
