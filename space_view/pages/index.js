import Head from 'next/head'
import Image from 'next/image'
import styles from '../styles/Home.module.css'
import { Canvas } from '@react-three/fiber'
import Box from "../components/Box";

export default function Home() {
  return (
    <div style={{ position: "fixed", width: "100%", height: "100%" }}>
      <Canvas className="canvas">
        <Box />
      </Canvas>
    </div>
  )
}

