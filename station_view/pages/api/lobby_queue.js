
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_10ce37b')
    // const db = client.db('isaac') // old db for debug
    const lobby_queue = await db
        .collection ('lobby_queue')
        .find ({
            'expired': 0,
            '_chain.valid_to' : null
        })
        .sort ({ 'queue_idx': 1 })
        .toArray ()

    res.status(200).json({ 'lobby_queue': lobby_queue })
}
