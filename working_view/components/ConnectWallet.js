import {
  useStarknet,
  useConnectors,
} from '@starknet-react/core'

// export function ConnectWallet() {
//   const { account, connect } = useStarknet()

//   if (account) {
//     return <div>Account: {account}</div>
//   }

//   return (
//     <div>
//       <div>
//         <div>Connected Account: {account}</div>
//       </div>
//       {InjectedConnector.ready() ? (
//           <button onClick={() => connect(new InjectedConnector())}>Connect Argent-X</button>
//       ) : (
//         <div>
//           <p>
//             <a href="https://github.com/argentlabs/argent-x">Download Argent-X</a>
//           </p>
//         </div>
//       )}
//     </div>
//   )

// }


export function ConnectWallet() {
  const { account } = useStarknet()
  const { available, connect, disconnect } = useConnectors()

  if (account) {
    // return <p className="connected_account">Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}</p>

    return (
        <>
            <p className="connected_account"
                style={{padding:'0',margin:'0',height:'25px',verticalAlign:'middle',fontSize:'12px'}}
            >
                Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}
            </p>
            <button className='wallet-button' onClick={() => disconnect()}>
                Disconnect
            </button>
        </>
    )
  }

  return (
    <>
        {available.length > 0 ? (
            available.map((connector) => (
                <button className='wallet-button' key={connector.id()} onClick={() => connect(connector)}>
                    Connect {connector.name()}
                </button>
            ))
        ) : (
            <p className="no_connectors">
                Wallet not found. Please install ArgentX or Braavos.
            </p>
        )}
    </>
  )
}
