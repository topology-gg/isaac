import {
  useStarknet,
  useContract,
  useStarknetCall,
  useStarknetInvoke
} from '@starknet-react/core'
import { Abi } from 'starknet'
import type { NextPage } from 'next'
import { useMemo } from 'react'
import { useForm } from "react-hook-form";
import { toBN } from 'starknet/dist/utils/number'
import { ConnectWallet } from '~/components/ConnectWallet'
import {
  InvokeDeployDevice,
  AdminGiveUndeployedDevice
} from '~/components/ServerInteraction'
import { TransactionList } from '~/components/TransactionList'

import ServerAbi from '~/abi/server_abi.json'
function useServerContract() {
  return useContract({
    abi: ServerAbi as Abi,
    address: '0x0717a903232a851dec3158e723750fc8a50a03afbdf7ad92f89558602c163a27',
  })
}

const Home: NextPage = () => {
  const { account } = useStarknet()
  const { contract: serverContract } = useServerContract()

  const { data: deviceDeployedEmapResult } = useStarknetCall({
    contract: serverContract,
    method: 'client_view_device_deployed_emap',
    args: [],
  })
  const deviceDeployedEmapValue = useMemo(() => {
    if (deviceDeployedEmapResult && deviceDeployedEmapResult.length > 0) {
      const value = toBN(deviceDeployedEmapResult[0])
      return value.toString(10)
    }
  }, [deviceDeployedEmapResult])
  console.log ("deviceDeployedEmapValue", deviceDeployedEmapValue)

  const { data: deviceType2UndeployedAmountResult } = useStarknetCall({
    contract: serverContract,
    method: 'admin_read_device_undeployed_ledger',
    args: [account, 2],
  })
  const deviceType2UndeployedAmountValue = useMemo(() => {
    if (deviceType2UndeployedAmountResult && deviceType2UndeployedAmountResult.length > 0) {
      const value = toBN(deviceType2UndeployedAmountResult[0])
      return value.toString(10)
    }
  }, [deviceType2UndeployedAmountResult])

  const { data, loading, error, reset, invoke:invokeDeviceDeploy } = useStarknetInvoke({
    contract: serverContract,
    method: 'client_deploy_device_by_grid',
  })
  const { register, handleSubmit, watch, formState: { errors } } = useForm();
  const onSubmitDeviceDeploy = (data: any) => {
    if (!account) {
      console.log('user wallet not connected yet.')
    }
    else if (!serverContract) {
      console.log('frontend not connected to server contract')
    }
    else {
      invokeDeviceDeploy ({ args: [
        data['deviceTypeRequired'],
        { x : data['gridXRequired'],y : data['gridYRequired']}
       ] })
      console.log('submit device-deploy tx: ', data)
    }
  }

  return (
    <div>
      <h2>Wallet</h2>
      <ConnectWallet />
      <h2>Isaac's server contract</h2>
      <p>Address: {serverContract?.address}</p>
      <p>Device-deployed Emap: {deviceDeployedEmapValue}</p>
      <p>Device-type-2 undeployed ammount: {deviceType2UndeployedAmountValue}</p>

      <AdminGiveUndeployedDevice />
      <InvokeDeployDevice />

      <form onSubmit={handleSubmit(onSubmitDeviceDeploy)}>
        <input defaultValue="device type" {...register("deviceTypeRequired", { required: true })} />
        {errors.deviceTypeRequired && <span> (This field is required) </span>}

        <input defaultValue="grid.x" {...register("gridXRequired", { required: true })} />
        {errors.gridXRequired && <span> (This field is required) </span>}

        <input defaultValue="grid.y" {...register("gridYRequired", { required: true })} />
        {errors.gridYRequired && <span> (This field is required) </span>}

        <input type="submit" value="Deploy device"/>
      </form>

      <h2>Recent Transactions</h2>
      <TransactionList />
    </div>
  )
}

export default Home
