
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_10ce37b')
    // const db = client.db('isaac') // old db for debug
    const civ_states = await db
        .collection ('u0' + '_civ_state')
        .find ({'_chain.valid_to' : null})
        .sort({ 'civ_idx': -1 })
        .toArray ()

    res.status(200).json({ 'civ_states': civ_states })
}
