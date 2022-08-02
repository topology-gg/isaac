import { MongoClient } from 'mongodb'

const MONGO_CONNECTION_STRING = process.env.MONGO_CONNECTION_STRING

const client = new MongoClient(MONGO_CONNECTION_STRING)

export default async function handler(req, res) {
    await client.connect()

    const db = client.db('isaac')

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