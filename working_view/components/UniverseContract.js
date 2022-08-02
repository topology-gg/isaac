import {
    useContract
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x00e6f67691f16f96f7e72119dca05967f3efe55e778b1a144214a5715986dd35' // universe #0

export function useUniverseContract () {
    return useContract ({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}