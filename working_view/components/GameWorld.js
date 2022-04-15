import React, { useEffect } from "react";
import Box from "./Box";
import { Sky } from '@react-three/drei'
import { Physics } from '@react-three/cannon'
import styles from '../styles/GameWorld.module.css'
import { useMemo } from 'react'

import {
    useStarknet,
    useContract,
    useStarknetCall,
    useStarknetInvoke
} from '@starknet-react/core'

import { Canvas, useThree } from '@react-three/fiber'
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls";

import ServerAbi from '../abi/server_abi.json'
export const SERVER_ADDRESS = '0x02a3f6c3ddf2be709ac34dfe6357f7f7bd8a462ecd16e46a15b2ee766ca6198c'
function useServerContract() {
    return useContract({ abi: ServerAbi, address: SERVER_ADDRESS })
}

const CameraController = () => {
    const { camera, gl } = useThree();
    useEffect(
      () => {
        const controls = new OrbitControls(camera, gl.domElement);

        controls.minDistance = 3;
        controls.maxDistance = 20;
        return () => {
          controls.dispose();
        };
      },
      [camera, gl]
    );
    return null;
  };

export default function GameWorld() {

    const { contract } = useServerContract()
    const { account } = useStarknet()
    const { invoke } = useStarknetInvoke({
        contract,
        method: 'client_deploy_device_by_grid'
    })

    const { data: macro_state, error } = useStarknetCall({
        contract,
        method: 'view_macro_state_curr',
        args: [],
    })

    const { data: phi } = useStarknetCall({
        contract,
        method: 'view_phi_curr',
        args: [],
    })

    const { data: device_emap } = useStarknetCall({
        contract,
        method: 'client_view_device_deployed_emap',
        args: []
    })

    const { data: utb_grids } = useStarknetCall({
        contract,
        method: 'client_view_all_utb_grids',
        args: []
    })


return (
        <Canvas className={styles.canvas}>
            <CameraController />
            <ambientLight />
            <Box macro_state={macro_state} phi={phi} device_emap={device_emap} utb_grids={utb_grids}/>
        </Canvas>
    )
}