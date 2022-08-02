import {
    useContract
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x0164c3f00e90457c270853248d4905e7f345eb323c49156755ffb28d65e308ee' // universe #0

export function useUniverseContract () {
    return useContract ({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}