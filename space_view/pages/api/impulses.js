import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {
    const client = await clientPromise

    const db = client.db('isaac')
    const impulses = await db
        .collection('u0' + '_impulses')
        .find({'_chain.valid_to' : null})
        .sort({ 'block_number': -1 })
        .toArray()

    res.status(200).json({ 'impulses': impulses })
}