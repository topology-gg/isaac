import {
    useContract
} from '@starknet-react/core'

import LobbyAbi from '../abi/lobby_abi.json'
const LOBBY_ADDR = '0x0594052245d8ba04a7e9825a1ddcd995af9bd8283edbca3b3c69e40e56f12799'

export function useLobbyContract () {
    return useContract ({ abi: LobbyAbi, address: LOBBY_ADDR })
}