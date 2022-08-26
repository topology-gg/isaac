import {
    useContract
} from '@starknet-react/core'
import { isaac_addresses } from './Addresses'

import abi from '../abi/dao_abi.json'
const address = isaac_addresses.dao

export function useDAOContract () {
    return useContract ({ abi: abi, address: address })
}