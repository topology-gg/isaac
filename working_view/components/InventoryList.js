import React, { Component, useState, useEffect } from "react";
import { useForm } from "react-hook-form";
import { toBN } from 'starknet/dist/utils/number'
import {
    StarknetProvider,
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core'

import { abbrevDecString } from '../lib/helpers/feltAbbreviator';
import {
    usePlayerFungibleBalancesByAccount,
    usePlayerNonfungibleDevicesByAccount,
    usePgs,
    useHarvesters,
    useTransformers,
    useUpsfs,
    useNdpes
} from '../lib/api'
import { DEVICE_TYPE_FULL_NAME_MAP } from './ConstantDeviceTypes';
import { DEVICE_RESOURCE_MAP } from './ConstantDeviceResources'
import { useUniverseContract } from "./UniverseContract";
import DEVICE_DIM_MAP from "./ConstantDeviceDimMap";
import { DEVICE_COLOR_MAP } from "./ConstantDeviceColors";

const nonfungible_types = [0,1,2,3,4,5,6,7,8,9,10,11,14,15]

export function InventoryList ({ onDeployDevice, onDeployUtx, inCiv }) {

    const { account, connect } = useStarknet ()
    const account_str_decimal = toBN(account).toString(10)
    // const { contract } = useUniverseContract ()

    // React states
    const [viewingType, setViewingType] = useState (0)
    const [viewingId, setViewingId] = useState ('0')
    const [leftView, setLeftView] = useState ('')
    const [midView, setMidView] = useState ('')
    const [rightView, setRightView] = useState ('')

    // DBs
    const { data: db_player_nonfungible_devices } = usePlayerNonfungibleDevicesByAccount (account_str_decimal)
    const { data: db_player_fungible_balances } = usePlayerFungibleBalancesByAccount (account_str_decimal)
    const { data: db_pgs } = usePgs ()
    const { data: db_harvesters } = useHarvesters ()
    const { data: db_transformers } = useTransformers ()
    const { data: db_upsfs } = useUpsfs ()
    const { data: db_ndpes } = useNdpes ()

    const handleDeployDevice = (device) => {
        onDeployDevice({
                id: device.id,
                type: device.type,
                dimension: DEVICE_DIM_MAP.get(device.type),
                color: DEVICE_COLOR_MAP.get(device.type),
            })
    }

    useEffect (() => {

        if (!account) {
            setLeftView (<p key='inventory-no-account-signed'>no account signed in</p>)
        }
        else if (!inCiv) {
            setLeftView (<p key='inventory-account-not-in-civ'>account not in this civilization</p>)
        }
        else if (
            !db_player_nonfungible_devices || !db_player_fungible_balances ||
            !db_pgs || !db_harvesters || !db_transformers || !db_upsfs || !db_ndpes
        ) {
            setLeftView (<div>db loading ...</div>)
        }
        else {
            console.log ("HEYYYYY")
            //
            // Create left view
            //
            const fungible_balances = db_player_fungible_balances.player_fungible_balances [0]
            const belt_balance = fungible_balances[12] || 0
            const wire_balance = fungible_balances[13] || 0

            const nonfungible_counts = {}
            for (var typ of nonfungible_types) {
                const count = db_player_nonfungible_devices.player_nonfungible_devices.filter (
                    ele => (ele.is_deployed == false) && (ele.type == typ)
                ).length
                nonfungible_counts [typ] = count
            }


            setLeftView (
                <div style={{display:'flex',flexDirection:'column'}}>
                    <h5>Non-fungible</h5>
                    {
                        nonfungible_types.map ((ele, idx) =>
                            <button
                                key = {`type-button-${idx}`}
                                className = {`inventory-button ${ele==viewingType ? 'button-active' : ''} ${nonfungible_counts[ele] ? 'action-button' : 'disabled-button'}`}
                                disabled = { !nonfungible_counts[ele] }
                                onClick = { () => {setViewingType(ele)} }
                            >
                                <span className="inventory-device-type">{DEVICE_TYPE_FULL_NAME_MAP[ele]}</span>
                                <span className="inventory-device-count">{nonfungible_counts[ele]}</span>
                            </button>
                        )
                    }
                    <h5 style={{marginTop:'20px'}}>Fungible</h5>
                    <p style={{margin:'0'}}>Belt x {belt_balance}</p>
                    {belt_balance > 0 && (
                        <button
                            className={`inventory-device-button`}
                            onClick={() => onDeployUtx(12)}
                        >
                            Deploy Belt
                        </button>
                    )}
                    <p style={{ margin: "0" }}>Wire x {wire_balance}</p>
                    {wire_balance > 0 && (
                        <button
                            className={`inventory-device-button`}
                            onClick={() => onDeployUtx(13)}
                        >
                            Deploy Wire
                        </button>
                    )}
                </div>
            )

            //
            // Create mid view
            //
            setMidView (
                <div className="inventory-devices-list">
                    {
                        db_player_nonfungible_devices.player_nonfungible_devices.filter (
                            ele =>(ele.is_deployed == false) && (ele.type == viewingType)
                        ).map((ele, idx) =>
                            // <tr key={`nonfungible_device-row-${idx}`} className="nonfungible_device">
                            //     <td key={`nonfungible-device-id-${idx}`}>{ abbrevDecString(ele.id) }</td>
                            //     <td key={`nonfungible-device-deployed-${idx}`}>{ ele.is_deployed ? 1 : 0 }</td>
                            // </tr>
                            <button
                                key = {`nonfungible_device-button-${idx}`}
                                className = {`inventory-device-button ${ele.id === viewingId ? 'button-active' : ''}`}
                                onClick = { () => {setViewingId(ele.id)} }
                            >
                                <div>{ DEVICE_TYPE_FULL_NAME_MAP[ele.type] }</div>
                                <div className="inventory-device-id">{ abbrevDecString(ele.id) }</div>
                            </button>
                        )
                    }
                </div>
            )

            //
            // Create right view
            //
            if (viewingId != '0') {

                const deviceInfo = []

                const device = db_player_nonfungible_devices.player_nonfungible_devices.filter (
                    ele => ele.id == viewingId
                )[0]
                const device_type = device.type
                deviceInfo.push (<h4 key='device-type-title'>{DEVICE_TYPE_FULL_NAME_MAP[device_type]}</h4>)
                deviceInfo.push (<p key='device-id-subtitle'>&lt; Id = {abbrevDecString(viewingId)} &gt;</p>)

                if ([0,1].includes(device_type)) {
                    const pg = db_pgs.pgs.filter (
                        ele => ele.id == viewingId
                    )[0]
                    deviceInfo.push (<p key='device-energy'>Energy: {pg.energy}</p>)
                }
                else if ([2,3,4,5,6].includes(device_type)) {
                    const harvester = db_harvesters.harvesters.filter (
                        ele => ele.id == viewingId
                    )[0]
                    const resource_name = DEVICE_RESOURCE_MAP [ parseInt(harvester.type) ]
                    deviceInfo.push (<p key='device-resource'>{resource_name}: {harvester.resource}</p>)
                    deviceInfo.push (<p key='device-energy'>Energy: {harvester.energy}</p>)
                }
                else if ([7,8,9,10,11].includes(device_type)) {
                    const transformer = db_transformers.transformers.filter (
                        ele => ele.id == viewingId
                    )[0]
                    const resource_names = DEVICE_RESOURCE_MAP [ parseInt(transformer.type) ]
                    deviceInfo.push (<p>{resource_names.pre}: {transformer.resource_pre}</p>)
                    deviceInfo.push (<p>{resource_names.post}: {transformer.resource_post}</p>)
                    deviceInfo.push (<p>Energy: {transformer.energy}</p>)
                }
                else if (device_type == 14) { // Factory
                    const upsf = db_upsfs.upsfs.filter (
                        ele => ele.id == viewingId
                    )[0]
                    deviceInfo.push (<p>Fe Raw: {upsf.resource_0}</p>)
                    deviceInfo.push (<p>Al Raw: {upsf.resource_2}</p>)
                    deviceInfo.push (<p>Cu Raw: {upsf.resource_4}</p>)
                    deviceInfo.push (<p>Si Raw: {upsf.resource_6}</p>)
                    deviceInfo.push (<p>Pu Raw: {upsf.resource_8}</p>)
                    deviceInfo.push (<p>Fe Refined: {upsf.resource_1}</p>)
                    deviceInfo.push (<p>Al Refined: {upsf.resource_3}</p>)
                    deviceInfo.push (<p>Cu Refined: {upsf.resource_5}</p>)
                    deviceInfo.push (<p>Si Refined: {upsf.resource_7}</p>)
                    deviceInfo.push (<p>Pu Refined: {upsf.resource_9}</p>)
                }
                else if (device_type == 15) { // Engine
                    const ndpe = db_ndpes.ndpes.filter (
                        ele => ele.id == viewingId
                    )[0]
                    deviceInfo.push (<p>Energy: {ndpe.energy}</p>)
                }

                setRightView (
                    <div>
                        {deviceInfo}
                        <button
                            className="action-button inventory-device-button"
                            onClick = { () => handleDeployDevice(device) }
                        >Deploy Device</button>
                    </div>
                )
            }
        }



    }, [account, viewingId, viewingType,
        db_player_nonfungible_devices, db_player_fungible_balances, db_pgs, db_harvesters,
        db_transformers, db_upsfs, db_ndpes])


    return (
        <div style={{display:'flex',flexDirection:'row',width:'100%',height:'85%'}}>
            <div className="inventory-left-view">
                {leftView}
            </div>

            <div className="inventory-mid-view">
                {midView}
            </div>

            <div className="inventory-right-view">
                {rightView}
            </div>

        </div>
    );
}
