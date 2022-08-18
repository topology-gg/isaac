import {
  useStarknet,
  useConnectors
} from '@starknet-react/core'
import { useEffect, useState } from 'react'
import Button from './Button'


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
            <>
                <p className="connected_account"
                    style={{padding:'0',margin:'0',height:'25px',verticalAlign:'middle',fontSize:'12px'}}
                >
                    Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}
                </p>
                <Button onClick={() => disconnect()}>
                    Disconnect
                </Button>
            </>
      )
    }

    return (
        <>
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
        </>
    )
}
