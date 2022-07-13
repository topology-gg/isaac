import React, { Component } from "react";

import {
    StarknetProvider,
  useStarknet,
  useStarknetInvoke
} from '@starknet-react/core'

import { useUniverseContract } from "./UniverseContract";
import { BUTTON_SINGLE_STYLE } from "./ActionStyles";

const button_style = {
    fontSize:'12px',
    marginBottom:'5px',
    paddingTop:'5px',
    paddingBottom:'5px',
    paddingLeft:'30px',
    paddingRight:'30px',
    lineHeight:'15px'
}
export function PickupUtxInterface (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useUniverseContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'player_pickup_utx_by_grid'
    })
    const x = props.grid_x
    const y = props.grid_y
    const typ = props.typ

    function onClick () {
        console.log (`pickup utx button clicked! (x,y,typ)=(${x}, ${y}, ${typ})`)
        invoke ({ args: [{x:x, y:y}] })
    }

    return (
        <div style={{display:'flex',flexDirection:'row'}}>
            <button
                style = {BUTTON_SINGLE_STYLE}
                onClick = {onClick}
                className = 'action-button'
            >
                Pick up {typ}
            </button>

            <div>
                {
                    data && (
                        <div>
                            <p>Transaction Hash: {data}</p>
                        </div>
                    )
                }
            </div>
            <div>
                {/* <p>Submitting: {loading ? 'Submitting' : 'Not Submitting'}</p> */}
                {/* <p>Error: {error || 'No error'}</p> */}
            </div>
        </div>
    );
}
