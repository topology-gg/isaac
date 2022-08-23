import { GRID, PAD_X, PAD_Y, SIDE } from "../constants/gameWorld"

function x_transform_normalized_to_canvas (x) {
    return PAD_X + x*GRID
}
function y_transform_normalized_to_canvas (y) {
    return PAD_Y + (SIDE*3 - y - 1)*GRID
}

export default function map_face_to_left_top(face) {
    if (face === 0) {
        return {
            left: x_transform_normalized_to_canvas(0),
            top: y_transform_normalized_to_canvas(2 * SIDE - 1),
        };
    }
    if (face === 1) {
        return {
            left: x_transform_normalized_to_canvas(SIDE),
            top: y_transform_normalized_to_canvas(SIDE - 1),
        };
    }
    if (face === 2) {
        return {
            left: x_transform_normalized_to_canvas(SIDE),
            top: y_transform_normalized_to_canvas(2 * SIDE - 1),
        };
    }
    if (face === 3) {
        return {
            left: x_transform_normalized_to_canvas(SIDE),
            top: y_transform_normalized_to_canvas(3 * SIDE - 1),
        };
    }
    if (face === 4) {
        return {
            left: x_transform_normalized_to_canvas(2 * SIDE),
            top: y_transform_normalized_to_canvas(2 * SIDE - 1),
        };
    } else {
        // face === 5
        return {
            left: x_transform_normalized_to_canvas(3 * SIDE),
            top: y_transform_normalized_to_canvas(2 * SIDE - 1),
        };
    }
}
