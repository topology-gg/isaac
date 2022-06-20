import React, { Component, useState, useEffect, useRef, useMemo } from "react";
import { fabric } from 'fabric';

import {
    useStarknet,
    useContract,
    useStarknetCall,
    useStarknetInvoke
} from '@starknet-react/core'
import { toBN } from 'starknet/dist/utils/number'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x0758e8e3153a61474376838aeae42084dae0ef55e0206b19b2a85e039d1ef180' // universe #0
function useUniverseContract() {
    return useContract({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}


// Copied from Isaac's `constants.cairo`:
// namespace ns_device_types:
//     const DEVICE_SPG = 0 # solar power generator
//     const DEVICE_NPG = 1 # nuclear power generator
//     const DEVICE_FE_HARV = 2 # iron harvester
//     const DEVICE_AL_HARV = 3 # aluminum harvester
//     const DEVICE_CU_HARV = 4 # copper harvester
//     const DEVICE_SI_HARV = 5 # silicon harvester
//     const DEVICE_PU_HARV = 6 # plutoniium harvester
//     const DEVICE_FE_REFN = 7 # iron refinery
//     const DEVICE_AL_REFN = 8 # aluminum refinery
//     const DEVICE_CU_REFN = 9 # copper refinery
//     const DEVICE_SI_REFN = 10 # silicon refinery
//     const DEVICE_PEF = 11 # plutonium enrichment facility
//     const DEVICE_UTB = 12 # universal transportation belt
//     const DEVICE_UTL = 13 # universal transmission line
//     const DEVICE_UPSF = 14 # universal production and storage facility
//     const DEVICE_NDPE = 15 # nuclear driller & propulsion engine

//     const DEVICE_TYPE_COUNT = 16
//     const DEVICE_PG_MAX = 1
//     const DEVICE_HARVESTER_MIN = 2
//     const DEVICE_HARVESTER_MAX = 6
//     const DEVICE_TRANSFORMER_MIN = 7
//     const DEVICE_TRANSFORMER_MAX = 11
// end

export default function GameStats() {
    const { contract } = useUniverseContract()
    const { account } = useStarknet()

    //
    // 0
    //
    const { data: result_0 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 0],
    })
    const value_0 = useMemo(() => {
        if (result_0 && result_0.length > 0) {
            const value = toBN(result_0[0])
            return value.toString(10)
        }
    }, [result_0])

    //
    // 2
    //
    const { data: result_2 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 2],
    })
    const value_2 = useMemo(() => {
        if (result_2 && result_2.length > 0) {
            const value = toBN(result_2[0])
            return value.toString(10)
        }
    }, [result_2])

    //
    // 12
    //
    const { data: result_12 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 12],
    })
    const value_12 = useMemo(() => {
        if (result_12 && result_12.length > 0) {
            const value = toBN(result_12[0])
            return value.toString(10)
        }
    }, [result_12])

    //
    // Return component
    //
    return(
        <div>
            <h3>Amount of undeployed devices</h3>
            <div>SPG:     {value_0}</div>
            <div>FE_HARV: {value_2}</div>
            <div>UTB:     {value_12}</div>
        </div>
    );
}
