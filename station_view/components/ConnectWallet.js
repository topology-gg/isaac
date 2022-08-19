import {
  useStarknet,
  useConnectors
} from '@starknet-react/core'
import { useEffect, useState } from 'react'
import Button from './Button'

import styles from './ConnectWallet.module.css'


export function ConnectWallet() {

    const { account } = useStarknet()
    const { available, connect, disconnect } = useConnectors()
    const [connectors, setConnectors] = useState([])
    const [walletNotFound, setWalletNotFound] = useState(false)

    // Connectors  are not available server-side therefore we
    // set the state in a useEffect hook
    useEffect(() => {
      if (available) setConnectors(available)
    }, [available])

    if (account) {
        return (
            <div className={styles.wrapper}>
                <p className={styles.text}>
                    Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}
                </p>
                <Button className={styles.button} onClick={() => disconnect()}>
                    Disconnect
                </Button>
            </div>
      )
    }

    return (
      <div className={`${styles.wrapper} ${styles.wrapperConnectButtons}`}>
            {connectors.length > 0 ? connectors.map((connector) => (
                <Button
                    key={connector.id()}
                    onClick={() => connect(connector)}
                >
                    {`Connect ${connector.name()}`}
                </Button>
            )) : (
                <>
                    <Button onClick={() => setWalletNotFound(true)}>Connect</Button>
                    {walletNotFound && <p className='error-text'>Wallet not found. Please install ArgentX or Braavos.</p>}
                </>
            )}
      </div>
    )
}
