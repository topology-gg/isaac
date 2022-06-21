import GameWorld from "../components/GameWorld";
import GameStats from "../components/GameStats"
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

              <h2>Isaac / Working View</h2>

              <span>.</span>

              <h3>Argent X Wallet</h3>
              <ConnectWallet />
            </div>

            <div className="right-child-bottom">
              <span>.</span>
              <GameStats />
            </div>

          </div>

      </div>

    </StarknetProvider>
  )
}

export default Home;