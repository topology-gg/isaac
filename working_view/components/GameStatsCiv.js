import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useCivState,
    useMacroStates,
    usePlayerBalances
} from '../lib/api'

export default function GameStatsCiv() {

    var content = []
    const { data: db_civ_state } = useCivState ()
    const { data: db_macro_states } = useMacroStates ()
    const { data: db_player_balances } = usePlayerBalances ()

    if (!db_civ_state || !db_macro_states || !db_player_balances) {
        content = []
    }
    else {
        if (db_macro_states.macro_states.length == 0) {
            content.push (<p>{'** universe inactive **'}</p>)
        }
        else {
            console.log ('got db_civ_state:', db_civ_state.civ_state[0])
            const civ_idx = db_civ_state.civ_state[0].civ_idx
            const active = db_civ_state.civ_state[0].active
            const line = `Number: ${civ_idx}`
            const population = db_player_balances.player_balances.length

            content.push (<h5>Civilization</h5>)
            content.push (<p>{line}</p>)
            content.push (<p>Population: {population}</p>)
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
