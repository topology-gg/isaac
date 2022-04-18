import ReactDOM from "react-dom";
import React, { useEffect, useRef, useState } from "react";
import './ColorMaterial'

import * as THREE from "three"
import { Canvas, useFrame } from "@react-three/fiber";
import { degToRad } from "three/src/math/MathUtils";
import { Vector2 } from "three";

import { createSurface } from './surfaceHelper'

let gridSize = 100;
const canvasSize = 1024;
// const planetSurfaceColor = "rgba(226,234,243,255)";
const planetSurfaceColor = "rgba(216,228,200,255)";
const deviceTypeToColorMap = {
    0: "rgba(26,67,118,255)", // SPG
    1: "purple", // NPG
    2: "rgba(233,129,137,255)", // FE harvester
    3: "green",
    4: "yellow",
    5: "yellow",
    6: "yellow",
    7: "rgba(225,122,97,255)", // FE refinery
    8: "yellow",
    9: "yellow",
    10: "yellow",
    11: "yellow",
    12: "rgba(224,225,209,0)", // UTB; just reference (color determined by lerping per frame for blinking effect)
    13: "rgba(183,220,239,255)", // UTL; just reference (color determined by lerping per frame for blinking effect)
    14: "rgba(242,228,67,255)" // OPSF
}
const deviceTypeToGridSizeMap = {
    0: 1, // spg
    1: 3, // npg
    2: 1, // fe harv
    3: 1, // al harv
    4: 1, // ci harv
    5: 1, // si harv
    6: 1, // pu harv
    7: 2, // fe refn
    8: 2, // al refn
    9: 2, // ci refn
    10: 2, // si refn
    11: 2, // pef
    12: 1, // utb
    13: 1, // utl
    14: 5, // opsf
}
const xRotationSpeed = 0.0
const yRotationSpeed = 0.0
const zRotationSpeed = 0.0

function drawSurfaceCell (ctx, gridSize, canvasSize, cellX, cellY) {
    ctx.fillStyle = planetSurfaceColor;
    let x = cellX * (canvasSize / gridSize)
    let y = cellY * (canvasSize / gridSize)
    let w = 1 * (canvasSize / gridSize)
    ctx.fillRect(x, y, w, w);
}

function drawDeviceCell(ctx, shapeDim, gridSize, canvasSize, cellX, cellY, color = "yellow", shape) {
    ctx.fillStyle = color;

    const pad = 3
    const x = cellX * (canvasSize / gridSize) + pad
    const y = cellY * (canvasSize / gridSize) + pad
    const w = shapeDim * (canvasSize / gridSize) - 2*pad

    if (shape == 'square') {
        ctx.beginPath()
        ctx.strokeStyle = 'rgba(20,20,20,255)';
        ctx.rect(x, y, w, w);
        ctx.fill();
        ctx.lineWidth = 1.5;
        ctx.stroke();
        ctx.closePath()

        // ctx.fillRect(x, y, w, w);
    }
    else if (shape == 'circle') {
        ctx.beginPath()
        ctx.arc(x + (w/2), y + (w/2), w/2, 0, 2 * Math.PI, false);
        ctx.fill();
        ctx.lineWidth = 1;
        ctx.strokeStyle = 'black';
        ctx.stroke();
        ctx.closePath()
    }
}

function drawGrid(ctx, gridSize, canvasSize) {
    for (let i = 0; i < gridSize + 1; i++) {
        const x = i * (canvasSize / gridSize);
        ctx.beginPath();
        ctx.lineWidth = 0.8;
        ctx.strokeStyle = 'rgba(50, 50, 50, 1)';
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvasSize);
        ctx.moveTo(0, x);
        ctx.lineTo(canvasSize, x);
        ctx.stroke();
    }
}

