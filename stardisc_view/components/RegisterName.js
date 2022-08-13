import React, { Component } from "react";
import { useForm } from "react-hook-form";

import {
    StarknetProvider,
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core'

import { useSNSContract } from "./SNSContract";

export function RegisterName (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useSNSContract ()
    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract,
        method: 'sns_register'
    })

    const {
        register: register,
        handleSubmit: handleSubmit,
        formState: { errors: errors }
    } = useForm();

    const onSubmitSnsRegister = (data) => {
        if (!account) {
            console.log('user wallet not connected yet')
        }
        else if (!contract) {
            console.log('sns contract not connected')
        }
        else {
            const name_in_felt = data['nameRequired'].split('').map (function (c) { return c.charCodeAt(0); }).join('')
            const args = [
                name_in_felt
            ]
            console.log(`submit sns_register tx with args: ${args}`)
            invoke ({ args: args })
        }
      }

    const link_to_voyager = `https://goerli.voyager.online/tx/${data}`

    const HEIGHT = '50px'
    const FORM_STYLE = {
        // height: '50px'
    }
    const INPUT_STYLE = {
        height: HEIGHT,
        paddingTop: '0',
        paddingBottom: '0',
        border: '0',
        paddingLeft: '10px',
        width: '160px'
        // fontSize: '16px',
        // lineHeight: '20px',
        // height: '50px',
        // paddingLeft: '5px',
        // borderRadius: '8px, 0px, 0px, 8px',
        // padding: '0',
        // borderWidth: '0'
    }
    const TX_HASH_STYLE = {

    }
    const BUTTON_STYLE = {
        height: HEIGHT,
        width: '40px',
        padding: '0 0',
        border: '0',
        cursor: 'pointer'
        // padding  : '0 15px',
        // padding: '0',
        // fontSize : '12px',
        // height   : '50px',
        // border   : '0',
        // color    : '#333333',
        // borderRadius : '0px 8px 8px 0px',

    }

    return (
        <div style={{display:'flex',flexDirection:'row',marginTop: '20px'}}>

            <form onSubmit={handleSubmit(onSubmitSnsRegister)} style={FORM_STYLE}>
                <input style={INPUT_STYLE} placeholder="gnocchi#6789" {...register("nameRequired", { required: true })} />
                <input type="submit" value={'Go'} style={BUTTON_STYLE}/>
                {/* <p>Error: {error || 'No error'}</p> */}
            </form>

            {/* <div style={{paddingLeft:'10px',paddingTop:'0',paddingBottom:'0',verticalAlign:'center'}}>
                {
                    data && (
                        <div>
                            <a style={TX_HASH_STYLE} href={link_to_voyager} target="_blank" rel="noopener noreferrer">view on voyager</a>
                        </div>
                    )
                }
            </div> */}
        </div>
    );
}
