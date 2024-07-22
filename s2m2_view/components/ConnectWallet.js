import {
  useStarknet,
  InjectedConnector
} from '@starknet-react/core'


export function ConnectWallet() {
  const { account, connect } = useStarknet()

  if (account) {
    return (
        <p
            className="connected_account"
            style={{padding:'0',margin:'0',height:'25px',verticalAlign:'middle'}}
        >
            Connected account: {String(account).slice(0,5)}...{String(account).slice(-4)}
        </p>
    )
  }

  return <button
            onClick = {
                () => {
                    connect(new InjectedConnector())
                    console.log ('connect')
                }
            }
            style={{padding:'0 15px',fontSize:'12px',height:'25px',border:'0',color:'#333333'}}
        >
            Connect wallet
        </button>
}
