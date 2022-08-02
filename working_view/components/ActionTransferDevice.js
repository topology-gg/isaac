import React, { Component } from "react";
import { useForm } from "react-hook-form";

import {
    StarknetProvider,
  useStarknet,
  useStarknetInvoke
} from '@starknet-react/core'

import { BUTTON_LEFT_STYLE, INPUT_MID_STYLE, INPUT_END_STYLE, TX_HASH_STYLE } from "./ActionStyles";
import { DEVICE_TYPE_MAP } from './ConstantDeviceTypes'
import { useUniverseContract } from "./UniverseContract";

export function TransferDeviceInterface (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useUniverseContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'player_transfer_undeployed_device'
    })

    // type : felt,
    // amount : felt,
    // to : felt

    const {
        register: registerTransferDevice,
        handleSubmit: handleSubmitTransferDevice,
        formState: { errors: errorsTransferDevice }
    } = useForm();

    const onSubmitTransferDevice = (data) => {
        if (!account) {
            console.log('user wallet not connected yet')
        }
        else if (!contract) {
            console.log('universe contract not connected')
        }
        else {
            const args = [
                data['typeRequired'],
                data['amountRequired'],
                data['toIdxRequired']
            ]
            console.log('submit transfer device tx with args:', args)
            invoke ({ args: args })
        }
      }

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`

    return (
        <div style={{display:'flex',flexDirection:'row'}}>

            <form onSubmit={handleSubmitTransferDevice(onSubmitTransferDevice)}>
                <input type="submit" value={'Transfer device'} style={BUTTON_LEFT_STYLE} className='action-button'/>
                <input style={INPUT_MID_STYLE} placeholder="type"   {...registerTransferDevice("typeRequired", { required: true })} />
                <input style={INPUT_MID_STYLE} placeholder="amount" {...registerTransferDevice("amountRequired", { required: true })} />
                <input style={INPUT_END_STYLE} placeholder="to idx"     {...registerTransferDevice("toIdxRequired", { required: true })} />
                {/* {errorsTransferDevice.typeRequired && <span> (This field is required) </span>}
                {errorsTransferDevice.amountRequired && <span> (This field is required) </span>}
                {errorsTransferDevice.toIdxRequired && <span> (This field is required) </span>} */}
                {/* <p>Error: {error || 'No error'}</p> */}
            </form>

            <div style={{paddingLeft:'10px',paddingTop:'0',paddingBottom:'0',verticalAlign:'center'}}>
                {
                    data && (
                        <div>
                            <a style={TX_HASH_STYLE} href={link_to_voyager} target="_blank" rel="noopener noreferrer">view on voyager</a>
                        </div>
                    )
                }
            </div>
        </div>
    );
}
