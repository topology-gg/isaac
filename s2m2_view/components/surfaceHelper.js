import { EnvironmentMap } from "@react-three/drei";

export const NUM_SURFACES = 6;

export const createSurface = (device_emap, surface_dim) => {

    console.log("> createSurface(): device_emap", device_emap, "surface_dim", surface_dim)

    // Initialize array
    let surface = Array.from(Array(NUM_SURFACES), () => (
        Array.from(Array(surface_dim), () =>
            // new Array(SURFACE_WIDTH).fill(null).map((val, idx) => getRandomInt(2))
            new Array(surface_dim).fill(0)
        )
    ))

    // For each deployed device in emap, find the face it belongs to, find normalized coord, and update surface
    for (const entry of device_emap[0]){
        console.log("> entry", entry)
        const x = entry.grid.x.toNumber()
        const y = entry.grid.y.toNumber()
        const typ = entry.type.toNumber()
        console.log('entry grid',x, y, typ)
        const ret = getFaceAndOffset (x, y, surface_dim)
        console.log ("> getFaceAndOffset():", ret)

        const x_norm = x - ret.offset.x
        const y_norm = y - ret.offset.y
        surface[ret.face][x_norm][y_norm] = typ
    }

    return surface
}

function getFaceAndOffset (x, y, dim) {
    if ( 0 <= x && x <= dim-1 && dim <= y && y <= 2*dim-1 ) {
        return {face: 0, offset: {x : 0, y : dim}}
    }
    else if (dim <= x && x <= 2*dim-1 && 0 <= y && y <= dim-1) {
        return {face: 1, offset: {x : dim, y : 0}}
    }
    else if (dim <= x && x <= 2*dim-1 && dim <= y && y <= 2*dim-1) {
        return {face: 2, offset: {x : dim, y : dim}}
    }
    else if (dim <= x && x <= 2*dim-1 && 2*dim <= y && y <= 3*dim-1) {
        return {face: 3, offset: {x : dim, y : 2*dim}}
    }
    else if (2*dim <= x && x <= 3*dim-1 && dim <= y && y <= 2*dim-1) {
        return {face: 4, offset: {x : 2*dim, y : dim}}
    }
    else if (3*dim <= x && x <= 4*dim-1 && dim <= y && y <= 2*dim-1) {
        return {face: 5, offset: {x : 3*dim, y : dim}}
    }
    else {
        console.log ("> uhhh!")
        return {face: 5, offset: {x : 3*dim, y : dim}}
    }
}

// function getRandomInt (max) {
//     return Math.floor(Math.random() * max);
// }