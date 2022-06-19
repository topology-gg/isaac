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
      <h3>Argent X Wallet</h3>
      <ConnectWallet />

      <GameStats />
      <GameWorld />

    </StarknetProvider>
  )
}

export default Home;