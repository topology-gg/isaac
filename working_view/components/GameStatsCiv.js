import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useCivState,
    useMacroStates,
    usePlayerFungibleBalances
} from '../lib/api'

export default function GameStatsCiv() {

    var content = []
    const { data: db_civ_state } = useCivState ()
    const { data: db_macro_states } = useMacroStates ()
    const { data: db_player_fungible_balances } = usePlayerFungibleBalances ()

    if (!db_civ_state || !db_macro_states || !db_player_fungible_balances) {
        content = []
    }
    else {
        if (db_macro_states.macro_states.length == 0) {
            content.push (<p key='stats-p-inactive'>{'** universe inactive **'}</p>)
        }
        else {
            // console.log ('got db_civ_state:', db_civ_state.civ_state[0])
            const civ_idx = db_civ_state.civ_state[0].civ_idx
            const active = db_civ_state.civ_state[0].active
            const line = `Number: ${civ_idx}`
            const population = db_player_fungible_balances.player_fungible_balances.length
            const ticks_since_birth = db_macro_states.macro_states.length - 1 // at age 0 a macro state event is emitted

            content.push (<h5 key='stats-h5'>Civilization</h5>)
            content.push (<p key='stats-p-1'>{line}</p>)
            content.push (<p key='stats-p-2'>Population: {population}</p>)
            content.push (<p key='stats-p-3'>Universe age: {ticks_since_birth} / 2520 ticks</p>)
        }
    }

    //
    // Return component
    //
    return(
        <div>
            {content}
        </div>
    );
}
