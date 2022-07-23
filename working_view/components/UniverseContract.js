import {
    useContract
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x05538cf7d703fa3dccb61329d23598a6b31748c120c6fff0b7c48da2396ba104' // universe #0

export function useUniverseContract () {
    return useContract ({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}