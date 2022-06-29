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
            <h1> Grid ({this.props.info.grid_x}, {this.props.info.grid_y})</h1>
            <button onClick={this.props.onHide}>Close Modal</button>
          </div>
          : null }
      </div>
    );
  }
}


export default Modal;
