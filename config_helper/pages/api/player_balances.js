
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac')
    const player_balances = await db
        .collection('u0' + '_player_balances')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'player_balances': player_balances })
}
