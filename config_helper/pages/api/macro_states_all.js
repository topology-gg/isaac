
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_10ce37b')
    // const db = client.db('isaac') // old db for debug

    const macro_states_all = await db
        .collection('u0' + '_macro_states')
        .find ()
        .project({ 'phi': 1, 'dynamics': 1, 'block_number': 1 })
        .sort({ 'block_number': +1 })
        .toArray()

    return res.status(200).json({ 'macro_states_all': macro_states_all })
}