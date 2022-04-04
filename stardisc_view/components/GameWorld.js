import React from "react";
import Box from "./Box";
import { Sky } from '@react-three/drei'
import { Physics } from '@react-three/cannon'
import styles from '../styles/GameWorld.module.css'

import {
    useContract,
    useStarknetCall,
} from '@starknet-react/core'
import { Canvas } from '@react-three/fiber'

import ServerAbi from '../pages/abi/server.json'
import ShapesAbi from '../pages/abi/shapes.json'

export const SERVER_ADDRESS = '0x04d36339f154419982289e28c8653f4a6c3f6009df387e3baa298b84b2de016b'
export const SHAPES_ADDRESS = '0x06760cd9097b4968d3dc6f1c81fda2b2bbe701f771f9cb657f064bf3ae90f0aa'

function useServerContract() {
    return useContract({ abi: ServerAbi, address: SERVER_ADDRESS })
}

function useShapesContract() {
    return useContract({ abi: ShapesAbi, address: SHAPES_ADDRESS })
}

export default function GameWorld() {

    const { contract } = useServerContract()
    const { data: macro_state, error } = useStarknetCall({
        contract,
        method: 'view_macro_state_curr',
        args: [],
    })
    console.log(macro_state)

    return (
        <Canvas className={styles.canvas}>
            <Sky sunPosition={[100, 20, 100]} />
            <ambientLight intensity={0.25} />
            <pointLight castShadow intensity={0.7} position={[100, 100, 100]} />
            <Physics gravity={[0, -30, 0]}>
                <Box />
            </Physics>
        </Canvas>
    )
}