import {
    useContract
} from '@starknet-react/core'
import { isaac_proxy_addresses } from './Addresses'

import abi from '../abi/lobby_abi.json'
const address = isaac_proxy_addresses.lobby

export function useLobbyContract () {
    return useContract ({ abi: abi, address: address })
}