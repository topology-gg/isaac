import React from "react";

export default function Box() {
    return <mesh>
        <boxBufferGeometry attach="geometry" />
        <meshLambertMaterial attach="material" color="blue" />
    </mesh>;
}