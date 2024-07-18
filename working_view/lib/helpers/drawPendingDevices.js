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

const addAndAnimateRect = (canvi, rect, rectRef) => {
    // Remove any previous instance and add it again
    if (rectRef.current) { canvi.remove(rectRef.current) }
    canvi.add(rect);
    animateGlow(canvi, rect);
    rectRef.current = rect;
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
                addAndAnimateRect(canvi, rect, grid.rectRef);
            })
        } else {
            const deviceRect = newDeviceRect();
            setRectProps(device, deviceRect);
            addAndAnimateRect(canvi, deviceRect, device.rectRef);
        }
    })

    canvi.requestRenderAll();
}
