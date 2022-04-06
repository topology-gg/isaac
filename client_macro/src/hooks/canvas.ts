import React, { useRef, useEffect } from 'react';

interface CanvasProps {
    width: number;
    height: number;
}

const Canvas = ({ width, height }: CanvasProps) => {
    const canvasRef = useRef<HTMLCanvasElement>(null);

    useEffect(() => {
        if (canvasRef.current) {
            const canvas = canvasRef.current;
            const context = canvas.getContext('2d');
            if (context) {
                context.beginPath();
                context.arc(50, 50, 50, 0, 2 * Math.PI);
                context.fill();
            }
        }
    })

    return <canvas ref={canvasRef} height={height} width={width} />;
};

Canvas.defaultProps = {
    width: window.innerWidth,
    height: window.innerHeight
};

export default Canvas;