import {
  useStarknet,
  InjectedConnector
} from '@starknet-react/core'

export function ConnectWallet() {
  const { account, connect } = useStarknet()

  if (account) {
    return <p>Account: {account}</p>
  }

  return (
    <div>
      <div>
        <p>Connected Account: {account}</p>
      </div>
      {InjectedConnector.ready() ? (
          <button onClick={() => connect(new InjectedConnector())}>Connect Argent-X</button>
      ) : (
        <div>
          <p>
            <a href="https://github.com/argentlabs/argent-x">Download Argent-X</a>
          </p>
        </div>
      )}
    </div>
  )

}
