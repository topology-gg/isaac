import React from 'react'
import { useStarknet, useStarknetCall } from '@starknet-react/core'
import { useSNSContract } from "./SNSContract";
import { toBN } from 'starknet/dist/utils/number';

function feltLiteralToString (felt) {

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

function parseCallResult (res) {

    if (res && res.length > 0) {
        const exist = toBN(res.exist).toString(10)
        const name = toBN(res.name).toString(10)
        const name_string = feltLiteralToString (name)

        return [exist, name_string]
    }

}

function abbrevAccountString (accountString) {
    return "0x" + accountString.slice(0,3) + "..." + accountString.slice(-4)
}

const GameStatsPlayer = ({ accountString }) => {

    const { account } = useStarknet()
    const { contract: snsContract } = useSNSContract ()

    const signed_in_account_str = toBN(account).toString(16)

    const { data } = useStarknetCall ({
        contract: snsContract,
        method: 'sns_lookup_adr_to_name',
        args: ["0x" + accountString],
    })

    const [_exist, name] = data ? parseCallResult (data) : [null, null]

    const display_account_str = name || abbrevAccountString(accountString)

    return (
        <>
            {accountString === signed_in_account_str ? (
                <td style={{ color: '#00CCFF' }}>
                    {display_account_str}
                </td>
            ) : (
                <td>{display_account_str}</td>
            )}
        </>
    )

}

export default GameStatsPlayer
