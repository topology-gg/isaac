import React, { Component, useState, useEffect, useMemo } from "react";
import { fabric } from 'fabric';

import {
    useStarknet,
    useContract,
    useStarknetCall,
    useStarknetInvoke
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x022a9f674dc96f8faeff7498b61fab9ecccd6aa3d42953d398e570fca54ef3b3' // universe #0
function useUniverseContract() {
    return useContract({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}

//
// Constants
//
const GRID = 8 // grid size
const PAD = 50 // pad size
const SIDE = 25 // number of grids per size (planet dimension)
const STROKE = 'rgba(200,200,200,1)' // grid stroke color

const DEVICE_DIM_MAP = new Map();
DEVICE_DIM_MAP.set(0, 1);
DEVICE_DIM_MAP.set(1, 3);
DEVICE_DIM_MAP.set(2, 1);
DEVICE_DIM_MAP.set(3, 2);
DEVICE_DIM_MAP.set(4, 1);
DEVICE_DIM_MAP.set(5, 1);
DEVICE_DIM_MAP.set(6, 1);
DEVICE_DIM_MAP.set(7, 2);
DEVICE_DIM_MAP.set(8, 2);
DEVICE_DIM_MAP.set(9, 2);
DEVICE_DIM_MAP.set(10, 2);
DEVICE_DIM_MAP.set(11, 2);
DEVICE_DIM_MAP.set(14, 5);
DEVICE_DIM_MAP.set(15, 5);

const DEVICE_COLOR_MAP = new Map();
DEVICE_COLOR_MAP.set(0, "black");
DEVICE_COLOR_MAP.set(1, "black");
DEVICE_COLOR_MAP.set(2, "red");
DEVICE_COLOR_MAP.set(3, "red");
DEVICE_COLOR_MAP.set(4, "red");
DEVICE_COLOR_MAP.set(5, "red");
DEVICE_COLOR_MAP.set(6, "red");
DEVICE_COLOR_MAP.set(7, "orange");
DEVICE_COLOR_MAP.set(8, "orange");
DEVICE_COLOR_MAP.set(9, "orange");
DEVICE_COLOR_MAP.set(10, "orange");
DEVICE_COLOR_MAP.set(11, "orange");
DEVICE_COLOR_MAP.set(12, "rgba(100,100,100,0.3)");
DEVICE_COLOR_MAP.set(13, "grey");
DEVICE_COLOR_MAP.set(14, "yellow");
DEVICE_COLOR_MAP.set(15, "blue");

// Copied from Isaac's `constants.cairo`:
// namespace ns_device_types:
//     const DEVICE_SPG = 0 # solar power generator
//     const DEVICE_NPG = 1 # nuclear power generator
//     const DEVICE_FE_HARV = 2 # iron harvester
//     const DEVICE_AL_HARV = 3 # aluminum harvester
//     const DEVICE_CU_HARV = 4 # copper harvester
//     const DEVICE_SI_HARV = 5 # silicon harvester
//     const DEVICE_PU_HARV = 6 # plutoniium harvester
//     const DEVICE_FE_REFN = 7 # iron refinery
//     const DEVICE_AL_REFN = 8 # aluminum refinery
//     const DEVICE_CU_REFN = 9 # copper refinery
//     const DEVICE_SI_REFN = 10 # silicon refinery
//     const DEVICE_PEF = 11 # plutonium enrichment facility
//     const DEVICE_UTB = 12 # universal transportation belt
//     const DEVICE_UTL = 13 # universal transmission line
//     const DEVICE_UPSF = 14 # universal production and storage facility
//     const DEVICE_NDPE = 15 # nuclear driller & propulsion engine

//     const DEVICE_TYPE_COUNT = 16
//     const DEVICE_PG_MAX = 1
//     const DEVICE_HARVESTER_MIN = 2
//     const DEVICE_HARVESTER_MAX = 6
//     const DEVICE_TRANSFORMER_MIN = 7
//     const DEVICE_TRANSFORMER_MAX = 11
// end

// Device footprint - copied from `constants.cairo`
// dw 1 # spg
// dw 3 # npg
// dw 1 # fe harv
// dw 1 # al harv
// dw 1 # cu harv
// dw 1 # si harv
// dw 1 # pu harv
// dw 2 # fe refn
// dw 2 # al refn
// dw 2 # cu refn
// dw 2 # si refn
// dw 2 # pef
// dw 0
// dw 0
// dw 5 # opsf
// dw 5 # ndpe

export default function GameWorld() {

    // Credits:
    // https://aprilescobar.medium.com/part-1-fabric-js-on-react-fabric-canvas-e4094e4d0304
    //

    //
    // Logic to retrieve state from Starknet
    //
    const { contract } = useUniverseContract()
    const { account } = useStarknet()
    const { data: device_emap } = useStarknetCall({
        contract,
        method: 'anyone_view_device_deployed_emap',
        args: []
    })
    const { data: utb_grids } = useStarknetCall({
        contract,
        method: 'anyone_view_all_utx_grids',
        args: [12]
    })
    const { data: utl_grids } = useStarknetCall({
        contract,
        method: 'anyone_view_all_utx_grids',
        args: [13]
    })

    //
    // Logic to initialize a Fabric canvas
    //
    const [canvas, setCanvas] = useState(null);
    useEffect (() => {
            setCanvas(
                new fabric.Canvas('c', {
                    height: 700,
                    width: 1200,
                    backgroundColor: 'white'
                    // backgroundColor: 'rgba(255, 73, 64, 0.6)'
                })
            );
            console.log("useEffect() called.")
        }, []
    );

    const drawWorld = canvi => {
        drawGrid (canvi)
        drawDevices (canvi)
    }

    const drawGrid = canvi => {

        //
        // Grid lines parallel to Y-axis
        //
        for (var xi = 0; xi < SIDE; xi++){
            canvi.add(new fabric.Line([
                PAD + xi*GRID,
                PAD + SIDE*GRID,
                PAD + xi*GRID,
                PAD + SIDE*GRID*2
            ], { stroke: STROKE, selectable: false }));
        }
        for (var xi = SIDE; xi < SIDE*2+1; xi++){
            canvi.add(new fabric.Line([
                PAD + xi*GRID,
                PAD + 0,
                PAD + xi*GRID,
                PAD + SIDE*GRID*3
            ], { stroke: STROKE, selectable: false }));
        }
        for (var xi = 2*SIDE+1; xi < SIDE*4+1; xi++){
            canvi.add(new fabric.Line([
                PAD + xi*GRID,
                PAD + SIDE*GRID,
                PAD + xi*GRID,
                PAD + SIDE*GRID*2
            ], { stroke: STROKE, selectable: false }));
        }

        //
        // Grid lines parallel to X-axis
        //
        for (var yi = 0; yi < SIDE; yi++){
            canvi.add(new fabric.Line([
                PAD + SIDE*GRID,
                PAD + yi*GRID,
                PAD + SIDE*GRID*2,
                PAD + yi*GRID
            ], { stroke: STROKE, selectable: false }));
        }
        for (var yi = SIDE; yi < 2*SIDE+1; yi++){
            canvi.add(new fabric.Line([
                PAD + 0,
                PAD + yi*GRID,
                PAD + SIDE*GRID*4,
                PAD + yi*GRID
            ], { stroke: STROKE, selectable: false }));
        }
        for (var yi = 2*SIDE+1; yi < 3*SIDE+1; yi++){
            canvi.add(new fabric.Line([
                PAD + SIDE*GRID,
                PAD + yi*GRID,
                PAD + SIDE*GRID*2,
                PAD + yi*GRID
            ], { stroke: STROKE, selectable: false }));
        }

        canvi.renderAll();
    }

    const drawDevices = canvi => {

        // Basic geometries provided by Fabric:
        // circle, ellipse, rectangle, triangle

        if (device_emap && utb_grids) {
            if (device_emap.emap && utb_grids.grids) {

                //
                // Draw devices
                //
                for (const entry of device_emap.emap){
                    const x = entry.grid.x.toNumber()
                    const y = entry.grid.y.toNumber()
                    const typ = entry.type.toNumber()
                    console.log("> entry: ", typ, x, y)

                    const device_dim = DEVICE_DIM_MAP.get(typ)
                    const device_color = DEVICE_COLOR_MAP.get(typ)

                    const rect = new fabric.Rect({
                        height: device_dim*GRID,
                        width: device_dim*GRID,
                        left: PAD + x*GRID,
                        top: PAD + (SIDE*3-y-device_dim)*GRID,
                        fill: device_color
                     });
                     canvi.add(rect);
                }

                //
                // Draw utbs
                //
                for (const grid of utb_grids.grids){
                    console.log("> utb:",x, y)

                    const x = grid.x.toNumber()
                    const y = grid.y.toNumber()
                    const device_dim = 1
                    const device_color = DEVICE_COLOR_MAP.get(12)

                    const rect = new fabric.Rect({
                        height: device_dim*GRID,
                        width: device_dim*GRID,
                        left: PAD + x*GRID,
                        top: PAD + (SIDE*3-y-device_dim)*GRID,
                        fill: device_color
                     });
                     canvi.add(rect);
                }

            }
        }

        canvi.renderAll();
    }

    //
    // Return component
    //
    return(
    <div>
        <button onClick={() => drawWorld(canvas)}> Draw </button>
        {/* <button onClick={() => drawDevices(canvas)}> Devices </button> */}
        <canvas id="c" />
    </div>
    );
}
