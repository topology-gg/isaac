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
        if (device.rect) {
            console.log("drawPendingPickups: already showing animation", device.id);
            return;
        }

        if (Array.isArray(deviceRects[device.id])) {
            // Picking up UTX grids
            deviceRects[device.id].forEach(rect => {
                rect.opacity = 0.5;
                animateGlow(canvi, rect);
                animatePulse(canvi, rect);
                device.rect = rect;
            });
        } else {
            const deviceRect = deviceRects[device.id];
            if (!deviceRect) {
                console.log("drawPendingPickups: no deviceRect", device.id);
                return;
            }
            deviceRect.opacity = 0.5;
            animateGlow(canvi, deviceRect);
            animatePulse(canvi, deviceRect);
            device.rect = deviceRect;
        }
    })

    canvi.requestRenderAll();
}
