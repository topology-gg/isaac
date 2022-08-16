import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useStarknet,
    useStarknetCall
} from '@starknet-react/core'

import { useSNSContract } from "./SNSContract";

import {
    useCivState,
    usePlayerBalances
} from '../lib/api'

const CIV_SIZE = 5

export default function GameStatsPlayers(props) {

    const { account } = useStarknet()
    const { contract: snsContract } = useSNSContract ()
    const { data: db_civ_state } = useCivState ()
    const { data: db_player_balances } = usePlayerBalances ()
    var rows = [];
    // console.log (db_player_balances)

    // make the starknet calls
    const [loadedPlayerAddresses, setLoadedPlayerAddresses] = useState([])

    useEffect(() => {
        const { data : result, loading, error, refresh} = useStarknetCall ({
            contract: snsContract,
            method: 'sns_lookup_adr_to_name',
            args: [account_str]
        })
    }, [loadedPlayerAddresses])

    if (db_player_balances) {

        // console.log('GameStatsPlayers:', db_player_balances)
        // const population = db_player_balances.player_balances.length

        for (var row_idx = 0; row_idx < CIV_SIZE; row_idx ++){
            const account_str = toBN(db_player_balances.player_balances[row_idx]['account']).toString(16)
            setLoadedPlayerAddresses( loadedPlayerAddresses.concat([account_str]) )
            const account_str_abbrev = "0x" + account_str.slice(0,3) + "..." + account_str.slice(-4)

            //const [exist, name_string] = parse_call_result (...)
            const display_account_str = exist == 0 ? account_str_abbrev : name_string

            var cell = []
            cell.push (<td key={`players-rowidx-${row_idx}`}>{row_idx}</td>)

            if (!account) {
                cell.push (<td key={'players-not-account'}>{display_account_str}</td>)
            }
            else {
                // check if signed-in account matches current row
                const signed_in_account_str = toBN(account).toString(16)
                // console.log (`account_str: ${account_str}; signed_in_account_str: ${signed_in_account_str}`)
                if (account_str === signed_in_account_str) {
                    cell.push (<td key={'players-account-signedin'} style={{color:'#00CCFF'}}>{display_account_str}</td>)
                }
                else {
                    cell.push (<td key={'players-account-not-signedin'}>{display_account_str}</td>)
                }
            }

            rows.push(<tr key={`players-row-${row_idx}`} className="player_account">{cell}</tr>)
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

function parse_call_result (result) {

    if (result && result.length > 0) {
        const exist = toBN(result.exist).toString(10)
        const name = toBN(result.name).toString(10)
        const name_string = felt_literal_to_string (name)

        console.log ('exist:', exist)
        console.log ('name:', name_string)
        return [exist, name_string]
    }

}