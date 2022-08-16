const BUTTON_BASE_STYLE = {
    fontSize:'12px',
    marginBottom:'5px',
    paddingTop:'5px',
    paddingBottom:'5px',
    paddingLeft:'30px',
    paddingRight:'30px',
    lineHeight:'15px',
    width: '175px',
    borderWidth: '0',
    cursor: 'pointer',
    display: 'inline-block',
    fontFamily: "Poppins-Light",
    textAlign: 'center',
    transition: 'all 200ms',
    verticalAlign: 'baseline',
    whiteSpace: 'nowrap',
    userSelect: 'none',
    touchAction: 'manipulation'
}

export const BUTTON_SINGLE_STYLE = {
    ...BUTTON_BASE_STYLE,
    borderRadius: '8px',
    color: '#333333'
}

export const BUTTON_SINGLE_DISABLED_STYLE = {
    ...BUTTON_BASE_STYLE,
    borderRadius: '8px',
    color: '#999999',
    backgroundColor: '#BBBBBB'
}

export const BUTTON_LEFT_STYLE = {
    ...BUTTON_BASE_STYLE,
    borderRadius: '8px 0px 0px 8px',
    color: '#333333'
}

export const BUTTON_LEFT_DISABLED_STYLE = {
    ...BUTTON_BASE_STYLE,
    borderRadius: '8px 0px 0px 8px',
    color: '#99999966',
    backgroundColor: '#CCCCCC66'
}

export const INPUT_BASE_STYLE = {
    fontSize:'10px',
    marginBottom:'5px',
    paddingTop:'5px',
    paddingBottom:'5px',
    paddingLeft:'15px',
    paddingRight:'15px',
    lineHeight:'15px',
    width: '40px',
    borderWidth: '0',
    backgroundColor: '#B9D9EB',
    color: '#333333',
    cursor: 'text',
    display: 'inline-block',
    fontFamily: "Poppins-Light",
    textAlign: 'center',
    transition: 'all 200ms',
    verticalAlign: 'baseline',
    whiteSpace: 'nowrap',
    userSelect: 'none',
    touchAction: 'manipulation'
}

export const INPUT_MID_STYLE = {
    ...INPUT_BASE_STYLE,
    borderRadius: '0px'
}

export const INPUT_END_STYLE = {
    ...INPUT_BASE_STYLE,
    borderRadius: '0px 8px 8px 0px'
}

export const TX_HASH_STYLE = {
    fontSize: '10px',
    color: '#333333',
    lineHeight:'15px',
    padding:'0',
    margin:'0'
}