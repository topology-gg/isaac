import React, { Component } from "react";

import {
    StarknetProvider,
  useStarknet,
  useStarknetInvoke
} from '@starknet-react/core'

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
export function PickupDeviceInterface (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useUniverseContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'player_pickup_device_by_grid'
    })
    const x = props.grid_x
    const y = props.grid_y
    const typ = props.typ

    function onClick () {
        console.log (`pickup device button clicked! (x,y,typ)=(${x}, ${y}, ${typ})`)
        invoke ({ args: [x, y] })
    }

    return (
        <div>
            <button
                style = {button_style}
                onClick = {onClick}
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
        </div>
    );
}
