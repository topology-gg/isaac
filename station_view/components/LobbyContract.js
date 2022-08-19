import {
    useContract
} from '@starknet-react/core'

import LobbyAbi from '../abi/lobby_abi.json'
const LOBBY_ADDR = '0x06ea0fc5dcf98f2cb9f4b97fc355cd1f92e0ee83fde75c0f6117602a54cf6bda'

export function useLobbyContract () {
    return useContract ({ abi: LobbyAbi, address: LOBBY_ADDR })
}