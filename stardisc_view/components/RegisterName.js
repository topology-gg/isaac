import React, { Component } from "react";
import { useForm } from "react-hook-form";

import {
    StarknetProvider,
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core'

import { useStarDiscContract } from "./StarDiscContract";

export function RegisterName (props) {

    const { account, connect } = useStarknet ()
    const { contract } = useStarDiscContract ()
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

    const HEIGHT = '70px'
    const HEIGHT_BUTTON = '72px'
    const FORM_STYLE = {
        // height: '50px'
    }
    const INPUT_STYLE = {
        height: HEIGHT,
        paddingTop: '0',
        paddingBottom: '0',
        paddingLeft: '10px',
        width: '250px',
        fontSize: '20px',
        backgroundColor: '#FFFFFF',
        border: '1px solid #000',
        borderRight: '0',
        borderRadius: '12px 0px 0px 12px',
        fontFamily: 'Poppins-Light'
    }

    const TX_HASH_STYLE = {
        fontSize: '12px',
        color: '#999',
        lineHeight:'12px',
        padding:'0',
        margin:'0'
    }
    const BUTTON_STYLE = {
        height: HEIGHT_BUTTON,
        width: '70px',
        padding: '0 0',
        cursor: 'pointer',
        fontSize : '20px',
        borderRadius : '0px 12px 12px 0px',
        border: '1px solid #000',
        fontFamily: 'Poppins-Light'

    }

    return (
        <div style={{display:'flex',flexDirection:'column',marginTop: '20px'}}>

            <div style={{display:'flex',flexDirection:'row'}}>
                <form onSubmit={handleSubmit(onSubmitSnsRegister)} style={FORM_STYLE}>
                    <input style={INPUT_STYLE} placeholder="gnocchi#6789" {...register("nameRequired", { required: true })} />
                    <input type="submit" value={'Go'} style={BUTTON_STYLE} className = 'creamy-button'/>
                    {/* <p>Error: {error || 'No error'}</p> */}
                </form>
            </div>

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
