import React, { useState, useEffect } from "react";
import { ConnectWallet } from "../components/ConnectWallet.js"
import { getInstalledInjectedConnectors, StarknetProvider } from '@starknet-react/core'

import View from "../components/View"
import Panel from "../components/Panel"
import ReplayWindow from "../components/ReplayWindow"
import CoverArt from "../components/CoverArt"
import CoverArtBack from "../components/CoverArtBack"
import Button from "../components/Button/index.js";

function Home() {

    const connectors = getInstalledInjectedConnectors()

    const [panelButtonText, setPanelButtonText] = useState ('Open history')
    const [panelOpen, setPanelOpen] = useState (false)
    const [replayWindowOpen, setReplayWindowOpen] = useState (false)

    const [dbStatesReplayWindow, setDbStatesReplayWindow] = useState({})

    function handlePanel() {
        if (panelOpen) {
            document.getElementById("side-panel").style.width = "0";
            setPanelOpen (false)
            setPanelButtonText ('Open history')
        }
        else {
            document.getElementById("side-panel").style.width = "500px";
            setPanelOpen (true)
            setPanelButtonText ('Close history')
        }
    }

    function toggleReplayWindow () {
        if (replayWindowOpen) {
            document.getElementById("replay-window").style.width = "0";
            setReplayWindowOpen (false)
        }
        else {
            document.getElementById("replay-window").style.width = "70%";
            setReplayWindowOpen (true)
        }
    }

    return (
        <StarknetProvider connectors={connectors}>
            <CoverArtBack />
            <CoverArt />

            <div id="replay-window" className="replay-window">
                <ReplayWindow toggleReplayWindow={toggleReplayWindow} dbStatesReplayWindow={dbStatesReplayWindow} open={replayWindowOpen}/>
            </div>
            <div id="side-panel" className="side-panel">
                <Panel toggleReplayWindow={toggleReplayWindow} setDbStatesReplayWindow={setDbStatesReplayWindow} />
            </div>
            <div className="mother-container">
                <div className="top-child-container">
                    <div style={{display:'flex'}}>
                        <p style={{fontFamily:'Anoxic',fontSize:'4em',marginTop:'0.2em',marginBottom:'0.2em'}}>ISAAC</p><p style={{verticalAlign:"bottom"}}>Alpha2</p>
                    </div>


                    <Button
                        onClick={handlePanel}
                        style={{
                            padding:'0',margin:'0',height:'25px',border:'0',width:'160px',
                            color:'#333333',fontSize:'13.33px',fontFamily:'Poppins-Light'
                        }}
                    >
                        {panelButtonText}
                    </Button>

                    <span>.</span>

                    <ConnectWallet />

                    <View />
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;
