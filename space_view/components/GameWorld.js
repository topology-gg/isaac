import React, { Component, useState, useEffect, useRef, useMemo } from "react";
import { fabric } from 'fabric';
import { BigNumber } from 'bignumber.js'
import {
    useStarknet,
    useContract,
    useStarknetCall,
    useStarknetInvoke
} from '@starknet-react/core'

import UniverseAbi from '../abi/universe_abi.json'
const UNIVERSE_ADDR = '0x0758e8e3153a61474376838aeae42084dae0ef55e0206b19b2a85e039d1ef180' // universe #0
function useUniverseContract() {
    return useContract({ abi: UniverseAbi, address: UNIVERSE_ADDR })
}

//
// Constants
//
const STARK_PRIME = new BigNumber('3618502788666131213697322783095070105623107215331596699973092056135872020481')
const STARK_PRIME_HALF = new BigNumber('1809251394333065606848661391547535052811553607665798349986546028067936010240')
const STROKE = 'rgba(200,200,200,1)' // grid stroke color

export default function GameWorld() {

    fabric.Object.prototype.selectable = false;

    // Credits:
    // https://aprilescobar.medium.com/part-1-fabric-js-on-react-fabric-canvas-e4094e4d0304
    // https://stackoverflow.com/questions/60723440/problem-in-attaching-event-to-canvas-in-useeffect
    // https://eliaslog.pw/how-to-add-multiple-refs-to-one-useref-hook/

    //
    // Logic to retrieve state from Starknet
    //
    const { contract } = useUniverseContract()
    const { account } = useStarknet()

    const { data: macro_state } = useStarknetCall({
        contract,
        method: 'macro_state_curr_read',
        args: []
    })
    const { data: phi } = useStarknetCall({
        contract,
        method: 'phi_curr_read',
        args: []
    })

    //
    // Logic to initialize a Fabric canvas
    //
    const [canvas, setCanvas] = useState([]);
    const [hasDrawn, _] = useState([]);
    const [windowDimensions, setWindowDimensions] = useState (getWindowDimensions());
    const _refs = useRef([]);
    // const _canvasRef = useRef(0);
    // const _hasDrawnRef =

    useEffect (() => {
        _refs.current[0] = new fabric.Canvas('c', {
            height: 1500,
            width: 1500,
            backgroundColor: '#00202C',
            selection: false
        })
        _refs.current[1] = false
    }, []);

    useEffect (() => {
        if (!_refs.current[1]) {
            drawWorld (_refs.current[0])
        }
    }, [macro_state, phi]);

    useEffect(() => {
        function handleResize() {
            setWindowDimensions (getWindowDimensions());
        }

        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);


    const drawWorld = canvi => {
        // console.log ("drawWorld")
        if (macro_state && phi) {
            if (macro_state.macro_state && phi.phi) {
                console.log ("macro_state:", macro_state.macro_state)
                console.log ("phi", phi.phi)

                drawSpace (canvi)
            //     drawGrid (canvi)
            //     drawDevices (canvi)
                _refs.current[1] = true
            // }
            }
        }

    }

    const drawSpace = canvi => {
        const window_dim = windowDimensions
        console.log ("window_dim", window_dim)

        //
        // Draw grid lines first
        //
        const line_vertical = new fabric.Line(
            [ORIGIN_X, 0, ORIGIN_X, window_dim.height],
            {
                stroke: 'grey',
                selectable: false
            },
        );
        const line_horizontal = new fabric.Line(
            [0, ORIGIN_Y, window_dim.width, ORIGIN_Y],
            {
                stroke: 'grey',
                selectable: false
            }
        );
        canvi.add (line_vertical)
        canvi.add (line_horizontal)

        const plnt_x = fp_felt_to_num(new BigNumber(macro_state.macro_state.plnt.q.x))
        const plnt_y = fp_felt_to_num(new BigNumber(macro_state.macro_state.plnt.q.y))
        const sun0_x = fp_felt_to_num(new BigNumber(macro_state.macro_state.sun0.q.x))
        const sun0_y = fp_felt_to_num(new BigNumber(macro_state.macro_state.sun0.q.y))
        const sun1_x = fp_felt_to_num(new BigNumber(macro_state.macro_state.sun1.q.x))
        const sun1_y = fp_felt_to_num(new BigNumber(macro_state.macro_state.sun1.q.y))
        const sun2_x = fp_felt_to_num(new BigNumber(macro_state.macro_state.sun2.q.x))
        const sun2_y = fp_felt_to_num(new BigNumber(macro_state.macro_state.sun2.q.y))

        const SUN_RADIUS = 0.383 // from contract
        const PLNT_RADIUS = 0.05 // arbitrary
        const ORIGIN_X = window_dim.width / 2
        const ORIGIN_Y = window_dim.height / 2
        const DISPLAY_SCALE = 50

        const sun0_circle = new fabric.Circle ({
            left: ORIGIN_X + sun0_x.toString(10) *DISPLAY_SCALE,
            top:  ORIGIN_Y + sun0_y.toString(10) *DISPLAY_SCALE,
            radius: SUN_RADIUS * DISPLAY_SCALE,
            stroke: 'black',
            strokeWidth: 1,
            fill: '#6289AF',
            selectable: false,
            hoverCursor: "pointer"
        });

        const sun1_circle = new fabric.Circle ({
            left: ORIGIN_X + sun1_x.toString(10) *DISPLAY_SCALE,
            top:  ORIGIN_Y + sun1_y.toString(10) *DISPLAY_SCALE,
            radius: SUN_RADIUS * DISPLAY_SCALE,
            stroke: 'black',
            strokeWidth: 1,
            fill: '#FF8B58',
            selectable: false,
            hoverCursor: "pointer"
        });

        const sun2_circle = new fabric.Circle ({
            left: ORIGIN_X + sun2_x.toString(10) *DISPLAY_SCALE,
            top:  ORIGIN_Y + sun2_y.toString(10) *DISPLAY_SCALE,
            radius: SUN_RADIUS * DISPLAY_SCALE,
            stroke: 'black',
            strokeWidth: 1,
            fill: '#A05760',
            selectable: false,
            hoverCursor: "pointer"
        });

        const plnt_rect = new fabric.Rect({
            left: ORIGIN_X + plnt_x.toString(10) *DISPLAY_SCALE,
            top:  ORIGIN_Y + plnt_y.toString(10) *DISPLAY_SCALE,
            height: PLNT_RADIUS * 2 * DISPLAY_SCALE,
            width: PLNT_RADIUS * 2 * DISPLAY_SCALE,
            angel: 60,
            stroke: 'black',
            strokeWidth: 2,
            fill: '',
            selectable: false,
            hoverCursor: "pointer"
        });

        const plnt_circle = new fabric.Circle ({
            left: ORIGIN_X + plnt_x.toString(10) *DISPLAY_SCALE,
            top:  ORIGIN_Y + plnt_y.toString(10) *DISPLAY_SCALE,
            radius: PLNT_RADIUS * DISPLAY_SCALE,
            stroke: 'black',
            strokeWidth: 0.5,
            fill: '#8E8E8E',
            selectable: false,
            hoverCursor: "pointer"
        });

        canvi.add (sun0_circle)
        canvi.add (sun1_circle)
        canvi.add (sun2_circle)
        canvi.add (plnt_circle)
        console.log ("planet rect angle:", plnt_rect.angle)

        // for (const entry of device_emap.emap){
        //     const x = entry.grid.x.toNumber()
        //     const y = entry.grid.y.toNumber()
        //     const typ = entry.type.toNumber()
        //     // console.log("> entry: ", typ, x, y)

        //     const device_dim = DEVICE_DIM_MAP.get(typ)
        //     const device_color = DEVICE_COLOR_MAP.get(typ)

        //     const rect = new fabric.Rect({
        //         height: device_dim*GRID,
        //         width: device_dim*GRID,
        //         left: PAD + x*GRID,
        //         top: PAD + (SIDE*3-y-device_dim)*GRID,
        //         fill: device_color
        //         });
        //     canvi.add(rect);
        // }
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
        // reference: https://www.htmlgoodies.com/html5/drawing-shapes-with-the-fabric-js-canvas-library/

        // if (device_emap && utb_grids) {
            // if (device_emap.emap && utb_grids.grids) {

        //
        // Draw devices
        //
        for (const entry of device_emap.emap){
            const x = entry.grid.x.toNumber()
            const y = entry.grid.y.toNumber()
            const typ = entry.type.toNumber()
            // console.log("> entry: ", typ, x, y)

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
            // console.log("> utb:",x, y)

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

            // }
        // }

        canvi.renderAll();
    }


    //
    // Return component
    //
    return(
    <div>
        <canvas id="c" />
    </div>
    );
}

function fp_felt_to_num(felt) {
    BigNumber.config({ EXPONENTIAL_AT: 76 })

    const felt_bn = new BigNumber(felt) // for weird reasons, the input `felt` may not be BigNumber, so this casting is required
    const felt_minus_half_prime = felt_bn.minus(STARK_PRIME_HALF)

    const felt_signed = felt_minus_half_prime.isPositive() ? felt_bn.minus(STARK_PRIME) : felt_bn;
    const felt_descaled = felt_signed.dividedBy(10 ** 20)

    return felt_descaled
  }


function fp_felt_to_string(felt) {

    const felt_descaled = fp_felt_to_num (felt)

    return felt_descaled.toString(10)
}


// function useWindowDimensions() {
//     const [windowDimensions, setWindowDimensions] = useState(getWindowDimensions());

//     useEffect(() => {
//         function handleResize() {
//             setWindowDimensions (getWindowDimensions());
//         }

//         window.addEventListener('resize', handleResize);
//         return () => window.removeEventListener('resize', handleResize);
//     }, []);

//     return windowDimensions;
// }

function getWindowDimensions() {
    if (typeof window !== 'undefined') {
        const { innerWidth: width, innerHeight: height } = window;
        // console.log("window is defined!")
        return { width, height };
    } else {
        // console.log('You are on the server')
        return { width : 700, height : 815 }
    }
}