import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useCivStates,
    useMacroStatesAll
} from '../lib/api'


export default function Panel (props) {

    //
    // Data fetched from backend on Apibara
    //
    const { data: db_civ_states } = useCivStates ()
    const { data: db_macro_states_all } = useMacroStatesAll ()

    //
    // React states and references
    //
    const [hasLoadedDB, setHasLoadedDB] = useState (false)
    const [historyRows, setHistoryRows] = useState ([])

    //
    // Check if all db collections are loaded
    //
    useEffect (() => {
        if (!db_civ_states || !db_macro_states_all) {
            console.log ('Panel: db loading ...')
            setHasLoadedDB (false)
            return
        }
        if (hasLoadedDB) {
            return
        }
        else {
            console.log ('> Panel: db loaded!')
            setHasLoadedDB (true)
        }
    }, [hasLoadedDB, db_civ_states, db_macro_states_all]);

    function handle_fate_button_click (civ_idx, macro_states_by_civ_idx) {
        console.log ('handle_fate_button_click called, civ_idx =',civ_idx)
        props.toggleReplayWindow ()
        props.setDbStatesReplayWindow ({
            'civ_idx' : civ_idx,
            'macro_states' : macro_states_by_civ_idx [civ_idx]
        })
    }

    //
    // Set display once database collections are all loaded
    //
    useEffect (() => {
        if (hasLoadedDB) {

            // Isolate macro states by their civ number, using civilization birth block numbers to filter
            const macro_states_by_civ_idx = {}

            const civ_states_length = db_civ_states.civ_states.length
            db_civ_states.civ_states.forEach(function (civ_state, i) {
                if (i == 0) { // civ_states is sorted with most recent civ at head of array
                    const block_num_lower_bound = civ_state.birth_block_number
                    const macro_states_of_civ = db_macro_states_all.macro_states_all.filter( function(macro_state) {
                        return macro_state.block_number > block_num_lower_bound;
                    });
                    macro_states_by_civ_idx [civ_state.civ_idx] = macro_states_of_civ
                    // console.log (`civ ${civ_state.civ_idx}, filter >${block_num_lower_bound}`)
                }
                else {
                    const block_num_lower_bound = civ_state.birth_block_number
                    const block_num_upper_bound = db_civ_states.civ_states[i-1].birth_block_number
                    const macro_states_of_civ = db_macro_states_all.macro_states_all.filter( function(macro_state) {
                        return (macro_state.block_number > block_num_lower_bound) && (macro_state.block_number < block_num_upper_bound);
                    });
                    macro_states_by_civ_idx [civ_state.civ_idx] = macro_states_of_civ
                    // console.log (`civ ${civ_state.civ_idx}, filter >${block_num_lower_bound} & <${block_num_upper_bound}`)
                }
            });

            var rows = []
            var i=0
            for (const civ_state of db_civ_states.civ_states) {
                var cells = []
                cells.push (<td key={`td-civ-num-${i}`} style={{fontSize:'14px',textAlign:'center'}}>{`Civ. number ${civ_state.civ_idx}`}</td>)
                cells.push (
                    <td key={`td-civ-fate-${i}`} style={{fontSize:'14px',textAlign:'left'}}>
                        <button
                            onClick={ () => handle_fate_button_click(civ_state.civ_idx, macro_states_by_civ_idx) }
                            style={{
                                padding:'0 25px',margin:'0',height:'25px',border:'0',
                                color:'#333333',fontSize:'13.33px',fontFamily:'Poppins-Light',
                                borderRadius: '10px'}}
                        >
                            {civ_state.fate}
                        </button>
                    </td>
                )
                rows.push (<tr key={`tr-civ-${i}`}>{cells}</tr>)
                i++;
            }
            setHistoryRows (rows)
        }
    }, [hasLoadedDB, db_civ_states, db_macro_states_all])


    return (
        <div style={{display:'flex',flexDirection:'column',textAlign:'center'}}>
            <h2 style={{marginBottom:'0'}}>Isaac History</h2>
            <p style={{marginTop:'5px',marginBottom:'30px'}}>the fate of past civilizations</p>

            {/* <div style={{overflowY: 'auto', height:'300px'}}> */}
            <table>
                <thead>
                    <tr>
                        {/* <th>Civilization number</th> */}
                        {/* <th>Fate</th> */}
                    </tr>
                </thead>
                <tbody>
                    {historyRows}
                </tbody>
            </table>
            {/* </div> */}

        </div>
    );
  }
