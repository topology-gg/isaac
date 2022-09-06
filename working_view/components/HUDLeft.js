import React from "react";
import styles from "../styles/HUDLeft.module.css";
import CubeIcon from "./CubeIcon"

const HUDLeft = ({ faceRadiation, selectedFace }) => {
    return (
        <div className={styles.hud}>
            <a className={styles.buttonLink} href="https://isaac-space-view.netlify.app/">← Space View</a>
            <div className={styles.selectedFace}>
                <span className={styles.faceNumber}>Face: {selectedFace !== -1 ? selectedFace : "-"}</span>
                <CubeIcon face={selectedFace !== -1 ? selectedFace : "None"} />
            </div>
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
