import { useStarknet, useStarknetInvoke } from '@starknet-react/core'
import React from 'react'
import { useServerContract } from '~/hooks/server'

// export function InvokeDeployDevice() {
//   const { account } = useStarknet()
//   const { contract: serverContract } = useServerContract()
//   const { invoke } = useStarknetInvoke({ contract: serverContract, method: 'client_deploy_device_by_grid' })

//   if (!account) {
//     return null
//   }

//   return (
//     <div>
//       <button onClick={() => invoke({ args: [2, {x : 50, y : 50}] })}>Deploy device of type 2 at grid (50,50)</button>
//     </div>
//   )
// }


export function AdminGiveUndeployedDevice() {
  const { account } = useStarknet()
  const { contract: serverContract } = useServerContract()
  const { invoke } = useStarknetInvoke({ contract: serverContract, method: 'admin_write_device_undeployed_ledger' })

  if (!account) {
    return null
  }

  return (
    <div>
      <button onClick={() => invoke(
        { args: [account, 2, 100] }
        )}>Give 100 devices of type 2 to {account}</button>
    </div>
  )
}
