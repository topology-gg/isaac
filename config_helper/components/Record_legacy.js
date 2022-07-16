import React, { Component } from "react";

const div_style = {
    display:'flex',
    flexDirection:'column',
    alignItems:'center',
    overflowY:'auto',
    height:'10em',
    width:'25em',
    paddingTop: '0.5em',
    paddingRight: '1.2em'
}

export default function RecordView () {

    //
    // TODO: use db state for Masyu current puzzle
    //
    let mock_records = [
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':0},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':1},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':2},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':3},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':4},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':5},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':6},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':7},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':8},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':9},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':10},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':11},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':12},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':13},
        {'address':'0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898', 'puzzle_id':14}
    ]

    var rows = []
    for (var i=0; i<mock_records.length; i++) {
        var cells = []
        const account = '...'
        const puzzle_id = mock_records[i]['puzzle_id']
        cells.push (<td style={{width:'15em',height:'2em'}}>...</td>)
        cells.push (<td style={{width:'10em',height:'2em'}}>{puzzle_id}</td>)
        rows.push (<tr>{cells}</tr>)
    }

    return (
        <div style={{textAlign:'center'}}>
            <h4>Solved</h4>
            <div style={div_style}>
                <table>
                    <thead>
                        <tr>
                            <th>account</th>
                            <th>puzzle id</th>
                        </tr>
                    </thead>

                    <tbody>
                        {rows}
                    </tbody>
                </table>
            </div>
        </div>
    );
}
