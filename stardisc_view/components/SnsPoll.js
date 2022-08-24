import React, { useMemo } from "react";
import { toBN } from 'starknet/dist/utils/number'

import {
    StarknetProvider,
    useStarknet,
    useStarknetCall
} from '@starknet-react/core'

import { useStarDiscContract } from "./StarDiscContract";

import { useStardiscRegistryByAccount } from '../lib/api'

export function SnsPoll (props) {

    const { account, connect } = useStarknet ()
    const account_str_decimal = toBN(account).toString(10)
    const { data: stardisc_query } = useStardiscRegistryByAccount (account_str_decimal) // must be a better way than fetching the entire registry

    if (account) {
        if (!stardisc_query) return;

        var rendered_account
        if (stardisc_query.stardisc_query.length > 0) { // query succeeded
            const name = toBN(stardisc_query.stardisc_query[0].name).toString(10)
            const name_string = feltLiteralToString (name)
            rendered_account = <strong>{name_string}</strong>
        }
        else { // query failed
            rendered_account = 'not registered yet'
        }
    }

    return (
        <div>
            {rendered_account}
            {/* <p>loading: {loading}</p>
            <p>error: {error}</p> */}
        </div>
    );
}

// reference: https://stackoverflow.com/a/66228871
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