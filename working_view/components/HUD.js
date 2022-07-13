import React, { Component, useState } from "react";
import styles from "../styles/HUD.module.css";

class HUD extends Component {

    render() {

        //
        // Build information to be shown in popup window
        //
        var content = []
        for (const line of this.props.lines) {
            if (line) {
                content.push (<div>{line}</div>)
            }
        }

        return (
            <div>
                <div className={styles.hud}>
                    {content}
                </div>
            </div>
        );
    }
}

export default HUD;
