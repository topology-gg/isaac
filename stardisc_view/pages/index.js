import GameWorld from "../components/GameWorld";
import GameStatsDevices from "../components/GameStatsDevices"
import GameStatsPlayers from "../components/GameStatsPlayers"

import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"

import {
  useStarknet,
  useContract,
  useStarknetCall,
  useStarknetInvoke,
  StarknetProvider,
} from '@starknet-react/core'

function Home() {

  return (
    <StarknetProvider>
      <div className="mother-container">

          <div className="left-child-container">
            <GameWorld />
          </div>

          <div className="right-child-container">

            <div className="right-child-top">
              <span>.</span>

              <h3>ISAAC: Working View</h3>
              <ConnectWallet />
            </div>

            <div className="right-child-middle">
              <span>.</span>
              <h4>Universe Stats</h4>
            </div>

            <div className="right-child-bottom">
              <GameStatsPlayers />
              <span>.</span>
              <GameStatsDevices />
            </div>

          </div>

      </div>

    </StarknetProvider>
  )
}

export default Home;