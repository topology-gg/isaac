import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import ServerAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x31bd38f4c37a31e55a5aba3538581cbe2ba6dc7f79b35adce686b6a8ea948cd',
  })
}