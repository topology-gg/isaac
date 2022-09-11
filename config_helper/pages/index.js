import React, { useState, useEffect } from "react";
import { ConnectWallet } from "../components/ConnectWallet.js"
import { getInstalledInjectedConnectors, StarknetProvider } from '@starknet-react/core'

import Config from "../components/Config"
import View from "../components/View"

function Home() {

    const connectors = getInstalledInjectedConnectors()

    const [isGyoza, setIsGyoza] = useState (false)

    return (
        <StarknetProvider connectors={connectors}>
            <div className="mother-container">
                <div className="top-child-container">
                    <h1 style={{fontFamily:'Anoxic',fontSize:'4em',marginTop:'2em',marginBottom:'0.2em'}}>ISAAC</h1>

                    <ConnectWallet set_is_gyoza={(bool) => setIsGyoza(bool)}/>

                    {/* <View /> */}
                    {isGyoza ? <Config /> : <></>}
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;
