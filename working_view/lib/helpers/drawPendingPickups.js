import animateGlow from "./animateGlow";
import animatePulse from "./animatePulse";

export default function drawPendingPickups(canvasRef, pendingPickupsRef, deviceRectsRef) {
    console.log("drawPendingPickups");
    const canvi = canvasRef.current;
    const pendingPickups = pendingPickupsRef.current;
    const deviceRects = deviceRectsRef.current;

    if (!canvi || !pendingPickups || !deviceRects) {
        console.warn(`drawPendingPickups: no canvas or pendingPickups. Canvas: ${!!canvi}, pendingPickups: ${!!pendingPickups}, deviceRects: ${!!deviceRects}`);
        return;
    }

    // console.log('deviceRects', deviceRects, 'pendingPickups', pendingPickups);

    pendingPickups.forEach(device => {
        if (device.utxGrids) {
            // device.utxGrids.forEach(grid => {
            //     const rect = newDeviceRect();
            //     setRectProps({x: grid.x, y: grid.y, dimension: 1, color: device.color}, rect);
            //     canvi.add(rect);
            //     animateGlow(canvi, rect);
            // })
        } else {
            const deviceRect = deviceRects[device.id];
            if (!deviceRect) {
                console.log("drawPendingPickups: no deviceRect", device.id);
                return;
            }
            if (device.rect) {
                console.log("drawPendingPickups: already showing animation", device.id);
                return;
            }
            console.log('deviceRect', deviceRect);
            deviceRect.opacity = 0.5;
            animateGlow(canvi, deviceRect);
            animatePulse(canvi, deviceRect);
            device.rect = deviceRect;
        }
    })

    canvi.requestRenderAll();
}
