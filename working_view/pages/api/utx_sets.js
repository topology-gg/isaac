
import clientPromise from "../../lib/mongodb"
import { DB_NAME } from "./db_name"

export default async function handler(req, res) {

    const client = await clientPromise

    const db = client.db(DB_NAME)

    const utx_sets = await db
        .collection('u0' + '_deployed_utx_sets')
        .find({'_chain.valid_to' : null})
        .toArray()

    res.status(200).json({ 'utx_sets': utx_sets })
}
