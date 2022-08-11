import { GRID, PAD_X, PAD_Y, SIDE } from "../constants/gameWorld";
import animateGlow from "./animateGlow";

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
        console.log("drawPendingDevices, device:", device);
        if (device.rectRef.current) {
            console.log("already in canvas");
            // The device is already in canvas, so we don't need to initialize it again
            setRectProps(device, device.rectRef.current);
        } else {
            console.log("adding to canvas");
            const deviceRect = new fabric.Rect({
                stroke: '',
                strokeWidth: 0,
                opacity: 0.5,
                selectable: false,
                hoverCursor: 'default',
                visible: true
            });
            setRectProps(device, deviceRect);
            canvi.add(deviceRect);
            animateGlow(canvi, deviceRect);

            device.rectRef.current = deviceRect;
        }
    })

    canvi.renderAll();
}
