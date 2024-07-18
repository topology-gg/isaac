import React, { useState, useEffect } from 'react'
import { useStarknet } from '@starknet-react/core'
import { toBN } from 'starknet/dist/utils/number';
import { abbrevHexString } from '../lib/helpers/feltAbbreviator';
import {
    useStardiscRegistryByAccount
} from '../lib/api'

function feltLiteralToString (felt) {

    const tester = felt.split('');

    let currentChar = '';
    let result = "";
    const minVal = 25;
    const maxval = 255;

    for (let i = 0; i < tester.length; i++) {
        currentChar += tester[i];
        if (parseInt(currentChar) > minVal) {
            result += String.fromCharCode(currentChar);
            currentChar = "";
        }
        if (parseInt(currentChar) > maxval) {
            currentChar = '';
        }
    }

    return result
}

const GameStatsPlayer = ({ accountBn }) => {

    const { account } = useStarknet()
    const signedInAccountStr = toBN(account).toString(10)
    const { data: db_stardisc_query } = useStardiscRegistryByAccount (accountBn.toString(10))

    // React state
    const [displayAccountStr, setDisplayAccountStr] = useState ()

    useEffect(() => {
        if (!db_stardisc_query) return;
        if (db_stardisc_query.stardisc_query.length == 0) {
            const abbrev_account_hexstr = abbrevHexString (accountBn.toString(16))
            setDisplayAccountStr (abbrev_account_hexstr)
            return;
        }

        const name = toBN(db_stardisc_query.stardisc_query[0].name).toString(10)
        const name_string = feltLiteralToString (name)

        setDisplayAccountStr (name_string)
    }, [db_stardisc_query])

    return (
        <>
            {accountBn.toString(10) === signedInAccountStr ? (
                <td style={{ color: '#FFAD48' }}>
                    {displayAccountStr}
                </td>
            ) : (
                <td>{displayAccountStr}</td>
            )}
        </>
    )

}

export default GameStatsPlayer
