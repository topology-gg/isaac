import {
    useContract
} from '@starknet-react/core'

import LobbyAbi from '../abi/lobby_abi.json'
const LOBBY_ADDR = '0x01c9125178ed782ca3fd9bea67acf1d602376cf5203450946d9dd897bddc97e4'

export function useLobbyContract () {
    return useContract ({ abi: LobbyAbi, address: LOBBY_ADDR })
}