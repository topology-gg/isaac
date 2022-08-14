import React, { Component, useState } from "react";
import styles from "../styles/Modal.module.css";

import { DEVICE_TYPE_MAP } from './ConstantDeviceTypes'
import { MANUFACTURING_REQUIREMENT } from './ConstantManufacturingRequirement'

import { DeployDeviceInterface } from './ActionDeployDevice'
import { PickupDeviceInterface } from './ActionPickupDevice'
import { PickupUtxInterface } from './ActionPickupUtx'
import { DeployUtxInterface } from './ActionDeployUtx'
import { BuildDeviceInterface } from './ActionBuildDevice'
import { LaunchNdpeInterface } from './ActionLaunchNdpe'
import { TransferDeviceInterface } from './ActionTransferDevice'

// Refs:
// https://stackoverflow.com/questions/54880669/react-domexception-failed-to-execute-removechild-on-node-the-node-to-be-re
// https://stackoverflow.com/questions/54276832/react-how-to-display-a-modal-popup-only-for-that-specific-div
// https://stackoverflow.com/questions/24502898/show-or-hide-element-in-react
// https://medium.com/@ralph1786/using-css-modules-in-react-app-c2079eadbb87

export function Modal (props) {

    //
    // Build information to be shown in popup window
    //
    const info = props.info
    var title = ""
    var grids = ""
    var display_left_top = null
    var display_left_bottom = null
    var options = []
    var bool_display_left_bottom = true

    const [hoverDevice, setHoverDevice] = useState ('-')

    var thead = [
        <th key='resource' style={{textAlign:'left',paddingLeft:'0'}}>Resource</th>,
        <th key='balance' style={{textAlign:'left',paddingLeft:'3em'}}>Balance</th>
    ]

    if (!info['grids']) {
        //
        // transfer device
        //
        title += "Transfer device peer-to-peer"
        grids = ""
        options.push (<TransferDeviceInterface />)
    }
    else {
        //
        // Multiple grid selected
        //
        if (info['grids'].length > 1) {
            title = `Selected ${info['grids'].length} grids:`
            for (const grid of info['grids']) {
                grids += `(${grid.x},${grid.y})`
            }

            options.push (<DeployUtxInterface grids={info['grids']} type={12}/>)
            options.push (<DeployUtxInterface grids={info['grids']} type={13}/>)
        }

        //
        // Single grid selected
        //
        else {
            title += "Selected 1 grid:"
            const grid = info['grids'][0]
            const grid_str = `(${grid.x},${grid.y})`
            const grid_mapping = props.gridMapping
            grids += grid_str

            //
            // Gather information about this grid;
            // construct option
            //
            var content1 = ''
            var content2 = ''
            if (grid_str in grid_mapping) {
                const grid_info = grid_mapping [grid_str]

                const owner = grid_info ['owner']
                const typ   = DEVICE_TYPE_MAP [grid_info ['type']]
                const balances = grid_info ['balances']

                content1 += `Device type: ${typ}\n`
                content2 += `Owner: ${owner}`

                const CELL_HEIGHT = '2em'
                var tbody = []
                const requirement = MANUFACTURING_REQUIREMENT [hoverDevice]
                if (balances) {
                    for (var key of Object.keys(balances)) {

                        if (! ['SPG', 'NPG', 'UPSF', 'NDPE'].includes(typ)) { // only these types need to display energy balance
                            if (key === 'energy') {
                                continue;
                            }
                        }

                        var cell = []
                        cell.push (<td key={`manufacture-key-${key}`} style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'0'}}>{key}</td>)
                        cell.push (<td key={`manufacture-balance-${key}`} style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'3em'}}>{balances[key]}</td>)

                        if (['UPSF'].includes(typ)) { // only UPSF needs to display manufacture requirement info
                            if (hoverDevice == '-') {
                                cell.push (<td key={`dash-${key}`} style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'3em'}}>{'-'}</td>)
                            }
                            else {
                                //
                                // use hoverDevice to pull in resource & energy requirement
                                //
                                const requirement_color = balances[key] >= requirement[key] ? '#333333' : '#C34723'
                                cell.push (<td key={`manufacture-requirement-${key}`} style={{
                                    height:CELL_HEIGHT,
                                    textAlign:'left',
                                    paddingLeft:'3em',
                                    color:requirement_color
                                }}>{requirement[key]}</td>)
                            }
                        }

                        tbody.push (<tr key={key}>{cell}</tr>)
                    }
                }

                //
                // Generate options - actions to be performed by player
                //

                if (['UTB', 'UTL'].includes(typ)) {
                    bool_display_left_bottom = false
                    options.push (<PickupUtxInterface grid_x={grid.x} grid_y={grid.y} typ={typ}/>)
                }
                else {
                    options.push (<PickupDeviceInterface grid_x={grid.x} grid_y={grid.y} typ={typ}/>)
                }

                if (balances && ['UPSF'].includes(typ)) {

                    var thead = [
                        <th key='upsf-resource' style={{textAlign:'left',paddingLeft:'0'}}>Resource</th>,
                        <th key='upsf-balance' style={{textAlign:'left',paddingLeft:'3em'}}>Balance</th>,
                        <th key='upsf-requirement' style={{textAlign:'left',paddingLeft:'3em'}}>Requirement</th>
                    ]

                    //
                    // Construct can_build for each device type
                    //
                    for (const i=0; i<16; i++){ // iterate over all device types
                        var can_build = true
                        for (var key of Object.keys(balances)) {
                            const have = balances[key]
                            const need = MANUFACTURING_REQUIREMENT[i][key]
                            if (have < need) {
                                can_build = false
                            }
                        }

                        options.push (
                            <BuildDeviceInterface typ={i} grid_x={grid.x} grid_y={grid.y} can_build={can_build} setHoverDeviceCallback={setHoverDevice} />
                        )
                    }

                }
                else if (['NDPE'].includes(typ)) {
                    options.push (
                        <LaunchNdpeInterface grid_x={grid.x} grid_y={grid.y} />
                    )
                }
            }
            else {
                content1 += "Grid not populated"
                bool_display_left_bottom = false

                for (const i=0; i<16; i++) {
                    if ([12,13].includes(i)) { continue; }

                    const have_nonzero_balance = props.device_balance[i] > 0 ? true : false
                    // console.log (`device type ${i} have_nonzero_balance=${have_nonzero_balance}`)

                    options.push (
                        <DeployDeviceInterface typ={i} grid_x={grid.x} grid_y={grid.y} have_nonzero_balance={have_nonzero_balance}/>
                    )
                }
            }

            //
            // Construct displayed information
            //
            display_left_top =
                <div>
                    <h3>Info</h3>
                    <p style={{fontSize:"0.9em"}}>{content1}</p>
                    <p style={{fontSize:"0.9em"}}>{content2}</p>
                </div>

            display_left_bottom =
                bool_display_left_bottom && (
                    <div>
                        <table style={{fontSize:"0.9em"}}>
                            <thead>
                                <tr>
                                    {thead}
                                </tr>
                            </thead>
                            <tbody>
                                {tbody}
                            </tbody>
                        </table>
                    </div>
                )

        }
    }

    var options_gated = []
    if (!props.account) {
        options_gated.push (<p key='no-account-signed'>no account signed in</p>)
    }
    else if (!props.in_civ) {
        options_gated.push (<p key='account-not-in-civ'>account not in this civilization</p>)
    }
    else {
        options_gated = options
    }

    const modal_left_child_style = {
        display: 'flex',
        flexDirection: 'column',
        paddingLeft: '0.6em',
        width: '20em'
    }

    const modal_right_child_style = {
        display: 'flex',
        order: 1,
        flexDirection: 'column',
        marginLeft: '2em',
        fontSize: '1em'
    }

    return (
        <div style={{display:'flex'}}>
            { props.show ?

            <div className={styles.modal}>

                <div style={modal_left_child_style}>
                    <h3>{title}</h3>
                    <p style={{fontSize:"0.9em",margin:'0'}}>{grids}</p>

                    {display_left_top}
                    {display_left_bottom}

                    <span>.</span>

                    <button onClick={props.onHide} style={{width:'fit-content'}} className='action-button'>
                        Esc
                    </button>
                </div>

                <div style={modal_right_child_style}>
                    <h3>Options:</h3>

                    {options_gated}

                </div>

            </div>

            : null }
        </div>
    );
}
