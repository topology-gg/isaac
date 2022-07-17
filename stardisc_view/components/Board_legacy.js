import React, { Component } from "react";

const CIRCLE_RADIUS_EM = 1.1
const CIRCLE_RADIUS = `${CIRCLE_RADIUS_EM}em`
const CIRCLE_WIDTH =`${CIRCLE_RADIUS_EM*2}em`

export default function BoardView () {

    //
    // TODO: use db state for Masyu current puzzle
    //
    let mock_puzzle = {
        3 : 2,
        8 : 2,
        12 : 2,
        28 : 2,
        44 : 2,
        47 : 2,
        49 : 2,
        61 : 2,
        11 : 1,
        20 : 1,
        22 : 1,
        29 : 1,
        31 : 1,
        33 : 1,
        35 : 1,
        40 : 1
    }

    let map_circle_type_to_color = {
        // 1 : "#D96767",
        // 2 : "#FFDD8D"
        1 : "#0066b2",
        2 : "#FF9944"
    }

    const color_none = '#00000000'

    var rows = []
    for (var y=0; y<8; y++) {
        var cells = []

        for (var x=0; x<8; x++) {
            const cell_idx = y*8 + x
            if (cell_idx in mock_puzzle) {
                const color = map_circle_type_to_color[mock_puzzle[cell_idx]]
                console.log (`color: ${color}`)
                cells.push (
                    <td>
                        <div style={{height:CIRCLE_WIDTH,width:CIRCLE_WIDTH,backgroundColor:color,margin:"auto",borderRadius:CIRCLE_RADIUS,color:"#00000066",lineHeight:CIRCLE_WIDTH,textAlign:'center'}}>
                            {cell_idx}
                        </div>
                    </td>
                )
            }
            else {
                cells.push (
                    <td>
                        <div style={{color:'#FFFFFF66'}}>
                            {cell_idx}
                        </div>
                    </td>
                )
            }
        }

        rows.push (<tr>{cells}</tr>)
    }

    return (
        <div style={{display:'flex',flexDirection:'column',alignItems:'center',justifyContent:'center',paddingTop:'2em'}}>
            <h4>Current puzzle id: x</h4>
            <table>
                <thead>
                </thead>

                <tbody>
                    {rows}
                </tbody>
            </table>
        </div>
    );
}
