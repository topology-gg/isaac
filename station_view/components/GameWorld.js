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
    console.log("device_emap:", device_emap)

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
            console.log("useEffect!")
        }, []
    );

    const addGrid = canvi => {
        const GRID = 8 // grid size
        const PAD = 50 // pad size
        const SIDE = 25 // number of grids per size (planet dimension)
        const STROKE = 'rgba(200,200,200,1)' // grid stroke color

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

    const addDevices = canvi => {

        // TODO

        canvi.renderAll();
    }

    // const canvas = new fabric.Canvas(
    //     'c', {
    //         height: 600,
    //         width: 600,
    //         backgroundColor: 'rgba(255, 73, 64, 0.6)'
    //     }
    // )

    //
    // Logic to draw on the Fabric canvas
    //
    // var grid = 600 / 25;
    // for (var i = 0; i < (600 / grid); i++) {
    //     canvas.add(new fabric.Line([ i * grid, 0, i * grid, 600], { stroke: '#ccc', selectable: false }));
    //     canvas.add(new fabric.Line([ 0, i * grid, 600, i * grid], { stroke: '#ccc', selectable: false }))
    // }

    //
    // Return component
    //
    return(
    <div>
        <button onClick={() => addGrid(canvas)}> Grid </button>
        <button onClick={() => addDevices(canvas)}> Devices </button>
        <canvas id="c" />
    </div>
    );
}

// export default class GameWorld extends Component {
//     componentDidMount() {

//         //
//         // Logic to retrieve state from Starknet
//         //
//         const { contract } = useUniverseContract()
//         const { account } = useStarknet()
//         const { data: device_emap } = useStarknetCall({
//             contract,
//             method: 'anyone_view_device_deployed_emap',
//             args: []
//         })
//         console.log("device_emap:", device_emap)

//         //
//         // Logic to initialize a Fabric canvas
//         //
//         const canvas = new fabric.Canvas(
//             'c', {
//                 height: 600,
//                 width: 600,
//                 backgroundColor: 'rgba(255, 73, 64, 0.6)'
//             }
//         )

//         //
//         // Logic to draw on the Fabric canvas
//         //
//         var grid = 600 / 50;
//         for (var i = 0; i < (600 / grid); i++) {
//             canvas.add(new fabric.Line([ i * grid, 0, i * grid, 600], { stroke: '#ccc', selectable: false }));
//             canvas.add(new fabric.Line([ 0, i * grid, 600, i * grid], { stroke: '#ccc', selectable: false }))
//         }
//     }

//     render() {
//         return (
//             <div>
//                 <canvas id="c" />
//             </div>
//         )
//     }
// }