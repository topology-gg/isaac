import React, { Component } from "react";
import styles from "../styles/Modal.module.css";

// import { addAddressPadding } from "starknet";

// Refs:
// https://stackoverflow.com/questions/54880669/react-domexception-failed-to-execute-removechild-on-node-the-node-to-be-re
// https://stackoverflow.com/questions/54276832/react-how-to-display-a-modal-popup-only-for-that-specific-div
// https://stackoverflow.com/questions/24502898/show-or-hide-element-in-react
// https://medium.com/@ralph1786/using-css-modules-in-react-app-c2079eadbb87

class Modal extends Component {

  render() {

    //
    // Build information to be shown in popup window
    //
    const info = this.props.info
    var title = ""
    var grids = ""
    var display_info
    var options = ""

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
            options = "deploy UTB / UTL"
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
            var content2 = ''
            if (grid_str in grid_mapping) {
                const grid_info = grid_mapping [grid_str]

                const owner = grid_info ['owner']
                const typ   = grid_info ['type']
                const balances = grid_info ['balances']

                content1 += `Device type: ${typ}; `
                content1 += `Owner: ${owner}`

                content2 += JSON.stringify(balances)



                options = "do something with the device on this grid"
            }
            else {
                content1 += "Grid not populated"

                options = "deploy something on this grid maybe"
            }


            //
            // Construct displayed information
            //
            display_info =
                <div>
                    <h3>Info</h3>
                    <p style={{fontSize:"0.9em"}}>{content1}</p>
                    <p style={{fontSize:"0.9em"}}>{content2}</p>
                </div>

        }
    }

    return (
        <div>
            { this.props.show ?
            <div className={styles.modal}>
                <h3>{title}</h3>
                <p style={{fontSize:"0.9em"}}>{grids}</p>

                {display_info}

                <h3>Options:</h3>
                <p style={{fontSize:"0.9em"}}>
                    {options}
                </p>

                <button onClick={this.props.onHide}>Esc</button>
            </div>
            : null }
        </div>
    );
  }
}


export default Modal;
