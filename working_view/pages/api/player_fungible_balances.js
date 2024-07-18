
import clientPromise from "../../lib/mongodb"
import { DB_NAME } from "./db_name"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db(DB_NAME)

    const player_fungible_balances = await db
        .collection('u0' + '_player_fungible_balances')
        .find({'_chain.valid_to': null})
        .toArray()

    res.status(200).json({ 'player_fungible_balances': player_fungible_balances })
}
