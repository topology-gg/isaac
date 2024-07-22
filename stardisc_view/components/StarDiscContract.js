import {
    useContract
} from '@starknet-react/core'

import StarDiscAbi from '../abi/stardisc_abi.json'
const STARDISC_ADDR = '0x0367846f4e87762424244c9891a5db6c242b270632ff2d82bfe1ed0907dfddf5'

export function useStarDiscContract () {
    return useContract ({ abi: StarDiscAbi, address: STARDISC_ADDR })
}
