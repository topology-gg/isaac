import React from "react";
import styles from "../styles/HUDLeft.module.css";

const HUDLeft = ({ faceRadiation, selectedFace }) => {
    return (
        <div className={styles.hud}>
            <a className={styles.buttonLink} href="https://isaac-space-view.netlify.app/">← Space View</a>
            <div>Face: {selectedFace !== -1 ? selectedFace : "-"} </div>
            <div>
                Solar Exposure:{" "}
                {selectedFace !== -1
                    ? Math.floor(
                          (Math.min(faceRadiation[selectedFace], 20) / 20.0) *
                              100
                      )
                    : "- "}
                %
            </div>
        </div>
    );
};

export default HUDLeft;
