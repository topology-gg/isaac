export const NUM_SURFACES = 6;
export const SURFACE_WIDTH = 100;
export const SURFACE_HEIGHT = 100;

export const createSurface = (phi) => {
    console.log("phi: ", phi)
    return Array.from(Array(NUM_SURFACES), () => (
        Array.from(Array(SURFACE_HEIGHT), () =>
            new Array(SURFACE_WIDTH).fill(null).map((val, idx) => getRandomInt(2))
        )
    ))
}


function getRandomInt(max) {
    return Math.floor(Math.random() * max);
}