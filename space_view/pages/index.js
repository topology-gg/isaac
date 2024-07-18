import GameWorld from "../components/GameWorld";
import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"
import CoverArt from "../components/CoverArt"
import CoverArtBack from "../components/CoverArtBack"

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
      <CoverArtBack />
      <CoverArt />

      <GameWorld />
      {/* <div className={styles.gamecontainer}>
        <GameWorld />
      </div> */}
    </StarknetProvider>
  )
}

export default Home;