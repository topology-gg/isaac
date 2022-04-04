import ReactDOM from "react-dom";
import React, { useEffect, useRef } from "react";

import { Canvas, useFrame } from "@react-three/fiber";
import { degToRad } from "three/src/math/MathUtils";
import { Vector2 } from "three";

import FX from "../pages/FX";

let gridSize = 16;
const canvasSize = 512;

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
        ctx.lineWidth = 1;
        ctx.strokeStyle = "green";
        ctx.moveTo(x, 0);
        ctx.lineTo(x, canvasSize);
        ctx.moveTo(0, x);
        ctx.lineTo(canvasSize, x);
        ctx.stroke();
    }
}

function drawLine(ctx, time, canvasSize) {
    const x = ((time * canvasSize) / gridSize) % canvasSize;
    ctx.beginPath();
    ctx.lineWidth = 3;
    ctx.strokeStyle = "white";
    ctx.moveTo(x, 0);
    ctx.lineTo(x, canvasSize);
    ctx.stroke();
}

export default function Box(props) {
    const canvasRef = useRef(document.createElement("canvas"));
    const textureRef = useRef();
    const group = useRef();
    const mouseUV = useRef(new Vector2());

    useEffect(() => {
        const canvas = canvasRef.current;

        canvas.width = canvasSize;
        canvas.height = canvasSize;
    });

    useFrame(({ clock }) => {
        const ctx = canvasRef.current.getContext("2d");
        ctx.clearRect(0, 0, canvasSize, canvasSize);
        drawCell(
            ctx,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "red"
        );
        drawCell(
            ctx,
            gridSize,
            canvasSize,
            gridSize / 2 +
            Math.floor((Math.sin(clock.getElapsedTime()) / 3) * gridSize),
            gridSize / 2 +
            Math.floor((Math.cos(clock.getElapsedTime()) / 3) * gridSize),
            "yellow"
        );
        drawCell(
            ctx,
            gridSize,
            canvasSize,
            Math.floor(mouseUV.current.x * gridSize),
            16 - Math.floor(mouseUV.current.y * gridSize),
            "white"
        );
        drawGrid(ctx, gridSize, canvasSize);
        drawLine(ctx, clock.getElapsedTime(), canvasSize);

        if (textureRef.current) {
            textureRef.current.needsUpdate = true;
        }
        group.current.rotateX(0.007);
        group.current.rotateZ(-0.007);
    });

    return (
        <group ref={group} {...props}>
            <mesh
                rotation={[0, degToRad(45), degToRad(45)]}
                onPointerMove={(e) => (mouseUV.current = e.uv)}
                onPointerOver={() => (document.body.style = "cursor: none;")}
                onPointerOut={() => (document.body.style = "cursor: pointer;")}
            >
                <boxGeometry args={[3, 3, 3]} />
                <meshBasicMaterial>
                    <canvasTexture
                        ref={textureRef}
                        attach="map"
                        image={canvasRef.current}
                    />
                </meshBasicMaterial>
            </mesh>
        </group>
    );
}
