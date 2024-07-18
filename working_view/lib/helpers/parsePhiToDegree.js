import { BigNumber } from 'bignumber.js'

//
// Helper function to convert api-returned phi value into degree
//
export default function parse_phi_to_degree (phi)
{
    const phi_bn = new BigNumber(Buffer.from(phi, 'base64').toString('hex'), 16)
    const phi_degree = (phi_bn / 10**20) / (Math.PI * 2) * 360

    return phi_degree
}
