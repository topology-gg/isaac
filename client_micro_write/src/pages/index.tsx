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
  AdminGiveUndeployedDevice
} from '~/components/ServerInteraction'
import { TransactionList } from '~/components/TransactionList'
import { useServerContract } from '~/hooks/server'


const Home: NextPage = () => {
  const { account } = useStarknet()
  const { contract: serverContract } = useServerContract()

  //
  // read deployed-device emap
  //
  const { data: deviceDeployedEmapResult } = useStarknetCall({
    contract: serverContract,
    method: 'client_view_device_deployed_emap',
    args: [],
  })
  const deviceDeployedEmapValue = useMemo(() => {
    if (deviceDeployedEmapResult && deviceDeployedEmapResult.length > 0) {
      console.log("> Receiving valid deviceDeployedEmapResult[0]:", deviceDeployedEmapResult[0])

      const json = JSON.stringify(deviceDeployedEmapResult[0]);
      return json
    }
  }, [deviceDeployedEmapResult])

  //
  // read deployed-utb emap
  //
  const { data: utbDeployedEmapResult } = useStarknetCall({
    contract: serverContract,
    method: 'client_view_utb_deployed_emap',
    args: [],
  })
  const utbDeployedEmapValue = useMemo(() => {
    if (utbDeployedEmapResult && utbDeployedEmapResult.length > 0) {
      console.log("> Receiving valid utbDeployedEmapResult[0]:", utbDeployedEmapResult[0])

      const json = JSON.stringify(utbDeployedEmapResult[0]);
      return json
    }
  }, [utbDeployedEmapResult])

  //
  // read amount of undeployed device-type-2 owned
  //
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

  //
  // read amount of undeployed device-type-7 owned
  //
  const { data: deviceType7UndeployedAmountResult } = useStarknetCall({
    contract: serverContract,
    method: 'admin_read_device_undeployed_ledger',
    args: [account, 7],
  })
  const deviceType7UndeployedAmountValue = useMemo(() => {
    if (deviceType7UndeployedAmountResult && deviceType7UndeployedAmountResult.length > 0) {
      const value = toBN(deviceType7UndeployedAmountResult[0])
      return value.toString(10)
    }
  }, [deviceType7UndeployedAmountResult])

  //
  // read amount of undeployed utb (type 12) owned
  //
  const { data: utbUndeployedAmountResult } = useStarknetCall({
    contract: serverContract,
    method: 'admin_read_device_undeployed_ledger',
    args: [account, 12],
  })
  const utbUndeployedAmountValue = useMemo(() => {
    if (utbUndeployedAmountResult && utbUndeployedAmountResult.length > 0) {
      const value = toBN(utbUndeployedAmountResult[0])
      return value.toString(10)
    }
  }, [utbUndeployedAmountResult])

  //
  // read amount of undeployed device-type-14 owned
  //
  const { data: deviceType14UndeployedAmountResult } = useStarknetCall({
    contract: serverContract,
    method: 'admin_read_device_undeployed_ledger',
    args: [account, 14],
  })
  const deviceType14UndeployedAmountValue = useMemo(() => {
    if (deviceType14UndeployedAmountResult && deviceType14UndeployedAmountResult.length > 0) {
      const value = toBN(deviceType14UndeployedAmountResult[0])
      return value.toString(10)
    }
  }, [deviceType14UndeployedAmountResult])

  const { register: registerGive, handleSubmit: handleSubmitGive, formState: { errors: errorsGive } } = useForm();
  const { register: registerDD, handleSubmit: handleSubmitDD, formState: { errors: errorsDD } } = useForm();
  const { register: registerDP, handleSubmit: handleSubmitDP, formState: { errors: errorsDP } } = useForm();
  const { register: registerFW, handleSubmit: handleSubmitFW, formState: { errors: errorsFW } } = useForm();

  const { data, loading, error, reset, invoke:invokeDeviceDeploy } = useStarknetInvoke({
    contract: serverContract,
    method: 'client_deploy_device_by_grid',
  })
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
        {x : data['gridXRequired'], y : data['gridYRequired']}
       ] })
      console.log('submit device-deploy tx: ', data)
    }
  }

  const { invoke:invokeClientForwardWorld } = useStarknetInvoke({
    contract: serverContract,
    method: 'client_forward_world',
  })
  const onSubmitForwardWorld = (data: any) => {
    if (!account) {
      console.log('user wallet not connected yet.')
    }
    else if (!serverContract) {
      console.log('frontend not connected to server contract')
    }
    else {
      invokeClientForwardWorld ({ args: [] })
      console.log('submit client-forward-world tx')
    }
  }

  const { invoke:invokeUTBDeploy } = useStarknetInvoke({
    contract: serverContract,
    method: 'client_deploy_utb_by_grids',
  })
  const onSubmitTestDeployUTB = (data: any) => {
    if (!account) {
      console.log('user wallet not connected yet.')
    }
    else if (!serverContract) {
      console.log('frontend not connected to server contract')
    }
    else {
      invokeUTBDeploy ({ args: [
        {x:50, y:150}, {x:58, y:150},
        [
          {x:51, y:150},
          {x:52, y:150},
          {x:53, y:150},
          {x:54, y:150},
          {x:55, y:150},
          {x:56, y:150},
          {x:57, y:150}
        ]
      ] })
      console.log('submit utb-deploy tx')
    }
  }

  const { invoke:invokeAdminWriteDeviceUndeployedLedger } = useStarknetInvoke({
    contract: serverContract,
    method: 'admin_write_device_undeployed_ledger',
  })
  const onSubmitGiveSelfUndeployedDevice = (data: any) => {
    if (!account) {
      console.log('user wallet not connected yet.')
    }
    else if (!serverContract) {
      console.log('frontend not connected to server contract')
    }
    else {
      invokeAdminWriteDeviceUndeployedLedger ({ args: [
        account,
        data['typeRequired'],
        data['amountRequired'],
      ] })
      console.log('submit admin-write-device-undeployed-ledger tx')
    }
  }

  const { invoke:invokeClientPickupDeviceByGrid } = useStarknetInvoke({
    contract: serverContract,
    method: 'client_pickup_device_by_grid',
  })
  const onSubmitDevicePickup = (data: any) => {
    if (!account) {
      console.log('user wallet not connected yet.')
    }
    else if (!serverContract) {
      console.log('frontend not connected to server contract')
    }
    else {
      invokeClientPickupDeviceByGrid ({ args: [
        {x : data['gridXRequired'], y : data['gridYRequired']}
      ] })
      console.log('submit client_pickup_device_by_grid tx')
    }
  }

  return (
    <div>
      <h2>Wallet</h2>
      <ConnectWallet />
      <h2>Isaac's server contract</h2>
      <p>Address: {serverContract?.address}</p>

      <p>Device-deployed Emap: {deviceDeployedEmapValue}</p>
      <p>UTB-deployed Emap: {utbDeployedEmapValue}</p>

      <p>Device-type-2 undeployed ammount: {deviceType2UndeployedAmountValue}</p>
      <p>Device-type-7 undeployed ammount: {deviceType7UndeployedAmountValue}</p>
      <p>Device-type-12 undeployed ammount: {utbUndeployedAmountValue}</p>
      <p>Device-type-14 undeployed ammount: {deviceType14UndeployedAmountValue}</p>

      <form onSubmit={handleSubmitGive(onSubmitGiveSelfUndeployedDevice)}>
        <input type="submit" value="Give self undeployed device"/>
        <input defaultValue="type" {...registerGive("typeRequired", { required: true })} />
        {errorsGive.typeRequired && <span> (This field is required) </span>}
        <input defaultValue="amount" {...registerGive("amountRequired", { required: true })} />
        {errorsGive.amountRequired && <span> (This field is required) </span>}
      </form>

      <form onSubmit={handleSubmitDD(onSubmitDeviceDeploy)}>
        <input type="submit" value="Deploy device"/>
        <input defaultValue="device type" {...registerDD("deviceTypeRequired", { required: true })} />
        {errorsDD.deviceTypeRequired && <span> (This field is required) </span>}
        <input defaultValue="grid.x" {...registerDD("gridXRequired", { required: true })} />
        {errorsDD.gridXRequired && <span> (This field is required) </span>}
        <input defaultValue="grid.y" {...registerDD("gridYRequired", { required: true })} />
        {errorsDD.gridYRequired && <span> (This field is required) </span>}
      </form>

      <form onSubmit={handleSubmitDP(onSubmitDevicePickup)}>
        <input type="submit" value="Pickup device"/>
        <input defaultValue="grid.x" {...registerDP("gridXRequired", { required: true })} />
        {errorsDP.gridXRequired && <span> (This field is required) </span>}
        <input defaultValue="grid.y" {...registerDP("gridYRequired", { required: true })} />
        {errorsDP.gridYRequired && <span> (This field is required) </span>}
      </form>

      <form onSubmit={handleSubmitFW(onSubmitTestDeployUTB)}>
        <input type="submit" value="UTB from (51,150) to (57,150) connecting (50,150) with (58,150)"/>
      </form>

      <form onSubmit={handleSubmitFW(onSubmitForwardWorld)}>
        <input type="submit" value="Forward world"/>
      </form>

      <h2>Recent Transactions</h2>
      <TransactionList />
    </div>
  )
}

export default Home
