import Head from 'next/head'
import Image from 'next/image'
import styles from '../styles/Home.module.css'
import GameWorld from "../components/GameWorld";
import { Abi } from 'starknet'
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