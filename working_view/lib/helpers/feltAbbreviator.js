export function abbrevDecString (felt) {
    return felt.slice(0,3) + "..." + felt.slice(-4)
}

export function abbrevHexString (accountString) {
    return "0x" + accountString.slice(0,3) + "..." + accountString.slice(-4)
}