import styles from '../styles/Home.module.css'
import GameWorld from "../components/GameWorld";
import {
  StarknetProvider,
} from '@starknet-react/core'

function Home() {
  return (
    <StarknetProvider>
      <GameWorld />
    </StarknetProvider>
  )
}

export default Home;