import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import ServerAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x07f06feaa05a72ea4b5dcac5f6e959660400bc04c35ac1a6279a5d8e321b6c7c',
  })
}