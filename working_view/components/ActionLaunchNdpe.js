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
export function LaunchNdpeInterface (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useUniverseContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'player_launch_all_deployed_ndpe'
    })
    const x = props.grid_x
    const y = props.grid_y

    function onClick () {
        console.log (`launch ndpe button clicked! (x,y)=(${x}, ${y})`)
        invoke ({ args: [{x:x, y:y}] })
    }

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`

    return (
        <div style={{display:'flex',flexDirection:'row'}}>
            <button
                style = {BUTTON_SINGLE_STYLE}
                onClick = {onClick}
                className = 'action-button'
            >
                Launch *all* NDPE
            </button>

            <div style={{paddingLeft:'10px',paddingTop:'0',paddingBottom:'0',verticalAlign:'center'}}>
            {
                    data && (
                        <div>
                            {/* <p>Transaction Hash: {data}</p> */}
                            <a style={{fontSize:'12px'}} href={link_to_voyager}>view on voyager</a>
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
