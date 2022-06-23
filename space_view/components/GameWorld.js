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
import { useMacroStates } from '../lib/api'

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


function createTriangle(x, y, w, h, rotation)
{
    var width  = w;
    var height = h;
    var pos = fabric.util.rotatePoint(
        new fabric.Point(x, y),
        new fabric.Point(x + width / 2, y + height / 3 * 2),
        fabric.util.degreesToRadians(rotation)
    );
    return new fabric.Triangle(
    {
        width: width,
        height: height,
        selectable: false,
        fill: STROKE,
        stroke: STROKE,
        strokeWidth: 1,
        left: pos.x,
        top: pos.y,
        angle: rotation,
        hoverCursor: 'default'
    });
}

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

    const { data: macro_states } = useMacroStates()

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
    }, [macro_states]);

    useEffect(() => {
        function handleResize() {
            setWindowDimensions (getWindowDimensions());
        }

        window.addEventListener('resize', handleResize);
        return () => window.removeEventListener('resize', handleResize);
    }, []);


    const drawWorld = canvi => {
        // console.log ("drawWorld")
        if (macro_states && macro_states.macro_states.length > 0) {
            console.log ("fetched", macro_states.macro_states.length, "macro_states in total.")
            const macro_state = macro_states.macro_states[0]
            // decode base64 to bytes, then bytes to BigNumber
            const phi = new BigNumber(Buffer.from(macro_state.phi, 'base64').toString('hex'), 16)

            console.log ("dynamics:", macro_state.dynamics)
            console.log ("phi", phi.toString())

            drawSpace (canvi)
            //     drawGrid (canvi)
            //     drawDevices (canvi)
            _refs.current[1] = true
        }

    }

    const drawSpace = canvi => {
        const window_dim = windowDimensions
        const macro_state = macro_states.macro_states[0]
        const dynamics = macro_state.dynamics

        console.log ("window_dim", window_dim)

        //
        // Constants
        //
        const SUN0_RADIUS = 1.495 // from contract
        const SUN1_RADIUS = 0.862 // from contract
        const SUN2_RADIUS = 0.383 // from contract
        const PLNT_RADIUS = 0.05 // arbitrary
        const ORIGIN_X = window_dim.width / 2
        const ORIGIN_Y = window_dim.height / 2
        const DISPLAY_SCALE = 60
        const GRID_STYLE = {
            stroke: '#CCCCCC',
            strokeWidth: 0.5,
            selectable: false
        }

        //
        // Compute coordinates of celestial bodies
        //
        const plnt_x = dynamics.planet.q.x
        const plnt_y = dynamics.planet.q.y
        const sun0_x = dynamics.sun0.q.x
        const sun0_y = dynamics.sun0.q.y
        const sun1_x = dynamics.sun1.q.x
        const sun1_y = dynamics.sun1.q.y
        const sun2_x = dynamics.sun2.q.x
        const sun2_y = dynamics.sun2.q.y

        const sun0_left = ORIGIN_X + (sun0_x.toString(10)-SUN0_RADIUS) *DISPLAY_SCALE
        const sun0_top  = ORIGIN_Y + (sun0_y.toString(10)-SUN0_RADIUS) *DISPLAY_SCALE
        const sun0_left_center = ORIGIN_X + sun0_x.toString(10) *DISPLAY_SCALE
        const sun0_top_center  = ORIGIN_Y + sun0_y.toString(10) *DISPLAY_SCALE

        const sun1_left = ORIGIN_X + (sun1_x.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE
        const sun1_top  = ORIGIN_Y + (sun1_y.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE
        const sun1_left_center = ORIGIN_X + sun1_x.toString(10) *DISPLAY_SCALE
        const sun1_top_center  = ORIGIN_Y + sun1_y.toString(10) *DISPLAY_SCALE

        const sun2_left = ORIGIN_X + (sun2_x.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE
        const sun2_top  = ORIGIN_Y + (sun2_y.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE
        const sun2_left_center = ORIGIN_X + sun2_x.toString(10) *DISPLAY_SCALE
        const sun2_top_center  = ORIGIN_Y + sun2_y.toString(10) *DISPLAY_SCALE

        const plnt_left_center = ORIGIN_X + plnt_x.toString(10) *DISPLAY_SCALE
        const plnt_top_center  = ORIGIN_Y + plnt_y.toString(10) *DISPLAY_SCALE

        //
        // Draw grid lines first
        //
        const line0_vertical = new fabric.Line(
            [sun0_left_center, 0, sun0_left_center, sun0_top_center], GRID_STYLE);
        // const line0_horizontal = new fabric.Line(
        //     [0, sun0_top_center, sun0_left_center, sun0_top_center], GRID_STYLE);

        // const line1_vertical = new fabric.Line(
        //     [sun1_left_center, 0, sun1_left_center, sun1_top_center], GRID_STYLE);
        const line1_horizontal = new fabric.Line(
            [0, sun1_top_center, sun1_left_center, sun1_top_center], GRID_STYLE);

        // const line2_vertical = new fabric.Line(
        //     [sun2_left_center, 0, sun2_left_center, sun2_top_center], GRID_STYLE);
        const line2_horizontal = new fabric.Line(
            [sun2_left_center, sun2_top_center, window_dim.width, sun2_top_center], GRID_STYLE);

        const line_plnt_vertical = new fabric.Line(
            [plnt_left_center, plnt_top_center, plnt_left_center, window_dim.height], GRID_STYLE);

        canvi.add (line0_vertical)
        // canvi.add (line0_horizontal)
        // canvi.add (line1_vertical)
        canvi.add (line1_horizontal)
        // canvi.add (line2_vertical)
        canvi.add (line2_horizontal)
        canvi.add (line_plnt_vertical)


        //
        // Draw textboxes
        //
        const FONT_SIZE_NAME = 15
        const FONT_SIZE_COORD = 12
        const COORD_SLICE = 6
        const sun0_coord_text = '(' + sun0_x.toString().slice(0,COORD_SLICE) + ', ' + sun0_y.toString().slice(0,COORD_SLICE) + ')'
        const sun1_coord_text = '(' + sun1_x.toString().slice(0,COORD_SLICE) + ', ' + sun1_y.toString().slice(0,COORD_SLICE) + ')'
        const sun2_coord_text = '(' + sun2_x.toString().slice(0,COORD_SLICE) + ', ' + sun2_y.toString().slice(0,COORD_SLICE) + ')'
        const plnt_coord_text = '(' + plnt_x.toString().slice(0,COORD_SLICE) + ', ' + plnt_y.toString().slice(0,COORD_SLICE) + ')'

        const tbox_plnt_bg = new fabric.Rect({
            fill: '#CCCCCC', scaleY: 0.5,
            originX: 'center', originY: 'center',
            rx: 5, ry: 5,
            width:  90, height: 80
        });
        const tbox_plnt_text = new fabric.Text(
            'EV', {
            fontSize: FONT_SIZE_NAME, originX: 'center', originY: 'bottom', fill: '#333333'
        });
        const tbox_plnt_coord_text = new fabric.Text(
            plnt_coord_text, {
            fontSize: FONT_SIZE_COORD, originX: 'center', originY: 'top', fill: '#333333'
        });
        const tbox_plnt_group = new fabric.Group(
            [ tbox_plnt_bg, tbox_plnt_text, tbox_plnt_coord_text], {
            left: plnt_left_center - 45,
            top: window_dim.height - 40
        });

        const tbox_sun0_bg = new fabric.Rect({
            fill: '#CCCCCC', scaleY: 0.5,
            originX: 'center', originY: 'center',
            rx: 5, ry: 5,
            width: 90, height: 80
        });
        const tbox_sun0_text = new fabric.Text(
            'BÖYÜK', {
            fontSize: FONT_SIZE_NAME, originX: 'center', originY: 'bottom', fill: '#333333'
        });
        const tbox_sun0_coord_text = new fabric.Text(
            sun0_coord_text, {
            fontSize: FONT_SIZE_COORD, originX: 'center', originY: 'top', fill: '#333333'
        });
        const tbox_sun0_group = new fabric.Group(
            [ tbox_sun0_bg, tbox_sun0_text, tbox_sun0_coord_text ], {
            left: sun0_left_center - 45,
            top: 0
        });

        const tbox_sun1_bg = new fabric.Rect({
            fill: '#CCCCCC', scaleY: 0.5,
            originX: 'center', originY: 'center',
            rx: 5, ry: 5,
            width: 90, height: 80
        });
        const tbox_sun1_text = new fabric.Text(
            'ORTA', {
            fontSize: FONT_SIZE_NAME, originX: 'center', originY: 'bottom', fill: '#333333'
        });
        const tbox_sun1_coord_text = new fabric.Text(
            sun1_coord_text, {
            fontSize: FONT_SIZE_COORD, originX: 'center', originY: 'top', fill: '#333333'
        });
        const tbox_sun1_group = new fabric.Group(
            [ tbox_sun1_bg, tbox_sun1_text, tbox_sun1_coord_text ], {
            left: 0,
            top: sun1_top_center - 40/2
        });

        const tbox_sun2_bg = new fabric.Rect({
            fill: '#CCCCCC', scaleY: 0.5,
            originX: 'center', originY: 'center',
            rx: 5, ry: 5,
            width: 90, height: 80
        });
        const tbox_sun2_text = new fabric.Text(
            'BALACA', {
            fontSize: FONT_SIZE_NAME, originX: 'center', originY: 'bottom', fill: '#333333'
        });
        const tbox_sun2_coord_text = new fabric.Text(
            sun2_coord_text, {
            fontSize: FONT_SIZE_COORD, originX: 'center', originY: 'top', fill: '#333333'
        });
        const tbox_sun2_group = new fabric.Group(
            [ tbox_sun2_bg, tbox_sun2_text, tbox_sun2_coord_text ], {
            left: window_dim.width-90,
            top: sun2_top_center - 40/2
        });

        canvi.add (tbox_plnt_group)
        canvi.add (tbox_sun0_group)
        canvi.add (tbox_sun1_group)
        canvi.add (tbox_sun2_group)


        //
        // Draw cocentric circles
        //
        const GRID_CIRCLE_RADIUS = 50
        for (let i = 0; i < 20; i++) {
            let radius = GRID_CIRCLE_RADIUS*i
            let circle = new fabric.Circle ({
                left: ORIGIN_X - radius,
                top:  ORIGIN_Y - radius,
                radius: radius,
                stroke: '#CCCCCC',
                strokeWidth: 0.2,
                strokeDashArray: [5, 5],
                fill: '',
                selectable: false,
                hoverCursor: "default"
            });
            canvi.add (circle)
        }

        //
        // Draw the trajectories using historical states
        //
        if (macro_states.macro_states.length > 1){
            const history_len = macro_states.macro_states.length
            console.log("history_len", history_len)
            for (var i = 1; i < history_len; i++){
                const historical_state = macro_states.macro_states[i]
                const historical_dynamics = historical_state.dynamics
                const plnt_x = historical_dynamics.planet.q.x
                const plnt_y = historical_dynamics.planet.q.y
                const sun0_x = historical_dynamics.sun0.q.x
                const sun0_y = historical_dynamics.sun0.q.y
                const sun1_x = historical_dynamics.sun1.q.x
                const sun1_y = historical_dynamics.sun1.q.y
                const sun2_x = historical_dynamics.sun2.q.x
                const sun2_y = historical_dynamics.sun2.q.y

                const sun0_left = ORIGIN_X + (sun0_x.toString(10)-SUN0_RADIUS) *DISPLAY_SCALE
                const sun0_top  = ORIGIN_Y + (sun0_y.toString(10)-SUN0_RADIUS) *DISPLAY_SCALE

                const sun1_left = ORIGIN_X + (sun1_x.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE
                const sun1_top  = ORIGIN_Y + (sun1_y.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE

                const sun2_left = ORIGIN_X + (sun2_x.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE
                const sun2_top  = ORIGIN_Y + (sun2_y.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE

                const plnt_left = ORIGIN_X + (plnt_x.toString(10)-PLNT_RADIUS) *DISPLAY_SCALE
                const plnt_top  = ORIGIN_Y + (plnt_y.toString(10)-PLNT_RADIUS) *DISPLAY_SCALE

                const historical_sun0_circle = new fabric.Circle ({
                    left: sun0_left,
                    top:  sun0_top,
                    radius: SUN0_RADIUS * DISPLAY_SCALE,
                    stroke: '',
                    strokeWidth: 0.1,
                    fill: '#6289AF10',
                    selectable: false,
                    hoverCursor: "pointer"
                });

                const historical_sun1_circle = new fabric.Circle ({
                    left: ORIGIN_X + (sun1_x.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE,
                    top:  ORIGIN_Y + (sun1_y.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE,
                    radius: SUN1_RADIUS * DISPLAY_SCALE,
                    stroke: '',
                    strokeWidth: 0.1,
                    fill: '#FF8B5810',
                    selectable: false,
                    hoverCursor: "pointer"
                });

                const historical_sun2_circle = new fabric.Circle ({
                    left: ORIGIN_X + (sun2_x.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE,
                    top:  ORIGIN_Y + (sun2_y.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE,
                    radius: SUN2_RADIUS * DISPLAY_SCALE,
                    stroke: '',
                    strokeWidth: 0.1,
                    fill: '#A0576010',
                    selectable: false,
                    hoverCursor: "pointer"
                });

                const historical_plnt_circle = new fabric.Circle ({
                    left: plnt_left,
                    top:  plnt_top,
                    radius: PLNT_RADIUS * DISPLAY_SCALE,
                    stroke: '',
                    strokeWidth: 0.1,
                    fill: '#8E8E8E10',
                    selectable: false,
                    hoverCursor: "pointer"
                });

                canvi.add (historical_sun0_circle)
                canvi.add (historical_sun1_circle)
                canvi.add (historical_sun2_circle)
                canvi.add (historical_plnt_circle)
            }
        }

        //
        // Draw the suns
        //
        const sun0_circle = new fabric.Circle ({
            left: sun0_left,
            top:  sun0_top,
            radius: SUN0_RADIUS * DISPLAY_SCALE,
            stroke: '#CCCCCC',
            strokeWidth: 1,
            fill: '#6289AF',
            selectable: false,
            hoverCursor: "pointer"
        });

        const sun1_circle = new fabric.Circle ({
            left: ORIGIN_X + (sun1_x.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE,
            top:  ORIGIN_Y + (sun1_y.toString(10)-SUN1_RADIUS) *DISPLAY_SCALE,
            radius: SUN1_RADIUS * DISPLAY_SCALE,
            stroke: '#CCCCCC',
            strokeWidth: 1,
            fill: '#FF8B58',
            selectable: false,
            hoverCursor: "pointer"
        });

        const sun2_circle = new fabric.Circle ({
            left: ORIGIN_X + (sun2_x.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE,
            top:  ORIGIN_Y + (sun2_y.toString(10)-SUN2_RADIUS) *DISPLAY_SCALE,
            radius: SUN2_RADIUS * DISPLAY_SCALE,
            stroke: '#CCCCCC',
            strokeWidth: 1,
            fill: '#A05760',
            selectable: false,
            hoverCursor: "pointer"
        });

        // const plnt_rect = new fabric.Rect({
        //     left: ORIGIN_X + plnt_x.toString(10) *DISPLAY_SCALE,
        //     top:  ORIGIN_Y + plnt_y.toString(10) *DISPLAY_SCALE,
        //     height: PLNT_RADIUS * 2 * DISPLAY_SCALE,
        //     width: PLNT_RADIUS * 2 * DISPLAY_SCALE,
        //     angel: 60,
        //     stroke: 'black',
        //     strokeWidth: 2,
        //     fill: '',
        //     selectable: false,
        //     hoverCursor: "pointer"
        // });

        const plnt_circle = new fabric.Circle ({
            left: ORIGIN_X + (plnt_x.toString(10)-PLNT_RADIUS) *DISPLAY_SCALE,
            top:  ORIGIN_Y + (plnt_y.toString(10)-PLNT_RADIUS) *DISPLAY_SCALE,
            radius: PLNT_RADIUS * DISPLAY_SCALE,
            stroke: '#CCCCCC',
            strokeWidth: 0.5,
            fill: '#8E8E8E',
            selectable: false,
            hoverCursor: "pointer"
        });

        canvi.add (sun0_circle)
        canvi.add (sun1_circle)
        canvi.add (sun2_circle)
        canvi.add (plnt_circle)
        // console.log ("planet rect angle:", plnt_rect.angle)


        //
        // Draw axis directionalities
        //
        const AXIS_LEN = 50
        const AXIS_TRI_W = 6
        const AXIS_TRI_H = 8
        const AXIS_ORI_X = 50
        const AXIS_ORI_Y = 50
        const axis_line_x = new fabric.Line(
            [AXIS_ORI_X, AXIS_ORI_Y, AXIS_ORI_X+AXIS_LEN, AXIS_ORI_Y], GRID_STYLE);
        const axis_line_y = new fabric.Line(
            [AXIS_ORI_X, AXIS_ORI_Y, AXIS_ORI_X, AXIS_ORI_Y+AXIS_LEN], GRID_STYLE);
        const axis_tri_x = createTriangle (
            AXIS_ORI_X+AXIS_LEN, AXIS_ORI_Y-AXIS_TRI_W,
            AXIS_TRI_W, AXIS_TRI_H,
            90
        )
        const axis_tri_y = createTriangle (
            AXIS_ORI_X-AXIS_TRI_W/2+1, AXIS_ORI_Y+AXIS_LEN-2,
            AXIS_TRI_W, AXIS_TRI_H,
            180
        )
        const tbox_axis_x = new fabric.Text(
            'x', {
            left: AXIS_ORI_X + AXIS_LEN + AXIS_TRI_H + 5,
            top: AXIS_ORI_Y - 10,
            fontSize: 16,
            fill: '#CCCCCC'
        });
        const tbox_axis_y = new fabric.Text(
            'y', {
            left: AXIS_ORI_X - 5,
            top: AXIS_ORI_Y + AXIS_LEN + AXIS_TRI_H,
            fontSize: 16,
            fill: '#CCCCCC'
        });

        canvi.add (axis_line_x)
        canvi.add (axis_line_y)
        canvi.add (axis_tri_x)
        canvi.add (axis_tri_y)
        canvi.add (tbox_axis_x)
        canvi.add (tbox_axis_y)
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