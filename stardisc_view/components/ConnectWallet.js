import {
    useStarknet,
    useConnectors
} from '@starknet-react/core'
import { useEffect, useState } from 'react'
import Button from './Button'
import { toBN } from 'starknet/dist/utils/number'

import styles from './ConnectWallet.module.css'

import {
    useStardiscRegistryByAccount
} from '../lib/api'

export function ConnectWallet() {

    const { account } = useStarknet()
    const { available, connect, disconnect } = useConnectors()
    const [connectors, setConnectors] = useState([])
    const [walletNotFound, setWalletNotFound] = useState(false)

    const account_str_decimal = toBN(account).toString(10)
    const { data: stardisc_query } = useStardiscRegistryByAccount (account_str_decimal) // must be a better way than fetching the entire registry

    // Connectors are not available server-side therefore we
    // set the state in a useEffect hook
    useEffect(() => {
        if (available) setConnectors(available)
    }, [available])

    const BUTTON_STYLE = {
        height: '72px',
        width: 'auto',
        padding: '0 25px',
        cursor: 'pointer',
        fontSize : '20px',
        borderRadius : '12px',
        border: '1px solid #000',
        fontFamily: 'Poppins-Light'
    }

    const DISCONNECT_BUTTON_STYLE = {
        height: '72px',
        width: 'auto',
        padding: '0 25px',
        cursor: 'pointer',
        fontSize : '20px',
        borderRadius: '0 12px 12px 0',
        borderLeft: '1px solid #000',
        fontFamily: 'Poppins-Light'
    }


    if (account) {
        return (
            <div className={styles.wrapper}>
                <p className={styles.text}>
                    Connected: {String(account).slice(0,5) + '...' + String(account).slice(-4)}
                </p>
                <Button
                    className='creamy-button'
                    style={DISCONNECT_BUTTON_STYLE}
                    onClick={() => disconnect()}
                >
                    Disconnect
                </Button>
            </div>
        )
    }

    const buttons_sorted = [].concat(connectors)
        .sort ((a,b) => {
            if(a.name() < b.name()) { return -1; }
            if(a.name() > b.name()) { return 1; }
            return 0;
        })
        .map ((connector) => (
            <Button
                key={connector.id()}
                onClick={() => connect(connector)}
                style = {BUTTON_STYLE}
                className = 'creamy-button'
            >
                {`Connect ${connector.name()}`}
            </Button>
        ))

    return (
        <div className={`${styles.wrapper} ${styles.wrapperConnectButtons}`}>
                {connectors.length > 0 ? buttons_sorted : (
                    <>
                        <Button onClick={() => setWalletNotFound(true)}>Connect</Button>
                        {walletNotFound && <p className='error-text'>Wallet not found. Please install ArgentX or Braavos.</p>}
                    </>
                )}
        </div>
    )
}

// function feltLiteralToString (felt) {

//     const tester = felt.split('');

//     let currentChar = '';
//     let result = "";
//     const minVal = 25;
//     const maxval = 255;

//     for (let i = 0; i < tester.length; i++) {
//         currentChar += tester[i];
//         if (parseInt(currentChar) > minVal) {
//             result += String.fromCharCode(currentChar);
//             currentChar = "";
//         }
//         if (parseInt(currentChar) > maxval) {
//             currentChar = '';
//         }
//     }

//     return result
// }