import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useStarknet,
} from '@starknet-react/core'

import {
    useCivState,
    usePlayerBalances
} from '../lib/api'

export default function GameStatsPlayers(props) {

    const { account } = useStarknet()
    const { data: db_civ_state } = useCivState ()
    const { data: db_player_balances } = usePlayerBalances ()
    var rows = [];
    // console.log (db_player_balances)

    if (db_player_balances) {

        // console.log('GameStatsPlayers:', db_player_balances)
        const population = db_player_balances.player_balances.length
        for (var row_idx = 0; row_idx < population; row_idx ++){
            const account_str = toBN(db_player_balances.player_balances[row_idx]['account']).toString(16)
            const account_str_abbrev = "0x" + account_str.slice(0,3) + "..." + account_str.slice(-4)

            var cell = []
            cell.push (<td>{row_idx}</td>)

            if (!account) {
                cell.push (<td>{account_str_abbrev}</td>)
            }
            else {
                // check if signed-in account matches current row
                const signed_in_account_str = toBN(account).toString(16)
                // console.log (`account_str: ${account_str}; signed_in_account_str: ${signed_in_account_str}`)
                if (account_str === signed_in_account_str) {
                    cell.push (<td style={{color:'#00CCFF'}}>{account_str_abbrev}</td>)
                }
                else {
                    cell.push (<td>{account_str_abbrev}</td>)
                }
            }

            rows.push(<tr className="player_account">{cell}</tr>)
        }
    }

    //
    // Return component
    //
    return(
        <div style={{visibility: props.universeActive?'visible':'hidden'}}>
            <h5>Player accounts in this universe</h5>

            <table>
                <thead>
                    <tr>
                        <th>Index</th>
                        <th>Address</th>
                    </tr>
                </thead>
                <tbody>
                    {rows}
                </tbody>
            </table>

        </div>
    );
}
