import React, { Component, useState } from "react";
import styles from "../styles/HUD.module.css";

class HUD extends Component {

    render() {

        //
        // Build information to be shown in popup window
        //
        var content = []
        var i=0
        for (const line of this.props.lines) {
            if (line) {
                content.push (<div key={`hudLine${i}`}>{line}</div>)
                i += 1
            }
        }

        return (
            <div style={{visibility: this.props.universeActive?'visible':'hidden'}}>
                <div className={styles.hud}>
                    {content}
                </div>
            </div>
        );
    }
}

export default HUD;
