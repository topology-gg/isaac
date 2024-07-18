import React from "react";
import styles from "../styles/FloatingMessage.module.css"

const FloatingMessage = ({message}) => {
    return <div className={styles.wrapper}>{message}</div>;
};

export default FloatingMessage;
