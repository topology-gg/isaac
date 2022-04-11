import ReactDOM from "react-dom";
import React, { useEffect, useRef, useState } from "react";
import './ColorMaterial'

import { Canvas, useFrame } from "@react-three/fiber";
import { degToRad } from "three/src/math/MathUtils";
import { Vector2 } from "three";

import { createSurface } from './surfaceHelper'

let gridSize = 50;
const canvasSize = 1024;
const deviceTypeToColorMap = {
    0: "blue", // SPG
    1: "purple", // NPG
    2: "red", // FE harvester
    3: "green",
    4: "yellow",
    5: "yellow",
    6: "yellow",
    7: "orange", // FE refinery
    8: "yellow",
    9: "yellow",
    10: "yellow",
    11: "yellow",
    12: "white", // UTB
    13: "yellow",
    14: "yellow"
}
const xRotationSpeed = 0.0
const yRotationSpeed = 0.0
const zRotationSpeed = 0.0

function drawCell(ctx, gridSize, canvasSize, cellX, cellY, color = "yellow") {
    ctx.fillStyle = color;
    ctx.fillRect(
        cellX * (canvasSize / gridSize),
        cellY * (canvasSize / gridSize),
        canvasSize / gridSize,
        canvasSize / gridSize
    );
}

function drawGrid(ctx, gridSize, canvasSize) {
    for (let i = 0; i < gridSize + 1; i++) {
        const x = i * (canvasSize / gridSize);
        ctx.beginPath();
        ctx.lineWidth = 0.5;
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.2)';;
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvasSize);
        ctx.moveTo(0, x);
        ctx.lineTo(canvasSize, x);
        ctx.stroke();
    }
}

// function drawLine(ctx, time, canvasSize) {
//     const x = ((time * canvasSize) / gridSize) % canvasSize;
//     ctx.beginPath();
//     ctx.lineWidth = 3;
//     ctx.strokeStyle = "white";
//     ctx.moveTo(x, 0);
//     ctx.lineTo(x, canvasSize);
//     ctx.stroke();
// }

function drawResources(ctx, surfaceArray) {
    for (var i = 0; i < surfaceArray.length; i++) {
        for (var j = 0; j < surfaceArray[i].length; j++) {
            if (surfaceArray[i][j] != 0) {
                const color = deviceTypeToColorMap[ surfaceArray[i][j] ]
                drawCell(
                    ctx,
                    gridSize,
                    canvasSize,
                    i,
                    j,
                    color
                );
            }
        }
    }
}

export default function Box(props) {
    const [surface, setSurface] = useState(null);

    const canvasRef = useRef(document.createElement("canvas"));
    const textureRef = useRef();
    const group = useRef();
    const mouseUV = useRef(new Vector2());

    const canvasRef2 = useRef(document.createElement("canvas"));
    const textureRef2 = useRef();

    const canvasRef3 = useRef(document.createElement("canvas"));
    const textureRef3 = useRef();

    const canvasRef4 = useRef(document.createElement("canvas"));
    const textureRef4 = useRef();

    const canvasRef5 = useRef(document.createElement("canvas"));
    const textureRef5 = useRef();

    const canvasRef6 = useRef(document.createElement("canvas"));
    const textureRef6 = useRef();

    useFrame(({ clock }) => {
            if (props.device_emap && !surface) {

                const new_surface = createSurface(props.device_emap, gridSize)

                console.log("new_surface:", new_surface)
                setSurface(new_surface)
            }

        // Can remove variables and call canvasRef instead
        const canvas = canvasRef.current;

        canvas.width = canvasSize;
        canvas.height = canvasSize;

        const canvas2 = canvasRef2.current;

        canvas2.width = canvasSize;
        canvas2.height = canvasSize;

        const canvas3 = canvasRef3.current;

        canvas3.width = canvasSize;
        canvas3.height = canvasSize;

        const canvas4 = canvasRef4.current;

        canvas4.width = canvasSize;
        canvas4.height = canvasSize;

        const canvas5 = canvasRef5.current;

        canvas5.width = canvasSize;
        canvas5.height = canvasSize;

        const canvas6 = canvasRef6.current;

        canvas6.width = canvasSize;
        canvas6.height = canvasSize;

        const ctx = canvasRef.current.getContext("2d");
        ctx.clearRect(0, 0, canvasSize, canvasSize);

        const ctx2 = canvasRef2.current.getContext("2d");
        ctx2.clearRect(0, 0, canvasSize, canvasSize);

        const ctx3 = canvasRef3.current.getContext("2d");
        ctx3.clearRect(0, 0, canvasSize, canvasSize);

        const ctx4 = canvasRef4.current.getContext("2d");
        ctx4.clearRect(0, 0, canvasSize, canvasSize);

        const ctx5 = canvasRef5.current.getContext("2d");
        ctx5.clearRect(0, 0, canvasSize, canvasSize);

        const ctx6 = canvasRef6.current.getContext("2d");
        ctx6.clearRect(0, 0, canvasSize, canvasSize);

        if (surface) {
            drawResources(ctx, surface[0])
            drawResources(ctx2, surface[1])
            drawResources(ctx3, surface[2])
            drawResources(ctx4, surface[3])
            drawResources(ctx5, surface[4])
            drawResources(ctx6, surface[5])
        }


        drawGrid(ctx, gridSize, canvasSize);
        drawGrid(ctx2, gridSize, canvasSize);
        drawGrid(ctx3, gridSize, canvasSize);
        drawGrid(ctx4, gridSize, canvasSize);
        drawGrid(ctx5, gridSize, canvasSize);
        drawGrid(ctx6, gridSize, canvasSize);

        if (textureRef.current) {
            textureRef.current.needsUpdate = true;
        }
        if (textureRef2.current) {
            textureRef2.current.needsUpdate = true;
        }
        if (textureRef3.current) {
            textureRef3.current.needsUpdate = true;
        }
        if (textureRef4.current) {
            textureRef4.current.needsUpdate = true;
        }

        if (textureRef5.current) {
            textureRef5.current.needsUpdate = true;
        }

        if (textureRef6.current) {
            textureRef6.current.needsUpdate = true;
        }

        group.current.rotateX(xRotationSpeed);
        group.current.rotateY(yRotationSpeed);
        group.current.rotateZ(zRotationSpeed);
    });

    return (
        <group ref={group} {...props}>
            <mesh
                rotation={[0, degToRad(0), degToRad(0)]}
                onPointerMove={(e) => (mouseUV.current = e.uv)}
                onPointerOver={() => (document.body.style = "cursor: none;")}
                onPointerOut={() => (document.body.style = "cursor: pointer;")}
            >
                <boxBufferGeometry args={[3, 3, 3]} />
                <meshBasicMaterial attach="material-0">
                    <canvasTexture
                        ref={textureRef}
                        attach="map"
                        image={canvasRef.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attach="material-1">
                    <canvasTexture
                        ref={textureRef2}
                        attach="map"
                        image={canvasRef2.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attach="material-2">
                    <canvasTexture
                        ref={textureRef3}
                        attach="map"
                        image={canvasRef3.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attach="material-3">
                    <canvasTexture
                        ref={textureRef4}
                        attach="map"
                        image={canvasRef4.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attach="material-4">
                    <canvasTexture
                        ref={textureRef5}
                        attach="map"
                        image={canvasRef5.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attach="material-5">
                    <canvasTexture
                        ref={textureRef6}
                        attach="map"
                        image={canvasRef6.current}
                    />
                </meshBasicMaterial>
            </mesh>
        </group>
    );
}