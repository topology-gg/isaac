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

function Home() {

  return (
    <div className="mother-container">
        <h2>Solve2Mint: Masyu</h2>
        <span>.</span>
        <BoardView />
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