import {
    useContract
} from '@starknet-react/core'

import S2m2Abi from '../abi/s2m2_abi.json'
const S2M2_ADDR = '0x02369dbd0ec5e3e152aef28d10042abdf7a22a316c667e2a880bd4c0978e448b'

export function useS2m2Contract () {
    return useContract ({ abi: S2m2Abi, address: S2M2_ADDR })
}