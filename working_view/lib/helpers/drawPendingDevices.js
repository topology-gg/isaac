import { GRID, PAD_X, PAD_Y, SIDE } from "../constants/gameWorld";
import animateGlow from "./animateGlow";

const newDeviceRect = () => {
    return new fabric.Rect({
        stroke: '',
        strokeWidth: 0,
        opacity: 0.5,
        selectable: false,
        hoverCursor: 'default',
        visible: true
    })
}

export default function drawPendingDevices(canvasRef, pendingDevicesRef) {
    console.log("drawPendingDevices");
    const canvi = canvasRef.current;
    const pendingDevices = pendingDevicesRef.current;

    if (!canvi || !pendingDevices) {
        console.warn("drawPendingDevices: no canvas or pendingDevices");
        return;
    }

    const setRectProps = (device, rect) => {
        rect.left = PAD_X + device.x * GRID
        rect.top = PAD_Y + (SIDE * 3 - device.y - device.dimension) * GRID
        rect.width = GRID * device.dimension
        rect.height = GRID * device.dimension
        rect.fill = device.color
    }

    pendingDevices.forEach(device => {
        console.log("draw pending device indicator to canvas");
        if (device.utxGrids) {
            device.utxGrids.forEach(grid => {
                const rect = newDeviceRect();
                setRectProps({x: grid.x, y: grid.y, dimension: 1, color: device.color}, rect);
                canvi.add(rect);
                animateGlow(canvi, rect);
            })
        } else {
            const deviceRect = newDeviceRect();
            setRectProps(device, deviceRect);
            canvi.add(deviceRect);
            animateGlow(canvi, deviceRect);
            device.rectRef.current = deviceRect;
        }
    })

    canvi.requestRenderAll();
}
