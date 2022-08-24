import {
  useStarknet,
  useConnectors
} from '@starknet-react/core'
import { useEffect, useState } from 'react'
import Button from './Button'
import { toBN } from 'starknet/dist/utils/number'

import styles from './ConnectWallet.module.css'

import {
    useStardiscRegistry
} from '../lib/api'

export function ConnectWallet() {

    const { account } = useStarknet()
    const { available, connect, disconnect } = useConnectors()
    const [connectors, setConnectors] = useState([])
    const [walletNotFound, setWalletNotFound] = useState(false)

    const { data: db_stardisc_registry } = useStardiscRegistry () // must be a better way than fetching the entire registry

    // Connectors are not available server-side therefore we
    // set the state in a useEffect hook
    useEffect(() => {
      if (available) setConnectors(available)
    }, [available])

    if (account) {
        if (!db_stardisc_registry.stardisc_registry) return;

        console.log ('> fetched stardisc_registry:', db_stardisc_registry.stardisc_registry)

        const account_str_decimal = toBN(account).toString(10)
        const found_name_obj = db_stardisc_registry.stardisc_registry.find(o => o.addr === account_str_decimal);

        var rendered_account
        if (found_name_obj) {
            const name = toBN(found_name_obj.name).toString(10)
            const name_string = feltLiteralToString (name)
            rendered_account = name_string
        }
        else {
            rendered_account = String(account).slice(0,5) + '...' + String(account).slice(-4)
        }

        return (
            <div className={styles.wrapper}>
                <p className={styles.text}>
                    Connected: {rendered_account}
                </p>
                <Button className={styles.button} onClick={() => disconnect()}>
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