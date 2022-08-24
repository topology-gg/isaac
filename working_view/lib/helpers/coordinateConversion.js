import { GRID, PAD_X, PAD_Y, SIDE } from "../constants/gameWorld"

export const coordToGrid = (x, y) => {
    const gridX = Math.floor( (x - PAD_X) / GRID )
    const gridY = SIDE*3 - 1 - Math.floor( (y - PAD_Y) / GRID )
    // const valid = is_valid_coord (gridX, gridY)

    return {
        x: gridX,
        y: gridY
    }
}