function drawResources(ctx, surfaceArray, clock) {
    for (var i = 0; i < surfaceArray.length; i++) {
        for (var j = 0; j < surfaceArray[i].length; j++) {
            drawSurfaceCell (ctx, gridSize, canvasSize, i, j)
        }
    }

    for (var i = 0; i < surfaceArray.length; i++) {
        for (var j = 0; j < surfaceArray[i].length; j++) {
            if (surfaceArray[i][j] != -1) {
                let color
                let shape
                if (surfaceArray[i][j] == 13) {
                    //
                    // deal with UTL flashing
                    // let color oscillates between two colors
                    //
                    const lows = [183-50, 220-50, 239-50]
                    const highs = [183, 220, 239]
                    const ranges = [highs[0]-lows[0], highs[1]-lows[1], highs[2]-lows[2]] // refactor this line
                    const offsets = [ // refactor this line
                        clock.getElapsedTime() * 800 % (ranges[0]*2),
                        clock.getElapsedTime() * 800 % (ranges[1]*2),
                        clock.getElapsedTime() * 800 % (ranges[2]*2)
                    ]

                    // TODO:
                    // 1. use good color-lerp algorithm
                    // 2. refactor with js array-creation practices
                    let val_r, val_g, val_b
                    if (offsets[0] < ranges[0]) {val_r = lows[0] + offsets[0]}
                    else {val_r = highs[0] - (offsets[0]-ranges[0])}

                    if (offsets[1] < ranges[1]) {val_g = lows[1] + offsets[1]}
                    else {val_g = highs[1] - (offsets[1]-ranges[1])}

                    if (offsets[2] < ranges[2]) {val_b = lows[2] + offsets[2]}
                    else {val_b = highs[2] - (offsets[2]-ranges[2])}

                    color = `rgba(${val_r}, ${val_g}, ${val_b}, 0.8)`;
                    // console.log('> drawing UTL with color', color)
                    shape = 'circle'
                }
                else if (surfaceArray[i][j] == 12) {
                    //
                    // deal with UTB flashing
                    // let color oscillates between two colors
                    //
                    const low = 120
                    const high = 225
                    const range = high-low
                    const offset = clock.getElapsedTime() * 200 % (range*2);
                    let val
                    if (offset < range){
                        val = low + offset
                    }
                    else{
                        val = high - (offset-range)
                    }
                    color = `rgba(${val}, ${val}, ${val}, 0.8)`;
                    // console.log('> drawing UTB with color', color)
                    shape = 'circle'
                }
                else {
                    color = deviceTypeToColorMap [ surfaceArray[i][j] ]
                    shape = 'square'
                }

                const deviceGridSize = deviceTypeToGridSizeMap [ surfaceArray[i][j] ]
                // console.log ('drawing type', surfaceArray[i][j], 'as', color, 'at', i, j, 'of size', deviceGridSize)
                drawDeviceCell(
                    ctx,
                    deviceGridSize,
                    gridSize,
                    canvasSize,
                    i,
                    j,
                    color,
                    shape
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
            if ( props.device_emap && props.utb_grids && props.utl_grids && !surface) {
                console.log("device_emap:", props.device_emap)
                console.log("utb_grids:", props.utb_grids)
                console.log("utl_grids:", props.utl_grids)

                const new_surface = createSurface(
                    props.device_emap,
                    props.utb_grids,
                    props.utl_grids,
                    gridSize
                )

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

        // Adjusting for surface 0 (ctx)
        ctx.rotate ( Math.PI / 2 );
        ctx.scale(1,-1);

        // Adjust for surface 4 (ctx5)
        ctx5.scale(-1,1)
        ctx5.translate (-canvasSize, 0);

        // Adjusting for surface 5 (ctx6)
        ctx6.translate (0, canvasSize);
        ctx6.scale(1,-1);

        // Adjusting for surface 1 (ctx2)
        ctx2.rotate (Math.PI / 2);
        ctx2.translate (0, -canvasSize)
        ctx2.scale(-1,1);
        ctx2.translate (-canvasSize,0)

        // Adjusting for surface 2 (ctx3)
        ctx3.scale(1,-1);
        ctx3.translate (0,-canvasSize)

        // Adjusting for surface 3 (ctx4)
        ctx4.scale(-1,1)
        ctx4.translate (-canvasSize, 0);

        if (surface) {
            drawResources(ctx, surface[0], clock)
            drawResources(ctx2, surface[1], clock)
            drawResources(ctx3, surface[2], clock)
            drawResources(ctx4, surface[3], clock)
            drawResources(ctx5, surface[4], clock)
            drawResources(ctx6, surface[5], clock)
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
                rotation={[degToRad(90), degToRad(0), degToRad(0)]}
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