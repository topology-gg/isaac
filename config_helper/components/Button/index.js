import React from 'react'
import styles from './Button.module.css'

const Button = (props) => {
    return (
        <button
          {...props}
          className={`${styles.button} ${props.className || ''}`}
        />
    )
}

export default Button
