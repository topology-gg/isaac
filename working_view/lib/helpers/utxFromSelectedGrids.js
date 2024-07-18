export default function utxFromSelectedGrids (selectedGrids) {
    const src = selectedGrids[0];
    const dst = selectedGrids[selectedGrids.length - 1];
    const grids = selectedGrids.slice(1, -1).map((grid) => ({
        x: grid.x,
        y: grid.y,
    }));

    return {
        src,
        dst,
        grids
    }
}
