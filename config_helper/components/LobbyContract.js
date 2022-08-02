import {
    useContract
} from '@starknet-react/core'

import LobbyAbi from '../abi/lobby_abi.json'
const LOBBY_ADDR = '0x07ac955f749c88226c169f642934ee3c6adea0f5f11c3ba97b2c89b879c4a177'

export function useLobbyContract () {
    return useContract ({ abi: LobbyAbi, address: LOBBY_ADDR })
}