
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('stardisc')
    const stardisc_registry = await db
        .collection('registry')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'stardisc_registry': stardisc_registry })
}
