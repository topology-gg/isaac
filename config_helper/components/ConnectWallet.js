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
            style={{padding:'0',margin:'0',height:'25px',verticalAlign:'middle',fontSize:'12px'}}
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
            style={{padding:'0',margin:'0',height:'25px',border:'0',width:'160px',color:'#333333',fontSize:'12px'}}
        >
            Connect Argent X wallet
        </button>
}
