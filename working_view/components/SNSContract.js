import {
    useContract
} from '@starknet-react/core'

import SNSAbi from '../abi/sns_abi.json'
const SNS_ADDR = '0x07662924e56ddcf0de40ba7a5b75fa0dbbe2212e448e7c5e42d362316ee39c87'

export function useSNSContract () {
    return useContract ({ abi: SNSAbi, address: SNS_ADDR })
}