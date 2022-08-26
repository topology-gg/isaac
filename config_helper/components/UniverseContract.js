import {
    useContract
} from '@starknet-react/core'
import { isaac_addresses } from './Addresses'

import UniverseAbi from '../abi/universe_abi.json'

export function useUniverseContract () {
    return useContract ({ abi: UniverseAbi, address: isaac_addresses.universe })
}