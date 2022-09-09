
import clientPromise from "../../../lib/mongodb"

export default async function handler(req, res) {

    const client = await clientPromise
    const { account } = req.query

    const db = client.db('stardisc')
    const stardisc_query = await db
        .collection('registry')
        .find({
            '_chain.valid_to' : null,
            'addr' : account
        })
        .toArray()

    res.status(200).json({ 'stardisc_query': stardisc_query })
}
