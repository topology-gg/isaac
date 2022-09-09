import {
    useContract
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x0666e03798f67a4579e6a211a9eb1b11d58e159fd11adbe275d600a08506c1b8' // Proxy for Universe #0

export function useUniverseContract () {
    return useContract ({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}