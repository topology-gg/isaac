import { GRID, PAD_X, PAD_Y, SIDE } from "../constants/gameWorld"

export function convert_screen_to_grid_x(x) {
    return Math.floor((x - PAD_X) / GRID);
}

export function convert_screen_to_grid_y(y) {
    return SIDE * 3 - 1 - Math.floor((y - PAD_Y) / GRID);
}
