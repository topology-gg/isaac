import React, { Component } from "react";
import styles from "../styles/Modal.module.css";
import { useStarDiscContract } from "./StarDiscContract";

import {
    useStarknetInvoke
} from '@starknet-react/core'

export default function Modal (props) {

    const selected_grids = props.info.grids

    const { contract } = useS2m2Contract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'solve'
    })

    function onClick () {
        console.log (`solution submitting! ${5}`)
        const arr_cell_indices_len = selected_grids.length
        var arr_cell_indices = []
        for (const grid of selected_grids) {
            arr_cell_indices.push (grid.y*8 + grid.x)
        }
        invoke ({ args: [
            props.puzzle_id,
            arr_cell_indices
        ] })
    }

    const modal_left_child_style = {
        display: 'flex',
        flexDirection: 'column',
        paddingLeft: '0.6em',
        width: '20em'
    }

    const modal_right_child_style = {
        display: 'flex',
        order: 1,
        flexDirection: 'column',
        marginLeft: '2em',
        fontSize: '1em'
    }

    var display_grids = ''
    if (selected_grids[0]) {
        for (const grid of selected_grids) {
            display_grids += `${grid.y*8 + grid.x} → `
        }
        display_grids += `${selected_grids[0].y*8 + selected_grids[0].x}`
    }


    const TX_HASH_STYLE = {
        fontSize: '12px',
        color: '#333333',
        lineHeight:'15px',
        padding:'0',
        margin:'0'
    }

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`
    const button_string = "let's go"

    return (
        <div style={{display:'flex',alignItems:'center',justifyContent:'center'}}>

            { props.show ?
                <div className={styles.modal}>

                    <p>Submitting: {display_grids}</p>

                    <button onClick={onClick} style={{width:'fit-content',padding:'1px 15px'}} className='action-button'>
                        {button_string}
                    </button>

                    <p>{error ? error : null}</p>
                    <div>
                        {
                            data && (
                                <a style={TX_HASH_STYLE} href={link_to_voyager}>view on voyager</a>
                            )
                        }
                    </div>

                </div>
            : null }

        </div>
    )
}
