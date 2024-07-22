import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";

import { toBN } from 'starknet/dist/utils/number'
import {
    usePuzzles,
    useS2mState
} from '../lib/api'

export default function Record (props) {

    const { data: db_puzzles } = usePuzzles ()
    var rows = []

    if (db_puzzles) {
        for (const puzzle of db_puzzles.puzzles) {
            const solver_hex_str = toBN(puzzle.solver).toString(16)
            const solver_hex_str_abbrev = "0x" + solver_hex_str.slice(0,3) + "..." + solver_hex_str.slice(-4)

            const button_style = {
                backgroundColor : puzzle.solved == 1 ? '#999999' : 'CCCCCC',
                color : puzzle.solved == 1 ? '#555555' : '#333333',
                border: 'none',
                padding: '1px 10px',
                fontSize: '12px'
            }

            var cells = []
            cells.push (
                <td>
                    <button onClick={() => {
                        props.callBack(puzzle.puzzle_id);
                    }} style={button_style}>
                     {puzzle.puzzle_id}
                    </button>
                </td>
            )
            if (puzzle.solved == 1) {
                cells.push (<td style={{fontSize:'12px'}}>{solver_hex_str_abbrev}</td>)
            }
            else {
                cells.push (<td>{'-'}</td>)
            }
            rows.push (<tr>{cells}</tr>)
        }
    }

    const style = {
        overflowY:'auto',
        height:'21em'
    }

    return (
        <div>

            <h3>Records</h3>

            <div style={style}>
                <table style={{margin:'0 auto'}}>
                    <thead>
                        <th style={{width:'5em',fontSize:'12px'}}>puzzle id</th>
                        <th style={{width:'10em',fontSize:'12px'}}>solver</th>
                    </thead>

                    <tbody>
                        {rows}
                    </tbody>
                </table>
            </div>

        </div>
    );
}