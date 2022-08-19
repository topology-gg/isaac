import React from 'react'

import styles from './QueueVisualization.module.css'

const QueueVisualization = ({queueLength, civSize}) => {
    const percentage = queueLength && civSize ? ((queueLength / civSize) * 100) : 0

    const fullStyle = {
        width: `${percentage}%`,
    }

    return (
        <div className={styles.qVis}>
            <div className={styles.full} style={fullStyle}></div>
            <span className={styles.text}>{queueLength} / {civSize}</span>
        </div>
    )
}

export default QueueVisualization
