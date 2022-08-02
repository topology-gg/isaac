import React, { Component } from "react";

import {
    StarknetProvider,
  useStarknet,
  useStarknetInvoke
} from '@starknet-react/core'

import { BUTTON_SINGLE_STYLE } from "./ActionStyles";
import { DEVICE_TYPE_MAP } from './ConstantDeviceTypes'
import { useUniverseContract } from "./UniverseContract";

const button_style = {
    fontSize:'12px',
    marginBottom:'5px',
    paddingTop:'5px',
    paddingBottom:'5px',
    paddingLeft:'30px',
    paddingRight:'30px',
    lineHeight:'15px'
}
export function DeployUtxInterface (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useUniverseContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'player_deploy_utx_by_grids'
    })
    const utx_type = props.type

    // const x = props.grid_x
    // const y = props.grid_y
    // const typ = props.typ

    const src_grid  = props.grids[0]
    const dst_grid  = props.grids[props.grids.length-1]
    var utx_grids = []
    for (const grid of props.grids.slice(1,-1)) {
        utx_grids.push ({x:grid.x, y:grid.y})
    }

    function onClick () {
        console.log (`deploy utx clicked!`)
        invoke ({ args: [
            utx_type,
            {x:src_grid.x, y:src_grid.y},
            {x:dst_grid.x, y:dst_grid.y},
            utx_grids
        ] })
    }

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`

    return (
        <div style={{display:'flex',flexDirection:'row'}}>
            <button
                style = {BUTTON_SINGLE_STYLE}
                onClick = {onClick}
                className = 'action-button'
            >
                Deploy {DEVICE_TYPE_MAP[utx_type]}
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
            {/* <div>
                <p>Submitting: {loading ? 'Submitting' : 'Not Submitting'}</p>
                <p>Error: {error || 'No error'}</p>
            </div> */}
        </div>
    );
}
