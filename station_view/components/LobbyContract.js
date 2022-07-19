import {
    useContract
} from '@starknet-react/core'

import LobbyAbi from '../abi/lobby_abi.json'
const LOBBY_ADDR = '0x0113b4b77eb613605e6ef0b72f684797f005d6d68ec632dc03fb7625d56787e6'

export function useLobbyContract () {
    return useContract ({ abi: LobbyAbi, address: LOBBY_ADDR })
}