import {
    useContract
} from '@starknet-react/core'

import LobbyAbi from '../abi/lobby_abi.json'
const LOBBY_ADDR = '0x0115af969a87fe850819348ed5d1c88f7306b0c3faa1997ada23749e4b0b2b5c' // Proxy for Lobby

export function useLobbyContract () {
    return useContract ({ abi: LobbyAbi, address: LOBBY_ADDR })
}