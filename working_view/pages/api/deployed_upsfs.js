
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac')
    const deployed_upsfs = await db
        .collection('u0' + '_deployed_upsfs')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'deployed_upsfs': deployed_upsfs })
}