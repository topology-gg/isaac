import React, { Component, useState, useEffect } from "react";
import { toBN } from 'starknet/dist/utils/number'

import {
    usePlayerFungibleBalances
} from '../lib/api'
import GameStatsPlayer from "./GameStatsPlayer";
import { CIV_SIZE } from "../lib/constants/gameWorld";

export default function GameStatsPlayers (props) {

    // const account_str_decimal = toBN(account).toString(10)
    // const { data: stardisc_query } = useStardiscRegistryByAccount (account_str_decimal) // must be a better way than fetching the entire registry
    const { data: db_player_fungible_balances } = usePlayerFungibleBalances ()

    const empty_addr_array = []
    for (var i=0; i<CIV_SIZE; i++){
        empty_addr_array.push ('0')
    }
    const [accountBns, setAccountBns] = useState(empty_addr_array)

    useEffect (() => {
        if (!db_player_fungible_balances) return;
        if (db_player_fungible_balances.player_fungible_balances.length == 0) return;

        setAccountBns ((prev) =>
            prev.map((account_bn, idx) => {
                if (account_bn !== '0') return account_bn

                const player_account = db_player_fungible_balances.player_fungible_balances.find(e => e.player_index === idx).account;

                return toBN(player_account)
            })
        )

    }, [db_player_fungible_balances])

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
                    {accountBns.map((accountBn, idx) =>
                        <tr key={`players-row-${idx}`} className="player_account">
                            <td key={`players-rowidx-${idx}`}>{idx}</td>
                            <GameStatsPlayer accountBn={accountBn} />
                        </tr>
                    )}
                </tbody>
            </table>

        </div>
    );
}
