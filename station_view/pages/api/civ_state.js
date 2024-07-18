
import clientPromise from "../../lib/mongodb"
import { DB_NAME } from "./db_name"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db(DB_NAME)
    // const db = client.db('isaac_10ce37b') // old db for last closed alpha
    // const db = client.db('isaac') // old db for debug
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
