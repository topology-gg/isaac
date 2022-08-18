import React, { useState, useEffect } from "react";
import { ConnectWallet } from "../components/ConnectWallet.js"
import { getInstalledInjectedConnectors, StarknetProvider } from '@starknet-react/core'

import View from "../components/View"
import Panel from "../components/Panel"
import CoverArt from "../components/CoverArt"
import CoverArtBack from "../components/CoverArtBack"

function Home() {

    const connectors = getInstalledInjectedConnectors()

    const [panelButtonText, setPanelButtonText] = useState ('open history')
    const [panelOpen, setPanelOpen] = useState (false)

    function handlePanel() {
        if (panelOpen) {
            document.getElementById("side-panel").style.width = "0";
            setPanelOpen (false)
            setPanelButtonText ('open history')
        }
        else {
            document.getElementById("side-panel").style.width = "500px";
            setPanelOpen (true)
            setPanelButtonText ('close history')
        }
    }

    return (
        <StarknetProvider connectors={connectors}>
            <CoverArtBack />
            <CoverArt />

            <div id="side-panel" className="side-panel">
                <Panel />
            </div>
            <div className="mother-container">
                <div className="top-child-container">
                    <h1 style={{fontFamily:'Anoxic',fontSize:'4em',marginTop:'0.2em',marginBottom:'0.2em'}}>ISAAC</h1>

                    <button
                        onClick={handlePanel}
                        style={{padding:'0',margin:'0',height:'25px',border:'0',width:'160px',color:'#333333',fontSize:'13.33px',fontFamily:'Poppins-Light'}}
                    >
                        {panelButtonText}
                    </button>

                    <span>.</span>

                    <ConnectWallet />

                    <View />
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;