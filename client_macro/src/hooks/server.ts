import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import CounterAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: CounterAbi as Abi,
    address: '0x04d36339f154419982289e28c8653f4a6c3f6009df387e3baa298b84b2de016b',
  })
}
