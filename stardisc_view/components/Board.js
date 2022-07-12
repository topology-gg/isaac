import React, { Component } from "react";

const button_style = {
    fontSize:'12px',
    marginBottom:'5px',
    paddingTop:'5px',
    paddingBottom:'5px',
    paddingLeft:'30px',
    paddingRight:'30px',
    lineHeight:'15px'
}
export default function BoardView () {

    //
    // TODO: use db state for Masyu current puzzle
    //
    let puzzle = {
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
        1 : "#D96767",
        2 : "#FFDD8D"
    }

    const color_none = '#00000000'

    var rows = []
    for (var y=0; y<9; y++) {
        var cells = []

        // y axis ticks
        if (y == 0) {
            cells.push (<td style={{borderTopColor:color_none,borderBottomColor:color_none,borderLeftColor:color_none,borderRightColor:color_none}}>x \ y</td>)
            for (var x=1; x<9; x++) {
                cells.push (<td style={{borderTopColor:color_none,borderLeftColor:color_none,borderRightColor:color_none}}>{x-1}</td>)
            }
        }
        else {
            cells.push (<td style={{borderTopColor:color_none,borderBottomColor:color_none,borderLeftColor:color_none}}>{y-1}</td>)
            for (var x=1; x<9; x++) {
                const cell_idx = (y-1)*8 + (x-1)
                if (cell_idx in puzzle) {
                    const color = map_circle_type_to_color[puzzle[cell_idx]]
                    console.log (`color: ${color}`)
                    cells.push (
                        <td>
                            <div style={{height:"24px",width:"24px",backgroundColor:color,margin:"auto",borderRadius:"12px",color:"#00000044",lineHeight:'24px',textAlign:'center'}}>
                                {cell_idx}
                            </div>
                        </td>
                    )
                }
                else {
                    cells.push (
                        <td>
                            <div style={{color:'#FFFFFF44'}}>
                                {cell_idx}
                            </div>
                        </td>
                    )
                }
            }
        }
        rows.push (<tr>{cells}</tr>)
    }

    return (
        <div>
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
