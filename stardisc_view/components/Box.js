import ReactDOM from "react-dom";
import React, { useEffect, useRef } from "react";

import { Canvas, useFrame } from "@react-three/fiber";
import { degToRad } from "three/src/math/MathUtils";
import { Vector2 } from "three";

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

    useEffect(() => {
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
    });

    useFrame(({ clock }) => {
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

        drawCell(
            ctx,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "red"
        );
        drawCell(
            ctx2,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "blue"
        );

        drawCell(
            ctx3,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "brown"
        );

        drawCell(
            ctx4,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "purple"
        );

        drawCell(
            ctx5,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "black"
        );

        drawCell(
            ctx6,
            gridSize,
            canvasSize,
            Math.floor((clock.getElapsedTime() * 16) % gridSize),
            Math.floor(clock.getElapsedTime() % gridSize),
            "yellow"
        );

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
                <boxBufferGeometry args={[3, 3, 3]} />
                <meshBasicMaterial attachArray="material">
                    <canvasTexture
                        ref={textureRef}
                        attach="map"
                        image={canvasRef.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attachArray="material">
                    <canvasTexture
                        ref={textureRef2}
                        attach="map"
                        image={canvasRef2.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attachArray="material">
                    <canvasTexture
                        ref={textureRef3}
                        attach="map"
                        image={canvasRef3.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attachArray="material">
                    <canvasTexture
                        ref={textureRef4}
                        attach="map"
                        image={canvasRef4.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attachArray="material">
                    <canvasTexture
                        ref={textureRef5}
                        attach="map"
                        image={canvasRef5.current}
                    />
                </meshBasicMaterial>
                <meshBasicMaterial attachArray="material">
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