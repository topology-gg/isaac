
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_dfbc16')
    // const db = client.db('isaac_10ce37b')
    const deployed_transformers = await db
        .collection('u0' + '_deployed_transformers')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'deployed_transformers': deployed_transformers })
}
