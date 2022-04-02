import React from "react";
import { Canvas } from '@react-three/fiber'

export default function Box() {
    return <mesh>
        <boxBufferGeometry attach="geometry" />
        <meshLambertMaterial attach="material" color="blue" />
    </mesh>;
}