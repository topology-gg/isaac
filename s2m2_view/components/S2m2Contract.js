import {
    useContract
} from '@starknet-react/core'

import S2m2Abi from '../abi/s2m2_abi.json'
const S2M2_ADDR = '0x039d38747fb62279cb5266261b01dce9bf369b53fe422e89fcb8153891e301f9'

export function useS2m2Contract () {
    return useContract ({ abi: S2m2Abi, address: S2M2_ADDR })
}