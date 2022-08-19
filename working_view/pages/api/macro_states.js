
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_dfbc16')
    // const db = client.db('isaac_10ce37b')
    const macro_states = await db
        .collection('u0_macro_states')
        .find({'_chain.valid_to' : null})
        .project({ 'phi': 1, 'dynamics': 1, 'block_number': 1 })
        .sort({ 'block_number': -1 })
        .toArray()

    res.status(200).json({ 'macro_states': macro_states })
}