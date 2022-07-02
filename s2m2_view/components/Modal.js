import React, { Component } from "react";
import styles from "../styles/Modal.module.css";

// Refs:
// https://stackoverflow.com/questions/54880669/react-domexception-failed-to-execute-removechild-on-node-the-node-to-be-re
// https://stackoverflow.com/questions/54276832/react-how-to-display-a-modal-popup-only-for-that-specific-div
// https://stackoverflow.com/questions/24502898/show-or-hide-element-in-react
// https://medium.com/@ralph1786/using-css-modules-in-react-app-c2079eadbb87

class Modal extends Component {

  render() {
    // console.log(this.props.show);
    return (
      <div>
        { this.props.show ?
          <div className={styles.modal}>
            {/* <h1> Grid ({this.props.info.grid_x}, {this.props.info.grid_y})</h1> */}
            <h3>Selected grid(s):</h3>
            <p style={{fontSize:"0.9em"}}>{this.props.info}</p>

            <h3>Options:</h3>
            <p style={{fontSize:"0.9em"}}>player doing something at these grids</p>

            <button onClick={this.props.onHide}>Esc</button>
          </div>
          : null }
      </div>
    );
  }
}


export default Modal;
