import { EnvironmentMap } from "@react-three/drei";

export const NUM_SURFACES = 6;

export const createSurface = (device_emap, utb_grids, surface_dim) => {

    console.log("> createSurface(): device_emap", device_emap, "utb_grids", utb_grids, "surface_dim", surface_dim)

    // Initialize array
    let surface = Array.from(Array(NUM_SURFACES), () => (
        Array.from(Array(surface_dim), () =>
            // new Array(SURFACE_WIDTH).fill(null).map((val, idx) => getRandomInt(2))
            new Array(surface_dim).fill(0)
        )
    ))

    if (device_emap.emap) {
        for (const entry of device_emap.emap){
            // console.log("> entry", entry)
            const x = entry.grid.x.toNumber()
            const y = entry.grid.y.toNumber()
            const typ = entry.type.toNumber()
            const ret = getFaceAndOffset (x, y, surface_dim)
            const surf = mapFaceToSurfaceIndex (ret.face)
            console.log('device grid', x, y, typ, 'on face', ret.face)

            const x_norm = x - ret.offset.x
            const y_norm = y - ret.offset.y
            surface[surf][x_norm][y_norm] = typ
        }
    }
    // For each deployed device in emap, find the face it belongs to, find normalized coord, and update surface
    if (utb_grids.grids) {
        for (const grid of utb_grids.grids){
            const x = grid.x.toNumber()
            const y = grid.y.toNumber()
            const ret = getFaceAndOffset (x, y, surface_dim)
            const surf = mapFaceToSurfaceIndex (ret.face)
            console.log('utb grid', x, y, 'on face', ret.face)

            const x_norm = x - ret.offset.x
            const y_norm = y - ret.offset.y
            surface[surf][x_norm][y_norm] = 12
        }
    }

    return surface
}

function mapFaceToSurfaceIndex (face) {
    if (face == 0) {
        return 0
    }
    else if (face == 1) {
        return 4
    }
    else if (face == 2) {
        return 3
    }
    else if (face == 3) {
        return 5
    }
    else if (face == 4) {
        return 1
    }
    else if (face == 5) {
        return 2
    }
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