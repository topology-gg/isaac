
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac_10ce37b')
    const deployed_ndpes = await db
        .collection('u0' + '_deployed_ndpes')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'deployed_ndpes': deployed_ndpes })
}
