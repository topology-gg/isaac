import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import ServerAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x00009d9fb113a6f2398eb417825b803354ced11067ff277df5077b1ab7b047b7',
  })
}