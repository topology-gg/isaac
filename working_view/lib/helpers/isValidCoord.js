import find_face_given_grid from "./findFaceGivenGrid";

export default function is_valid_coord(x, y) {
    const face = find_face_given_grid(x, y);

    if (face >= 0) {
        return true;
    } else {
        return false;
    }
}
