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
export const SERVER_ADDRESS = '0x0025ecf8ef3993263fec37a54dd730c5d10fa347d1427c584de0a48ec292b4b4'
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
        method: 'client_view_all_utx_grids',
        args: [12]
    })

    const { data: utl_grids } = useStarknetCall({
        contract,
        method: 'client_view_all_utx_grids',
        args: [13]
    })


return (
        <Canvas className={styles.canvas}>
            <CameraController />
            <ambientLight />
            <Box macro_state={macro_state} phi={phi} device_emap={device_emap} utb_grids={utb_grids} utl_grids={utl_grids}/>
        </Canvas>
    )
}