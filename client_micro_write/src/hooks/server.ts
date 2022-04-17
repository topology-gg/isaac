import { useContract } from '@starknet-react/core'
import { Abi } from 'starknet'

import ServerAbi from '~/abi/server_abi.json'

export function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x0025ecf8ef3993263fec37a54dd730c5d10fa347d1427c584de0a48ec292b4b4',
  })
}