import {
    GRID,
    HOVER_DEVICE_COLOR,
    HOVER_DEVICE_STROKE_WIDTH,
    PAD_X,
    PAD_Y,
    SIDE,
    STROKE_CURSOR_FACE,
    STROKE_WIDTH_CURSOR_FACE,
    STROKE_WIDTH_GRID_MEDIUM
} from "../../lib/constants/gameWorld";

import { fabric } from 'fabric';

export function createCursorGridRect() {
    return new fabric.Rect({
        height: GRID,
        width: GRID,
        left: PAD_X,
        top: PAD_Y,
        fill: '#00000000',
        selectable: false,
        hoverCursor: 'default',
        visible: false,
        strokeWidth: STROKE_WIDTH_GRID_MEDIUM,
        stroke: '#FFFFFF'
    });
}

export function createCursorFaceRect() {
    return new fabric.Rect({
        height: GRID*SIDE,
        width: GRID*SIDE,
        left: PAD_X,
        top: PAD_Y,
        fill: "",
        stroke: STROKE_CURSOR_FACE,
        strokeWidth: STROKE_WIDTH_CURSOR_FACE,
        selectable: false,
        hoverCursor: 'default',
        visible: false
    });
}

export function createCursorHoverDeviceRect () {
    return new fabric.Rect({
        height: GRID,
        width: GRID,
        left: PAD_X,
        top: PAD_Y,
        fill: '',
        selectable: false,
        hoverCursor: 'default',
        visible: false,
        stroke: HOVER_DEVICE_COLOR,
        strokeLineJoin: 'round',
        opacity: 1.0,
        strokeWidth: HOVER_DEVICE_STROKE_WIDTH,
    });
}

export function createPlacementAssistRect () {
    return new fabric.Rect({
        height: GRID,
        width: GRID,
        left: PAD_X,
        top: PAD_Y,
        fill: '',
        strokeWidth: 0,
        selectable: false,
        hoverCursor: 'default',
        visible: true,
        opacity: 0.5,
    })
}
