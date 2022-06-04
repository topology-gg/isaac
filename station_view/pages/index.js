import GameWorld from "../components/GameWorld";
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
      <GameWorld />
      {/* <div className={styles.gamecontainer}>
        <GameWorld />
      </div> */}
    </StarknetProvider>
  )
}

export default Home;