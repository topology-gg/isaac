import {
    useContract
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x0066eb1b228a5aeed216c78c119f157cc9b57bbbd9d1aa8e7e7dc4537cc76a65' // universe #0

export function useUniverseContract () {
    return useContract ({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}