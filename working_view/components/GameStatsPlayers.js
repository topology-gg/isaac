import React, { Component, useState, useEffect } from "react";
import { toBN } from 'starknet/dist/utils/number'

import {
    usePlayerBalances
} from '../lib/api'
import GameStatsPlayer from "./GameStatsPlayer";

const CIV_SIZE = 5

export default function GameStatsPlayers(props) {

    const { data: db_player_balances } = usePlayerBalances ()

    const empty_addr_array = []
    const empty_result_array = []
    for (var i=0; i<CIV_SIZE; i++){
        empty_addr_array.push ('0')
        empty_result_array.push (null)
    }
    const [accountStringsState, setAccountStringsState] = useState(empty_addr_array)

    useEffect (() => {
        if (!db_player_balances) return;
        if (!db_player_balances.player_balances) return;

        setAccountStringsState ((prev) =>
            prev.map((account_str, idx) => {
                if (account_str !== '0') return account_str

                const player_account = db_player_balances.player_balances.find(e => e.player_index === idx).account;

                return toBN(player_account).toString(16)
            })
        )

    }, [db_player_balances])

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
                    {accountStringsState.map((accountString, idx) =>
                        <tr key={`players-row-${idx}`} className="player_account">
                            <td key={`players-rowidx-${idx}`}>{idx}</td>
                            <GameStatsPlayer accountString={accountString} />
                        </tr>
                    )}
                </tbody>
            </table>

        </div>
    );
}
