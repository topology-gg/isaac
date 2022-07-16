import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";

import {
    usePuzzles,
    useS2mState
} from '../lib/api'

export default function Record (props) {

    const { data: db_puzzles } = usePuzzles ()
    var rows = []

    if (db_puzzles) {
        for (const puzzle of db_puzzles.puzzles) {
            var cells = []
            cells.push (
                <td>
                    <button onClick={() => {
                        props.callBack(puzzle.puzzle_id);
                    }}>
                     {puzzle.puzzle_id}
                    </button>
                </td>
            )
            if (puzzle.solved == 1) {
                cells.push (<td>puzzle.solver</td>)
            }
            else {
                cells.push (<td>{'-'}</td>)
            }
            rows.push (<tr>{cells}</tr>)
        }
    }

    const style = {
        overflowY:'auto',
        height:'20em'
    }

    return (
        <div>

            <h3>Records</h3>

            <div style={style}>
                <table style={{margin:'0 auto'}}>
                    <thead>
                        <th style={{width:'5em'}}>puzzle id</th>
                        <th style={{width:'10em'}}>solver</th>
                    </thead>

                    <tbody>
                        {rows}
                    </tbody>
                </table>
            </div>

        </div>
    );
}