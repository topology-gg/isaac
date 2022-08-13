import React, { Component, useEffect } from "react";

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
    const { id, grid_x: x, grid_y: y, typ, onPendingPickup } = props

    function onClick () {
        console.log (`pickup utx button clicked! (x,y,typ)=(${x}, ${y}, ${typ})`)
        // onPendingPickup({ id, txid: `faketxid${id}` })
        invoke ({ args: [{x:x, y:y}] })
    }

    useEffect(() => {
        if (data) {
            console.log (`deploy device transaction broadcasted! (id,x,y,type) = (${id},${x},${y},${typ},${data})`)
            onPendingPickup({ id, txid: data })
        }
    } , [id, data])

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`

    return (
        <div style={{display:'flex',flexDirection:'row'}}>
            <button
                style = {BUTTON_SINGLE_STYLE}
                onClick = {onClick}
                className = 'action-button'
            >
                Pick up {typ}
            </button>

            <div style={{paddingLeft:'10px',paddingTop:'0',paddingBottom:'0',verticalAlign:'center'}}>
                {
                    data && (
                        <div>
                            {/* <p>Transaction Hash: {data}</p> */}
                            <a style={{fontSize:'12px'}} href={link_to_voyager} target="_blank" rel="noopener noreferrer">view on voyager</a>
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
