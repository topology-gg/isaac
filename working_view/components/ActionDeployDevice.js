import React, { Component, useEffect } from "react";

import {
    StarknetProvider,
  useStarknet,
  useStarknetInvoke
} from '@starknet-react/core'

import { BUTTON_SINGLE_STYLE, BUTTON_SINGLE_DISABLED_STYLE } from "./ActionStyles";
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
export function DeployDeviceInterface (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useUniverseContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'player_deploy_device_by_grid'
    })
    const { typ, onDeployStarted } = props
    const x = props.grid_x
    const y = props.grid_y

    function onClick () {

        if (!props.have_nonzero_balance ) {
            console.log ('cannot deploy because having 0 balance of this device type')
        }
        else {
            console.log (`deploy device clicked! (x,y,type) = (${x},${y},${typ})`)
            // To test without submitting transaction
            // onDeployStarted({ x, y, typ, txid: `faketxid${typ}${x}${y}` })
            invoke ({ args: [
                typ,
                {x:x, y:y}
            ] })
        }
    }

    /**
     * Trigger onDeployStarted when the transaction is sent
     *
     * onDeployStarted is deliberately not in the dependencies for this effect
     * Because we only want to trigger this once when `data` becomes available,
     * not when onDeployStarted changes.
     */
    useEffect(() => {
        if (data) {
            console.log (`deploy device transaction broadcasted! (x,y,type) = (${x},${y},${typ},${data})`)
            onDeployStarted({ x, y, typ, txid: data })
        }
    } , [x, y, typ, data])

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`

    return (
        <div style={{display:'flex',flexDirection:'row'}}>
            <button
                style = {props.have_nonzero_balance ? BUTTON_SINGLE_STYLE : BUTTON_SINGLE_DISABLED_STYLE}
                // style = {BUTTON_SINGLE_DISABLED_STYLE}
                onClick = {onClick}
                className = 'action-button'
            >
                Deploy {DEVICE_TYPE_MAP[typ]}
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
