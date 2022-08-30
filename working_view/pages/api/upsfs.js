
import clientPromise from "../../lib/mongodb"
import { DB_NAME } from "./db_name"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db(DB_NAME)

    const upsfs = await db
        .collection('u0' + '_upsfs')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'upsfs': upsfs })
}
