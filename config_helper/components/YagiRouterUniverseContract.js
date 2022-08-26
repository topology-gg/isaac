import {
    useContract
} from '@starknet-react/core'
import { yagi_router_addresses } from './Addresses'

import abi from '../abi/yagi_router_universe_abi.json'
const address = yagi_router_addresses.universe

export function useYagiRouterUniContract () {
    return useContract ({ abi: abi, address: address })
}