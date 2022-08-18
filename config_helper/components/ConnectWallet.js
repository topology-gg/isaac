import {
  useStarknet,
  useConnectors
} from '@starknet-react/core'
import { useEffect, useState } from 'react'


export function ConnectWallet() {

    const { account } = useStarknet()
    const { available, connect, disconnect } = useConnectors()
    const [connectors, setConnectors] = useState([])

    // Connectors  are not available server-side hterefore we 
    // set the state in a useEffect hook
    useEffect(() => {
      if (available) setConnectors(available)
    }, [available])

    const BUTTON_STYLE = {padding:'0',margin:'0',height:'25px',border:'0',width:'160px',color:'#333333',fontSize:'13.33px',fontFamily:'Poppins-Light'}

    if (account) {
        return (
            <div>
                <p className="connected_account"
                    style={{padding:'0',margin:'0',height:'25px',verticalAlign:'middle',fontSize:'12px'}}
                >
                    Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}
                </p>
                <button style={BUTTON_STYLE}
                    onClick={() => disconnect()}>
                        Disconnect
                </button>
            </div>
      )
    }

    return (
        <div>
            {connectors.map((connector) => (
                <button
                    style={BUTTON_STYLE}
                    key={connector.id()} onClick={() => connect(connector)}>
                    {`Connect ${connector.name()}`}
                </button>
            ))}
        </div>
    )

    // const { account } = useStarknet()
    // const { available, connect, disconnect } = useConnectors()

    // if (account) {
    //     return (
    //         <p
    //             className="connected_account"
    //             style={{padding:'0',margin:'0',height:'25px',verticalAlign:'middle',fontSize:'12px'}}
    //         >
    //             Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}
    //         </p>
    //     )
    // }

    // return (
    //     <div>
    //       {available.map((connector) => (
    //         <button key={connector.id()} onClick={() => connect(connector)}>
    //           {`Connect ${connector.name()}`}
    //         </button>
    //       ))}
    //     </div>
    //   )
}
