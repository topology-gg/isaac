import React, { useMemo } from "react";
import { toBN } from 'starknet/dist/utils/number'

import {
    StarknetProvider,
    useStarknet,
    useStarknetCall
} from '@starknet-react/core'

import { useSNSContract } from "./SNSContract";

export function SnsPoll (props) {

    const { account, connect } = useStarknet ()
    const { contract: snsContract } = useSNSContract ()

    // console.log (`account: ${account}, typeof(account): ${typeof(account)}`)

    const { data : result, loading, error, refresh} = useStarknetCall ({
        contract: snsContract,
        method: 'sns_lookup_adr_to_name',
        args: [account]
    })

    const value = useMemo(() => {

        if (result && result.length > 0) {
            const exist = toBN(result.exist).toString(10)
            const name = toBN(result.name).toString(10)
            const name_string = felt_literal_to_string (name)

            console.log ('exist:', exist)
            console.log ('name:', name_string)
            return [exist, name_string]
        }

    }, [result])

    const info =
        !value ? '' :
        value[0] == 0 ? ' not registered yet' : ' ' + value[1]


    return (
        <div>
            {
                value && (
                    value[0] == 0 ?
                        <p style={{fontSize:'20px'}}>you are {info} </p>
                        :
                        <p style={{fontSize:'20px'}}>you are <strong>{info}</strong> </p>
                )
            }
            {/* <p>loading: {loading}</p>
            <p>error: {error}</p> */}
        </div>
    );
}

// reference: https://stackoverflow.com/a/66228871
function felt_literal_to_string (felt) {

    const tester = felt.split('');

    let currentChar = '';
    let result = "";
    const minVal = 25;
    const maxval = 255;

    for (let i = 0; i < tester.length; i++) {
        currentChar += tester[i];
        if (parseInt(currentChar) > minVal) {
            console.log(currentChar, String.fromCharCode(currentChar));
            result += String.fromCharCode(currentChar);
            currentChar = "";
        }
        if (parseInt(currentChar) > maxval) {
            currentChar = '';
        }
    }

    return result
}