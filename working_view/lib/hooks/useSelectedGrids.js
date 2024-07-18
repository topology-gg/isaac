import { useCallback, useEffect, useRef, useState } from "react";
import { fabric } from "fabric";
import {
    FILL_CURSOR_SELECTED_GRID,
    GRID,
    PAD_X,
    PAD_Y,
    SIDE,
} from "../constants/gameWorld";

const newGridAssistRect = ({ x, y }) =>
    new fabric.Rect({
        height: GRID,
        width: GRID,
        left: PAD_X + x * GRID,
        top: PAD_Y + (SIDE * 3 - y - 1) * GRID,
        fill: FILL_CURSOR_SELECTED_GRID,
        selectable: false,
        hoverCursor: "default",
        strokeWidth: 0,
    });

// Stores the state of selected grids and draws them on the canvas
export default function useSelectedGrids(canvasRef) {
    const [selectedGrids, _setSelectedGrids] = useState([]);
    const selectedGridsRef = useRef([]);
    // Keep track of rects so we can remove them
    const rectsRef = useRef([]);

    const setSelectedGrids = useCallback((valueFn) => {
        selectedGridsRef.current = valueFn(selectedGridsRef.current);
        _setSelectedGrids(valueFn);
    }, []);

    // Add grids to the selection (e.g. on mouse drag)
    const addToSelection = useCallback(({ x, y }) => {
        // console.log("addToSelection", {x, y})
        setSelectedGrids((prev) => {
            if (prev.some((grid) => grid.x === x && grid.y === y)) {
                // Already added
                return prev
            } else {
                return [...prev, { x, y }];
            }
        });
    }, [setSelectedGrids]);

    // Draws the current selection on canvas
    const draw = useCallback(() => {
        if (!canvasRef.current?.getContext()) { return }

        // Reset previous rects
        if (rectsRef.current.length) {
            canvasRef.current.remove(...rectsRef.current)
            rectsRef.current = []
        }
        // Initialize rects
        selectedGrids.forEach((grid) => {
            const rect = newGridAssistRect(grid);
            rectsRef.current.push(rect);
            canvasRef.current.add(rect);
        });
        canvasRef.current.requestRenderAll();
    }, [selectedGrids, canvasRef]);

    // Reset selection
    const reset = useCallback(() => {
        setSelectedGrids(() => [])
    }, [setSelectedGrids])

    // Draw every time dependencies change
    useEffect(() => {
        draw();
    }, [draw]);

    return {
        addToSelection,
        draw,
        reset,
        selectedGrids,
        selectedGridsRef,
    };
}
