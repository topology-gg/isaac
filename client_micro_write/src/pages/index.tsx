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
    method: 'client_view_utx_deployed_emap',
    args: [12],
  })
  const utbDeployedEmapValue = useMemo(() => {
    if (utbDeployedEmapResult && utbDeployedEmapResult.length > 0) {
      console.log("> Receiving valid utxDeployedEmapResult[0]:", utbDeployedEmapResult[0])

      const json = JSON.stringify(utbDeployedEmapResult[0]);
      return json
    }
  }, [utbDeployedEmapResult])

  //
  // read deployed-utl emap
  //
  const { data: utlDeployedEmapResult } = useStarknetCall({
    contract: serverContract,
    method: 'client_view_utx_deployed_emap',
    args: [13],
  })
  const utlDeployedEmapValue = useMemo(() => {
    if (utlDeployedEmapResult && utlDeployedEmapResult.length > 0) {
      console.log("> Receiving valid utxDeployedEmapResult[0]:", utlDeployedEmapResult[0])

      const json = JSON.stringify(utlDeployedEmapResult[0]);
      return json
    }
  }, [utlDeployedEmapResult])

  //
  // read amount of undeployed device-type-0 owned
  //
  const { data: deviceType0UndeployedAmountResult } = useStarknetCall({
    contract: serverContract,
    method: 'admin_read_device_undeployed_ledger',
    args: [account, 0],
  })
  const deviceType0UndeployedAmountValue = useMemo(() => {
    if (deviceType0UndeployedAmountResult && deviceType0UndeployedAmountResult.length > 0) {
      const value = toBN(deviceType0UndeployedAmountResult[0])
      return value.toString(10)
    }
  }, [deviceType0UndeployedAmountResult])

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
  // read amount of undeployed utb (type 12) owned
  //
  const { data: utlUndeployedAmountResult } = useStarknetCall({
    contract: serverContract,
    method: 'admin_read_device_undeployed_ledger',
    args: [account, 13],
  })
  const utlUndeployedAmountValue = useMemo(() => {
    if (utlUndeployedAmountResult && utlUndeployedAmountResult.length > 0) {
      const value = toBN(utlUndeployedAmountResult[0])
      return value.toString(10)
    }
  }, [utlUndeployedAmountResult])

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
    method: 'executeTask'
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
      <h2>ISAAC</h2>
      <ConnectWallet />

      <h3>Contract interaction</h3>
      <p>Address: {serverContract?.address}</p>

      {/* <p>Address of multi_deploy.cairo:
        <a href="https://goerli.voyager.online/contract/0x063cfb28813ffdbce2fbb6979404b7902dfbe560989dc90f99fb37575629bdb1" target="_blank">
          0x063cfb28813ffdbce2fbb6979404b7902dfbe560989dc90f99fb37575629bdb1
        </a>
      </p> */}

      <form onSubmit={handleSubmitGive(onSubmitGiveSelfUndeployedDevice)}>
        <input type="submit" value="Give yourself undeployed device"/>
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

      <form onSubmit={handleSubmitFW(onSubmitForwardWorld)}>
        <input type="submit" value="Forward world"/>
      </form>

      <h3>Recent Transactions</h3>
      <TransactionList />

      <h3>Viewing your undeployed device balance in contract</h3>
      <p>Solar Power Generator (device-type-0) undeployed ammount: {deviceType0UndeployedAmountValue}</p>
      <p>FE Harvester (device-type-2) undeployed ammount: {deviceType2UndeployedAmountValue}</p>
      <p>FE Refinery (evice-type-7) undeployed ammount: {deviceType7UndeployedAmountValue}</p>
      <p>UTB (device-type-12) undeployed ammount: {utbUndeployedAmountValue}</p>
      <p>UTL (device-type-13) undeployed ammount: {utlUndeployedAmountValue}</p>
      <p>OPSF (device-type-14) undeployed ammount: {deviceType14UndeployedAmountValue}</p>

      <h3>Viewing global enumerable maps in contract</h3>
      <p>Device-deployed enumerable-map: {deviceDeployedEmapValue}</p>
      <p>UTB-deployed enumerable-map: {utbDeployedEmapValue}</p>
      <p>UTL-deployed enumerable-map: {utlDeployedEmapValue}</p>

    </div>
  )
}

export default Home
