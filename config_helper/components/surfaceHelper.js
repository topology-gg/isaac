export const NUM_SURFACES = 6;
export const SURFACE_WIDTH = 16;
export const SURFACE_HEIGHT = 16;

export const createSurface = () => {
    return Array.from(Array(6), () => (
        Array.from(Array(16), () =>
            new Array(16).fill(null).map((val, idx) => getRandomInt(2))
        )
    ))
}


function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}