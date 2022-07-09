import React, { Component } from "react";
import styles from "../styles/Modal.module.css";

import { DEVICE_TYPE_MAP } from './ConstantDeviceTypes'

// import { addAddressPadding } from "starknet";

// Refs:
// https://stackoverflow.com/questions/54880669/react-domexception-failed-to-execute-removechild-on-node-the-node-to-be-re
// https://stackoverflow.com/questions/54276832/react-how-to-display-a-modal-popup-only-for-that-specific-div
// https://stackoverflow.com/questions/24502898/show-or-hide-element-in-react
// https://medium.com/@ralph1786/using-css-modules-in-react-app-c2079eadbb87

const button_style = {
    fontSize:'12px',
    marginBottom:'5px',
    paddingTop:'5px',
    paddingBottom:'5px',
    paddingLeft:'30px',
    paddingRight:'30px',
    lineHeight:'15px'
}

class Modal extends Component {

  render() {

    //
    // Build information to be shown in popup window
    //
    const info = this.props.info
    var title = ""
    var grids = ""
    var display_info
    var options = []

    if (info['grids']) {

        //
        // Multiple grid selected
        //
        if (info['grids'].length > 1) {
            title = `Selected ${info['grids'].length} grids:`
            for (const grid of info['grids']) {
                grids += `(${grid.x},${grid.y})`
            }

            display_info = null
            options.push (<button>Deploy utx</button>)
        }
        //
        // Single grid selected
        //
        else {
            title += "Selected 1 grid:"
            const grid = info['grids'][0]
            const grid_str = `(${grid.x},${grid.y})`
            const grid_mapping = this.props.gridMapping
            grids += grid_str

            //
            // Gather information about this grid;
            // construct option
            //
            var content1 = ''
            var content2 = []
            if (grid_str in grid_mapping) {
                const grid_info = grid_mapping [grid_str]

                const owner = grid_info ['owner']
                const typ   = DEVICE_TYPE_MAP [grid_info ['type']]
                const balances = grid_info ['balances']

                content1 += `Device type: ${typ}; `
                content1 += `Owner: ${owner}`

                const CELL_HEIGHT = '2em'
                var tbody = []
                for (var key of Object.keys(balances)) {
                    var cell = []
                    cell.push (<td style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'0'}}>{key}</td>)
                    cell.push (<td style={{height:CELL_HEIGHT,textAlign:'left',paddingLeft:'0.6em'}}>{balances[key]}</td>)
                    tbody.push (<tr>{cell}</tr>)
                }

                options.push (<button style={button_style}>Pick up {typ}</button>)
                if (['UPSF'].includes(typ)) {
                    for (const i=0; i<16; i++) {
                        options.push (<button style={button_style}>Construct {DEVICE_TYPE_MAP [i]}</button>)
                    }
                }
                else if (['NDPE'].includes(typ)) {
                    options.push (<button style={button_style}>Launch NDPE</button>)
                }
            }
            else {
                content1 += "Grid not populated"

                options.push (<button style={button_style}>Deploy device</button>)
                options.push (<button style={button_style}>Deploy utx</button>)
            }


            //
            // Construct displayed information
            //
            display_info =
                <div>
                    <h3>Info</h3>
                    <p style={{fontSize:"0.9em"}}>{content1}</p>

                    <table style={{fontSize:"0.9em"}}>
                        <thead>
                            <tr>
                                <th style={{textAlign:'left',paddingLeft:'0'}}>Resource</th>
                                <th>Balance</th>
                            </tr>
                        </thead>
                        <tbody>
                            {tbody}
                        </tbody>
                    </table>
                </div>

        }
    }

    var options_gated = []
    if (!this.props.account) {
        options_gated.push (<p>no account signed in</p>)
    }
    else if (!this.props.in_civ) {
        options_gated.push (<p>account not in this civilization</p>)
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
            { this.props.show ?

            <div className={styles.modal}>

                <div style={modal_left_child_style}>
                    <h3>{title}</h3>
                    <p style={{fontSize:"0.9em",margin:'0'}}>{grids}</p>

                    {display_info}

                    <span>.</span>

                    <button onClick={this.props.onHide} style={{width:'fit-content'}}>Esc</button>
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
}


export default Modal;
