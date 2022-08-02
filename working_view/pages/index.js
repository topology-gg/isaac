import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";

import GameWorld from "../components/GameWorld";
import GameStatsDevices from "../components/GameStatsDevices"
import GameStatsPlayers from "../components/GameStatsPlayers"
import GameStatsCiv from "../components/GameStatsCiv"
import CoverArt from "../components/CoverArt"
import CoverArtBack from "../components/CoverArtBack"

import { ConnectWallet } from "../components/ConnectWallet.js"

import {
    useMacroStates
} from '../lib/api'

import {
  useStarknet,
  useContract,
  useStarknetCall,
  useStarknetInvoke,
  StarknetProvider,
} from '@starknet-react/core'

function Home() {

    const [universeActive, setUniverseActive] = useState (false)
    const { data: db_macro_states } = useMacroStates ()

    useEffect ( () => {
        if (!db_macro_states) {
            return
        }
        else {
            if (db_macro_states.macro_states.length > 0) {
                setUniverseActive (true)
            }
            else {
                setUniverseActive (false)
            }
        }
    }, [db_macro_states])

    return (
    <StarknetProvider>
        <CoverArtBack />
        <CoverArt />

        <audio id='sound-popup-open'  src='/sound-open.ogg'/>
        <audio id='sound-popup-close' src='/sound-close.ogg'/>

        <div className="mother-container">

            <div className="left-child-container">
                <GameWorld />
            </div>

            <div className="right-child-container" style={{display: universeActive?'flex':'none'}}>

                <div className="right-child-title">
                    <span>.</span>

                    <h3 style={{fontFamily:'Anoxic',fontSize:'40px',marginTop:'10px',marginBottom:'20px'}}>
                        ISAAC
                    </h3>
                    <ConnectWallet />
                </div>

                <div className="right-child-middle" >
                    <span>.</span>
                    <h4>Control</h4>
                    <p>Key press 1~6: choose display mode</p>
                    <p>Key press 7: transfer device</p>
                    <p>Mouse click: select grid</p>
                    <p>Mouse drag: select grids</p>
                    <span>.</span>
                </div>

                <h4 style={{paddingBottom:'1em'}}>Universe Stats</h4>

                <div className="right-child-bottom">
                    <GameStatsCiv />
                    <span>.</span>
                    <GameStatsPlayers universeActive={universeActive} />
                    <span>.</span>
                    <GameStatsDevices universeActive={universeActive} />
                </div>

            </div>

        </div>

    </StarknetProvider>
    )
}

export default Home;