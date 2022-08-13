import React, { useMemo } from "react";

import {
    StarknetProvider,
    useStarknet,
    useStarknetCall
} from '@starknet-react/core'

import { useSNSContract } from "./SNSContract";

export function SnsPoll (props) {

    const { account, connect } = useStarknet ()
    const { snsContract } = useSNSContract ()

    // console.log (`account: ${account}, typeof(account): ${typeof(account)}`)

    const { data : result, loading, error, refresh} = useStarknetCall ({
        contract: snsContract,
        method: 'sns_lookup_adr_to_name',
        args: [account]
    })

    const value = useMemo(() => {

        console.log (`result: ${result}`)
        if (result && result.length > 0) {

            // console.log (`result: ${result}`)
            return 'aa'
        //   const nameValue = toBN(nameValue[0])
        //   return nameValue.toString(10)

        }
    }, [result])

    return (
        <div style={{display:'flex',flexDirection:'column',marginTop: '20px'}}>
            <p>Lookup: {value}</p>
            <p>loading: {loading}</p>
            <p>error: {error}</p>
        </div>
    );
}
