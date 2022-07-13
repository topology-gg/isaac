import React, { Component, useState, useEffect, useRef, useMemo, Table } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useCivState
} from '../lib/api'

export default function GameStatsCiv() {

    var content = []
    const { data: db_civ_state } = useCivState ()
    if (db_civ_state) {
        console.log ('got db_civ_state:', db_civ_state.civ_state[0])
        const civ_idx = db_civ_state.civ_state[0].civ_idx
        const active = db_civ_state.civ_state[0].active

        if (active != 1) {
            content.push (<p>{'universe inactive'}</p>)
        }
        else {
            const line = `Number: ${civ_idx}`
            content.push (<p>{line}</p>)
        }
    }

    //
    // Return component
    //
    return(
        <div>
            <h5>Civilization</h5>
            {content}
            <p>Population: 25</p>
        </div>
    );
}
