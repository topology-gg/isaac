import { SIDE } from "../constants/gameWorld";

export default function find_face_given_grid(x, y) {
    const x0 = x >= 0 && x < SIDE;
    const x1 = x >= SIDE && x < SIDE * 2;
    const x2 = x >= SIDE * 2 && x < SIDE * 3;
    const x3 = x >= SIDE * 3 && x < SIDE * 4;

    const y0 = y >= 0 && y < SIDE;
    const y1 = y >= SIDE && y < SIDE * 2;
    const y2 = y >= SIDE * 2 && y < SIDE * 3;

    // face 0
    if (x0 && y1) {
        return 0;
    }

    // face 1
    if (x1 && y0) {
        return 1;
    }

    // face 2
    if (x1 && y1) {
        return 2;
    }

    // face 3
    if (x1 && y2) {
        return 3;
    }

    // face 4
    if (x2 && y1) {
        return 4;
    }

    // face 5
    if (x3 && y1) {
        return 5;
    }

    return -1;
}
