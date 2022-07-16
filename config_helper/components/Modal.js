import React, { Component } from "react";
import styles from "../styles/Modal.module.css";
import { useS2m2Contract } from "./S2m2Contract";

class Modal extends Component {

    render() {

        const selected_grids = this.props.info.grids

        const { contract } = useS2m2Contract ()
        const { data, loading, error, reset, invoke } = useStarknetInvoke ({
            contract,
            method: 'solved'
        })

        function onClick () {
            console.log (`solution submitting! ${5}`)
            const arr_cell_indices_len = len (selected_grids)
            var arr_cell_indices = []
            for (const grid of selected_grids) {
                arr_cell_indices.push (grid.y*8 + grid.x)
            }
            invoke ({ args: [puzzle_id, arr_cell_indices_len].concat(arr_cell_indices) })
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

        var display_grids = ''
        if (selected_grids[0]) {
            for (const grid of selected_grids) {
                display_grids += `${grid.y*8 + grid.x} → `
            }
            display_grids += `${selected_grids[0].y*8 + selected_grids[0].x}`
        }


        return (
            <div style={{display:'flex',alignItems:'center',justifyContent:'center'}}>

                { this.props.show ?
                    <div className={styles.modal}>

                        <p>Submitting: {display_grids}</p>

                        <button onClick={onClick} style={{width:'fit-content'}} className='action-button'>
                            let's go
                        </button>

                    </div>
                : null }

            </div>
        )

    //
    // Build information to be shown in popup window
    //
    // const info = this.props.info
    // var title = ""
    // var grids = ""
    // var display_left_top = null
    // var display_left_bottom = null
    // var options = []
    // var bool_display_left_bottom = true

    // if (!info['grids']) {
    //     //
    //     // transfer device
    //     //
    //     title += "Transfer device peer-to-peer"
    //     grids = ""
    //     options.push (<TransferDeviceInterface />)
    // }
    // else {
    //     //
    //     // Multiple grid selected
    //     //
    //     if (info['grids'].length > 1) {
    //         title = `Selected ${info['grids'].length} grids:`
    //         for (const grid of info['grids']) {
    //             grids += `(${grid.x},${grid.y})`
    //         }

    //         options.push (<DeployUtxInterface grids={info['grids']} type={12}/>)
    //         options.push (<DeployUtxInterface grids={info['grids']} type={13}/>)
    //     }

    //     //
    //     // Single grid selected
    //     //
    //     else {
    //         title += "Selected 1 grid:"
    //         const grid = info['grids'][0]
    //         const grid_str = `(${grid.x},${grid.y})`
    //         const grid_mapping = this.props.gridMapping
    //         grids += grid_str

    //         //
    //         // Gather information about this grid;
    //         // construct option
    //         //
    //         var content1 = ''
    //         var content2 = []
    //         if (grid_str in grid_mapping) {
    //             const grid_info = grid_mapping [grid_str]

    //             const owner = grid_info ['owner']
    //             const typ   = DEVICE_TYPE_MAP [grid_info ['type']]
    //             const balances = grid_info ['balances']

    //             content1 += `Device type: ${typ}; `
    //             content1 += `Owner: ${owner}`

    //             const CELL_HEIGHT = '2em'
    //             var tbody = []
    //             for (var key of Object.keys(balances)) {
    //                 var cell = []
    //                 cell.push (<td style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'0'}}>{key}</td>)
    //                 cell.push (<td style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'0.6em'}}>{balances[key]}</td>)
    //                 tbody.push (<tr>{cell}</tr>)
    //             }

    //             //
    //             // Generate options - actions to be performed by player
    //             //

    //             if (['UTB', 'UTL'].includes(typ)) {
    //                 bool_display_left_bottom = false
    //                 options.push (<PickupUtxInterface grid_x={grid.x} grid_y={grid.y} typ={typ}/>)
    //             }
    //             else {
    //                 options.push (<PickupDeviceInterface grid_x={grid.x} grid_y={grid.y} typ={typ}/>)
    //             }

    //             if (['UPSF'].includes(typ)) {
    //                 for (const i=0; i<16; i++) {
    //                     options.push (
    //                         <BuildDeviceInterface typ={i} grid_x={grid.x} grid_y={grid.y} />
    //                     )
    //                 }
    //             }
    //             else if (['NDPE'].includes(typ)) {
    //                 options.push (
    //                     <LaunchNdpeInterface grid_x={grid.x} grid_y={grid.y} />
    //                 )
    //             }
    //         }
    //         else {
    //             content1 += "Grid not populated"
    //             bool_display_left_bottom = false

    //             for (const i=0; i<16; i++) {
    //                 if ([12,13].includes(i)) { continue; }
    //                 options.push (
    //                     <DeployDeviceInterface typ={i} grid_x={grid.x} grid_y={grid.y} />
    //                 )
    //             }
    //         }

    //         //
    //         // Construct displayed information
    //         //
    //         display_left_top =
    //             <div>
    //                 <h3>Info</h3>
    //                 <p style={{fontSize:"0.9em"}}>{content1}</p>
    //             </div>

    //         display_left_bottom =
    //             bool_display_left_bottom && (
    //                 <div>
    //                     <table style={{fontSize:"0.9em"}}>
    //                         <thead>
    //                             <tr>
    //                                 <th style={{textAlign:'left',paddingLeft:'0'}}>Resource</th>
    //                                 <th>Balance</th>
    //                             </tr>
    //                         </thead>
    //                         <tbody>
    //                             {tbody}
    //                         </tbody>
    //                     </table>
    //                 </div>
    //             )

    //     }
    // }

    // var options_gated = []
    // if (!this.props.account) {
    //     options_gated.push (<p>no account signed in</p>)
    // }
    // else if (!this.props.in_civ) {
    //     options_gated.push (<p>account not in this civilization</p>)
    // }
    // else {
    //     options_gated = options
    // }

    // const modal_left_child_style = {
    //     display: 'flex',
    //     flexDirection: 'column',
    //     paddingLeft: '0.6em',
    //     width: '20em'
    // }

    // const modal_right_child_style = {
    //     display: 'flex',
    //     order: 1,
    //     flexDirection: 'column',
    //     marginLeft: '2em',
    //     fontSize: '1em'
    // }

    // return (
    //     <div style={{display:'flex'}}>
    //         { this.props.show ?

    //         <div className={styles.modal}>

    //             <div style={modal_left_child_style}>
    //                 <h3>{title}</h3>
    //                 <p style={{fontSize:"0.9em",margin:'0'}}>{grids}</p>

    //                 {display_left_top}
    //                 {display_left_bottom}

    //                 <span>.</span>

    //                 <button onClick={this.props.onHide} style={{width:'fit-content'}} className='action-button'>
    //                     Esc
    //                 </button>
    //             </div>

    //             <div style={modal_right_child_style}>
    //                 <h3>Options:</h3>

    //                 {options_gated}

    //             </div>

    //         </div>

    //         : null }
    //     </div>
    // );
    }
}


export default Modal;
