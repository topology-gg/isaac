import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';

import { DEVICE_COLOR_MAP } from './ConstantDeviceColors'

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


export default function GameStatsDevices() {
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
    // 1
    //
    const { data: result_1 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 1],
    })
    const value_1 = useMemo(() => {
        if (result_1 && result_1.length > 0) {
            const value = toBN(result_1[0])
            return value.toString(10)
        }
    }, [result_1])

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
    // 3
    //
    const { data: result_3 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 3],
    })
    const value_3 = useMemo(() => {
        if (result_3 && result_3.length > 0) {
            const value = toBN(result_3[0])
            return value.toString(10)
        }
    }, [result_3])

    //
    // 4
    //
    const { data: result_4 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 4],
    })
    const value_4 = useMemo(() => {
        if (result_4 && result_4.length > 0) {
            const value = toBN(result_4[0])
            return value.toString(10)
        }
    }, [result_4])

    //
    // 5
    //
    const { data: result_5 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 5],
    })
    const value_5 = useMemo(() => {
        if (result_5 && result_5.length > 0) {
            const value = toBN(result_5[0])
            return value.toString(10)
        }
    }, [result_5])

    //
    // 6
    //
    const { data: result_6 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 6],
    })
    const value_6 = useMemo(() => {
        if (result_6 && result_6.length > 0) {
            const value = toBN(result_6[0])
            return value.toString(10)
        }
    }, [result_6])

    //
    // 7
    //
    const { data: result_7 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 7],
    })
    const value_7 = useMemo(() => {
        if (result_7 && result_7.length > 0) {
            const value = toBN(result_7[0])
            return value.toString(10)
        }
    }, [result_7])

    //
    // 8
    //
    const { data: result_8 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 8],
    })
    const value_8 = useMemo(() => {
        if (result_8 && result_8.length > 0) {
            const value = toBN(result_8[0])
            return value.toString(10)
        }
    }, [result_8])

    //
    // 9
    //
    const { data: result_9 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 9],
    })
    const value_9 = useMemo(() => {
        if (result_9 && result_9.length > 0) {
            const value = toBN(result_9[0])
            return value.toString(10)
        }
    }, [result_9])

    //
    // 10
    //
    const { data: result_10 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 10],
    })
    const value_10 = useMemo(() => {
        if (result_10 && result_10.length > 0) {
            const value = toBN(result_10[0])
            return value.toString(10)
        }
    }, [result_10])

    //
    // 11
    //
    const { data: result_11 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 11],
    })
    const value_11 = useMemo(() => {
        if (result_11 && result_11.length > 0) {
            const value = toBN(result_11[0])
            return value.toString(10)
        }
    }, [result_11])

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
    // 13
    //
    const { data: result_13 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 13],
    })
    const value_13 = useMemo(() => {
        if (result_13 && result_13.length > 0) {
            const value = toBN(result_13[0])
            return value.toString(10)
        }
    }, [result_13])

    //
    // 14
    //
    const { data: result_14 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 14],
    })
    const value_14 = useMemo(() => {
        if (result_14 && result_14.length > 0) {
            const value = toBN(result_14[0])
            return value.toString(10)
        }
    }, [result_14])

    //
    // 15
    //
    const { data: result_15 } = useStarknetCall({
        contract: contract, method: 'device_undeployed_ledger_read', args: [account, 15],
    })
    const value_15 = useMemo(() => {
        if (result_15 && result_15.length > 0) {
            const value = toBN(result_15[0])
            return value.toString(10)
        }
    }, [result_15])

    const arr_values = [
        value_0, value_1, value_2, value_3, value_4,
        value_5, value_6, value_7, value_8, value_9,
        value_10, value_11, value_12, value_13, value_14, value_15
    ]
    const arr_types = [
        "SPG", "NPG",
        "FE HARV", "AL HARV", "CU HARV", "SI HARV", "PU HARV",
        "FE REFN", "AL REFN", "CU REFN", "SI REFN", "PEF",
        "UTB", "UTL", "UPSF", "NDPE"
    ]
    const arr_footprints = [
        "1 x 1", "3 x 3",
        "1 x 1", "1 x 1", "1 x 1", "1 x 1", "1 x 1",
        "2 x 2", "2 x 2", "2 x 2", "2 x 2", "2 x 2",
        "1 x 1", "1 x 1",
        "5 x 5", "5 x 5"
    ]

    var rows = [];
    for (var row_idx = 0; row_idx < 16; row_idx ++){
        var cell = []
        const device_color = DEVICE_COLOR_MAP.get(row_idx)
        // cell.push (<td> <p style={{ color: device_color, fontSize:'1.6em'}}>■</p> </td>)
        cell.push (<td><div style={{height:"1em",width:"1em",backgroundColor:device_color,margin:"auto"}}></div></td>)
        cell.push (<td>{arr_types[row_idx]}</td>)
        cell.push (<td>{arr_footprints[row_idx]}</td>)
        cell.push (<td>{arr_values[row_idx]}</td>)

        rows.push(<tr>{cell}</tr>)
    }

    //
    // Return component
    //
    return(
        <div>
            <h5>Amount of your undeployed devices</h5>

            <table>
                <thead>
                    <tr>
                        <th>Legend</th>
                        <th>Type</th>
                        <th>Footprint</th>
                        <th>Amount</th>
                    </tr>
                </thead>
                <tbody>
                    {rows}
                    {/* <tr>
                        <td>■</td>
                        <td>SPG</td>
                        <td>{value_0}</td>
                    </tr>

                    <tr>
                        <td>1</td>
                        <td>NPG</td>
                        <td>{value_1}</td>
                    </tr>

                    <tr>
                        <td>2</td>
                        <td>FE HARV</td>
                        <td>{value_2}</td>
                    </tr>

                    <tr>
                        <td>3</td>
                        <td>AL HARV</td>
                        <td>{value_3}</td>
                    </tr>

                    <tr>
                        <td>4</td>
                        <td>CU HARV</td>
                        <td>{value_4}</td>
                    </tr>

                    <tr>
                        <td>5</td>
                        <td>SI HARV</td>
                        <td>{value_5}</td>
                    </tr>

                    <tr>
                        <td>6</td>
                        <td>PU HARV</td>
                        <td>{value_6}</td>
                    </tr>

                    <tr>
                        <td>7</td>
                        <td>FE REFN</td>
                        <td>{value_7}</td>
                    </tr>

                    <tr>
                        <td>8</td>
                        <td>AL REFN</td>
                        <td>{value_8}</td>
                    </tr>

                    <tr>
                        <td>9</td>
                        <td>CU REFN</td>
                        <td>{value_9}</td>
                    </tr>

                    <tr>
                        <td>10</td>
                        <td>SI REFN</td>
                        <td>{value_10}</td>
                    </tr>

                    <tr>
                        <td>11</td>
                        <td>PEF</td>
                        <td>{value_11}</td>
                    </tr>

                    <tr>
                        <td>12</td>
                        <td>UTB</td>
                        <td>{value_12}</td>
                    </tr>

                    <tr>
                        <td>13</td>
                        <td>UTL</td>
                        <td>{value_13}</td>
                    </tr>

                    <tr>
                        <td>14</td>
                        <td>UPSF</td>
                        <td>{value_14}</td>
                    </tr>

                    <tr>
                        <td>15</td>
                        <td>NDPE</td>
                        <td>{value_15}</td>
                    </tr> */}

                </tbody>
            </table>

        </div>
    );
}
