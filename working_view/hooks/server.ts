import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import CounterAbi from '../abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: CounterAbi as Abi,
    address: '0x0717a903232a851dec3158e723750fc8a50a03afbdf7ad92f89558602c163a27',
  })
}
