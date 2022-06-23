import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
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

export default function GameStatsPlayers() {
    const { contract } = useUniverseContract()
    const { account } = useStarknet()

    //
    // 0
    //
    const { data: result_0 } = useStarknetCall({
        contract: contract, method: 'civilization_player_idx_to_address_read', args: [0],
    })
    const value_0 = useMemo(() => {
        if (result_0 && result_0.length > 0) {
            const value = toBN(result_0[0])
            const value_string = value.toString(16)
            return "0x" + value_string.slice(0,3) + "..." + value_string.slice(-4)
        }
    }, [result_0])

    //
    // Return component
    //
    return(
        <div>
            <h4>Player accounts in this universe</h4>

            <table>
                <thead>
                    <tr>
                        <th>Player index</th>
                        <th>Player account</th>
                    </tr>
                </thead>
                <tbody>
                    <tr>
                        <td>0</td>
                        <td>{value_0}</td>
                    </tr>
                </tbody>
            </table>

        </div>
    );
}
