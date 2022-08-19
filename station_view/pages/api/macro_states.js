
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_dfbc16')
    // const db = client.db('isaac_10ce37b')
    // const db = client.db('isaac') // old db for debug

    // TODO: query the birth block_number of this civ, and use that to filter macro_states.
    //       because documents are immutable, we need to differentiate states of current civ from states of past civs

    // const latest_civ_states = await db
    //     .collection ('u0_civ_state')
    //     .find ({
    //         'most_recent' : 1,
    //         '_chain.valid_to' : null
    //     })
    //     .toArray()

    // if (latest_civ_states.length == 0) {
    //     return res.status(200).json({ 'macro_states': [] })
    // }
    // else if (latest_civ_states[0].active == 0) {
    //     return res.status(200).json({ 'macro_states': [] })
    // }

    // const civ_birth_block_number = latest_civ_states[0].birth_block_number

    const macro_states = await db
        .collection('u0' + '_macro_states')
        // .find({ 'block_number': { '$gte': civ_birth_block_number } })
        .find ({'_chain.valid_to' : null})
        .project({ 'phi': 1, 'dynamics': 1, 'block_number': 1 })
        .sort({ 'block_number': -1 })
        .toArray()

    return res.status(200).json({ 'macro_states': macro_states })
}