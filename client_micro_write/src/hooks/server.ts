import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import ServerAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x02a3f6c3ddf2be709ac34dfe6357f7f7bd8a462ecd16e46a15b2ee766ca6198c',
  })
}