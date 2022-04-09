import GameWorld from "../components/GameWorld";
import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"

import {
  StarknetProvider,
} from '@starknet-react/core'

function Home() {
  return (
    <StarknetProvider>
      <div className={styles.gamecontainer}>
        <GameWorld />
      </div>
    </StarknetProvider>
  )
}

export default Home;