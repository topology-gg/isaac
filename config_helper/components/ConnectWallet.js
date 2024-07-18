import {
  useStarknet,
  useConnectors
} from '@starknet-react/core'
import { useEffect, useState } from 'react'
import Button from './Button'
import { toBN } from 'starknet/dist/utils/number'

import styles from './ConnectWallet.module.css'
import { gyoza_addr } from './Addresses'

export function ConnectWallet (props) {

    const { account } = useStarknet()
    const { available, connect, disconnect } = useConnectors()
    const [connectors, setConnectors] = useState([])
    const [walletNotFound, setWalletNotFound] = useState(false)

    // Connectors are not available server-side therefore we
    // set the state in a useEffect hook
    useEffect(() => {
      if (available) setConnectors(available)
    }, [available])

    if (account) {
        // console.log ('account: ', account)

        const account_int_str = toBN(account).toString(10)
        const gyoza_int_str = toBN(gyoza_addr).toString(10)

        var render
        if (account_int_str === gyoza_int_str) {
            render = (
                <p className={styles.text}>
                    Welcome back, <strong>gyoza</strong>.
                </p>
            )
            props.set_is_gyoza (true)
        }
        else {
            const account_abbrev = String(account).slice(0,5) + '...' + String(account).slice(-4)
            render = (
                <p className={styles.text}>
                    {account_abbrev} is not gyoza.
                </p>
            )
            props.set_is_gyoza (false)
        }

        return (
            <div className={styles.wrapper}>
                {render}
                <Button className={styles.button} onClick={() => handleDisconnect()}>
                    Disconnect
                </Button>
            </div>
      )
    }

    function handleDisconnect () {
        disconnect ()
        props.set_is_gyoza (false)
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