import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';
import { BigNumber } from 'bignumber.js'

import {
    useStarknet,
} from '@starknet-react/core'

import { DEVICE_COLOR_MAP } from './ConstantDeviceColors'
import {
    useCivState,
    usePlayerBalances
} from '../lib/api'

export default function GameStatsDevices(props) {

    const { account } = useStarknet()
    BigNumber.config({ EXPONENTIAL_AT: 76 })
    const account_int_str = BigNumber(account).toString()
    var arr_values = []
    //
    // Data fetched from backend on Apibara
    //
    const { data: db_civ_state } = useCivState ()
    const { data: db_player_balances } = usePlayerBalances ()

    //
    // Get player balances according to signed-in account
    //
    if (db_player_balances) {
        var player_balance
        for (const entry of db_player_balances.player_balances) {
            if (account_int_str === entry['account']) {
                player_balance = entry

                for (const i=0; i<16; i++) {
                    arr_values[i] = entry [i.toString()]
                }
            }
        }
    }

    // const arr_types = [
    //     "Solar Power Generator",
    //     "Nuclear Power Generator",
    //     "Fe Harvester", "Al Harvester", "Cu Harvester", "Si Harvester", "Pu Harvester",
    //     "Fe Refinery", "Al Refinery", "Cu Refinery", "Si Refinery", "Plutonium Enricher",
    //     "Belt", "Wire", "Factory", "Engine"
    // ]


    const arr_types = {
        0:  "Solar Power Generator",
        1:  "Nuclear Power Generator",
        2:  "Iron Harvester",
        3:  "Aluminum Harvester",
        4:  "Copper Harvester",
        5:  "Silicon Harvester",
        6:  "Plutonium Harvester",
        7:  "Iron Refinery",
        8:  "Aluminum Refinery",
        9:  "Copper Refinery",
        10: "Silicon Refinery",
        11: "Plutonium Enricher",
        12: "Belt",
        13: "Wire",
        14: "Factory",
        15: "Engine"
    }
    const arr_footprints = [
        "1 x 1", "3 x 3",
        "1 x 1", "1 x 1", "1 x 1", "1 x 1", "1 x 1",
        "2 x 2", "2 x 2", "2 x 2", "2 x 2", "2 x 2",
        "1 x 1", "1 x 1",
        "5 x 5", "5 x 5"
    ]

    const indices = [
        0, 1, 2, 7, 3, 8, 4, 9, 5, 10, 6, 11, 12, 13, 14, 15
    ]

    var rows = [];
    for (var row_idx = 0; row_idx < 16; row_idx ++){
        var cell = []
        const index = indices [row_idx]

        const device_color = DEVICE_COLOR_MAP.get(index)
        cell.push (<td key={`devices-div-${row_idx}`}><div style={{height:"1em",width:"1em",backgroundColor:device_color,margin:"auto"}}></div></td>)
        cell.push (<td key={`devices-cell-1-${row_idx}`}>{arr_types[index]}</td>)
        cell.push (<td key={`devices-cell-2-${row_idx}`}>{arr_footprints[index]}</td>)
        cell.push (<td key={`devices-cell-3-${row_idx}`}>{arr_values[index]}</td>)

        rows.push(<tr key={`devices-row-${row_idx}`}>{cell}</tr>)
    }

    //
    // Return component
    //
    return(
        <div style={{visibility: props.universeActive?'visible':'hidden'}}>
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
                </tbody>

            </table>

        </div>
    );
}
