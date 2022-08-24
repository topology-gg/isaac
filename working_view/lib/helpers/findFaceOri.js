import { SIDE } from "../constants/gameWorld"

export default function find_face_ori (face) {
    if (face === 0) {
        return [0, SIDE]
    }
    else if (face === 1) {
        return [SIDE, 0]
    }
    else if (face === 2) {
        return [SIDE, SIDE]
    }
    else if (face === 3) {
        return [SIDE, 2*SIDE]
    }
    else if (face === 4) {
        return [2*SIDE, SIDE]
    }
    else { // face === 5
        return [3*SIDE, SIDE]
    }
}
