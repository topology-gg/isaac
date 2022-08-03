
import clientPromise from "../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db('isaac')
    const deployed_devices = await db
        .collection('u0' + '_deployed_devices')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'deployed_devices': deployed_devices })
}
