import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import CounterAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: CounterAbi as Abi,
    address: '0x05d5ee760639052254c2b94c7eb6d8c859ea16cdbc57063be52a872340920ef5',
  })
}
