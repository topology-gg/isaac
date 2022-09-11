import {
    useContract
} from '@starknet-react/core'
import { isaac_proxy_addresses } from './Addresses'

import abi from '../abi/fsm_abi.json'

export function useFsmAngelContract () {
    return useContract ({ abi: abi, address: isaac_proxy_addresses.fsm_angel })
}