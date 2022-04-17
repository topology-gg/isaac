import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import ServerAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x06a98d9f4b77dd225569065f7c0eea2b93eff6dcc35b2780ca9613425cbbe62a',
  })
}