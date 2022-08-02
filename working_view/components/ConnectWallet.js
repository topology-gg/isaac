import {
  useStarknet,
  InjectedConnector
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
  const { account, connect } = useStarknet()

  if (account) {
    return <p className="connected_account">Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}</p>
  }

  return <button onClick={() => connect(new InjectedConnector())}>Connect wallet</button>
}
