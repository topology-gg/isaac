import GameWorld from "../components/GameWorld";
import GameStatsDevices from "../components/GameStatsDevices"
import GameStatsPlayers from "../components/GameStatsPlayers"
import CoverArt from "../components/CoverArt"
import CoverArtBack from "../components/CoverArtBack"

import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"

import {
  useStarknet,
  useContract,
  useStarknetCall,
  useStarknetInvoke,
  StarknetProvider,
} from '@starknet-react/core'

import BoardView from "../components/Board";
import RecordView from "../components/Record";

function Home() {

    return (
        <div className="mother-container">
            <div className="top-child-container">
                <h2>Solve2Mint 2.0</h2>
                <p style={{marginBottom:'0'}}>Earn your ticket to the Isaac Alpha reality.</p>
                <p style={{marginTop:'0',marginBottom:'0'}}>One puzzle, for one ticket, for one account.</p>
                <p style={{marginTop:'0',marginBottom:'0'}}>N puzzles available. <a>Contract.</a> <a>Voyager.</a> </p>

                <BoardView />
            </div>

            <div className="bottom-child-container">
                <RecordView />
            </div>
        </div>
    )


        //     <div className="left-child-container">
        //         <BoardView />
        //     </div>

        //     <div className="right-child-container">

        //         <div className="right-child-title">
        //             <span>.</span>

        //             <h3>Solve2Mint: Masyu</h3>
        //         </div>

        //         <div className="right-child-middle">
        //             <span>.</span>
        //             <h4>Control</h4>
        //             <p>Key press 1~6: choose display mode</p>
        //             <p>Mouse click: select grid</p>
        //             <p>Mouse drag: select grids</p>
        //             <span>.</span>
        //             <h4>Universe Stats</h4>
        //         </div>

        //         <div className="right-child-bottom">
        //         </div>

        //     </div>

        // </div>
}

export default Home;