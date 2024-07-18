
import clientPromise from "../../../lib/mongodb"
import { DB_NAME } from "../db_name"

export default async function handler(req, res) {

    const client = await clientPromise
    const { account } = req.query

    const db = client.db(DB_NAME)

    const player_nonfungible_devices = await db
        .collection('u0' + '_player_nonfungible_devices')
        .find({
            '_chain.valid_to' : null,
            'owner' : account
    })
        .toArray()

    res.status(200).json({ 'player_nonfungible_devices': player_nonfungible_devices })
}
