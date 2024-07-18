import { fabric } from "fabric";
import { useEffect } from "react";
import { useCallback } from "react";
import { useRef } from "react";
import {
    PAD_X,
    PAD_Y,
    GRID,
    SIDE,
} from "../constants/gameWorld";
import { createPlacementAssistRect } from "../../components/fabricObjects/assists";

function gridToCanvasCoord(gridX, gridY) {
    const x = PAD_X + gridX * GRID;
    const y = PAD_Y + (SIDE * 3 - gridY) * GRID;

    return [x, y];
}

export default function usePlacementAssist(
    deviceBeingPlaced,
    mousePositionNorm,
    canvasRef
) {
    const devicePlacementAssistRef = useRef();

    // Updates the assist rect
    const update = useCallback(() => {
        if (!canvasRef.current?.getContext() || !devicePlacementAssistRef.current) {
            return;
        }
        if (deviceBeingPlaced) {
            // console.log("updating placement assist rect position");
            const [left, top] = gridToCanvasCoord(
                mousePositionNorm.x,
                mousePositionNorm.y + deviceBeingPlaced.dimension
            );
            devicePlacementAssistRef.current.left = left;
            devicePlacementAssistRef.current.top = top;
            devicePlacementAssistRef.current.width =
                GRID * deviceBeingPlaced.dimension;
            devicePlacementAssistRef.current.height =
                GRID * deviceBeingPlaced.dimension;
            devicePlacementAssistRef.current.fill = deviceBeingPlaced.color;
            devicePlacementAssistRef.current.visible = true;
        } else {
            devicePlacementAssistRef.current.visible = false;
        }
        // devicePlacementAssistRef.current.dirty = true;
        canvasRef.current.requestRenderAll();
    }, [deviceBeingPlaced, mousePositionNorm, canvasRef]);

    // const reset = () => {
    //     canvasRef.current.remove(devicePlacementAssistRef.current);
    // };

    useEffect(() => {
        if (!canvasRef.current?.getContext()) {
            return;
        }

        if (deviceBeingPlaced) {
            devicePlacementAssistRef.current = createPlacementAssistRect();
            // devicePlacementAssistRef.current = new fabric.Rect({
            //     height: GRID,
            //     width: GRID,
            //     left: PAD_X,
            //     top: PAD_Y,
            //     fill: "#ffff00",
            //     selectable: false,
            //     hoverCursor: "default",
            //     visible: true,
            //     strokeWidth: 0,
            // });
            // devicePlacementAssistRef.current.visible = true;
            canvasRef.current.add(devicePlacementAssistRef.current);
            canvasRef.current.requestRenderAll();
        } else {
            canvasRef.current.remove(devicePlacementAssistRef.current);
        }
    }, [deviceBeingPlaced, canvasRef]);

    useEffect(() => {
        update();
    }, [update]);
}
