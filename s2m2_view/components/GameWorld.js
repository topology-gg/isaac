import React, { Component, useState, useEffect, useRef, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import Modal from "./Modal";
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
const GRID = 8 // grid size
const PAD = 100 // pad size
const SIDE = 25 // number of grids per size (planet dimension)
const STROKE = '#BBBBBB' // grid stroke color
const STROKE_EDGE = '#333333' // grid stroke color
const CANVAS_W = 1050
const CANVAS_H = 900
const TRIANGLE_W = 10
const TRIANGLE_H = 15

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
DEVICE_COLOR_MAP.set(0,  "#8DAAF7"); // SPG
DEVICE_COLOR_MAP.set(1,  "#A87AF7"); // NPG
DEVICE_COLOR_MAP.set(2,  "#211E3A"); // FE HARV
DEVICE_COLOR_MAP.set(3,  "#445868"); // FE REFN
DEVICE_COLOR_MAP.set(4,  "#893439"); // AL HARV
DEVICE_COLOR_MAP.set(5,  "#D96767"); // AL REFN
DEVICE_COLOR_MAP.set(6,  "#F18C62"); // CU HARV
DEVICE_COLOR_MAP.set(7,  "#FFB57E"); // CU REFN
DEVICE_COLOR_MAP.set(8,  "#75ABCF"); // SI HARV
DEVICE_COLOR_MAP.set(9,  "#ADC2D3"); // SI REFN
DEVICE_COLOR_MAP.set(10, "#E4A2AB"); // PU HARV
DEVICE_COLOR_MAP.set(11, "#EDCEDB"); // PEF
DEVICE_COLOR_MAP.set(12, "#9FACA3"); // UTB
DEVICE_COLOR_MAP.set(13, "#88D4CA"); // UTL
DEVICE_COLOR_MAP.set(14, "#FFDD8D"); // UPSF
DEVICE_COLOR_MAP.set(15, "#51499E"); // NDPE

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

function createTriangle(x, y, rotation)
{
    var width  = TRIANGLE_W;
    var height = TRIANGLE_H;
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

    // Credits:
    // https://aprilescobar.medium.com/part-1-fabric-js-on-react-fabric-canvas-e4094e4d0304
    // https://stackoverflow.com/questions/60723440/problem-in-attaching-event-to-canvas-in-useeffect
    // https://eliaslog.pw/how-to-add-multiple-refs-to-one-useref-hook/

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
    const { data: civ_player_address_0 } = useStarknetCall({
        contract,
        method: 'civilization_player_idx_to_address_read',
        args: [0]
    })

    //
    // Logic to initialize a Fabric canvas
    //
    const [canvas, setCanvas] = useState([]);
    const [coordTextBox, setCoordTextBox] = useState();
    const [hasDrawn, _] = useState([]);
    const _refs = useRef([]);
    // const _canvasRef = useRef(0);
    // const _hasDrawnRef =

    var textOptions = {
        fontSize:16,
        left: PAD + 3*GRID*SIDE,
        top: PAD,
        radius:10,
        borderRadius: '25px',
        hasRotatingPoint: true
    };

    var textObject = new fabric.IText('(-,-)', textOptions);

    var cursorGridRect = new fabric.Rect({
        height: GRID,
        width: GRID,
        left: PAD,
        top: PAD,
        fill: "#AAAAAA",
        selectable: false,
        hoverCursor: 'default',
        visible: false
    });

    useEffect (() => {

        // console.log("useEffect(callback, []) called.")
        _refs.current[0] = new fabric.Canvas('c', {
            height: CANVAS_H,
            width: CANVAS_W,
            backgroundColor: '#E3EDFF',
            selection: false
        })
        setCanvas (_refs.current[0]);

        _refs.current[1] = false
    }, []);

    useEffect (() => {
        // console.log("useEffect(callback, [device_emap, utb_grids]) called.")
        if (!_refs.current[1]) {
            drawWorld (_refs.current[0])
        }
    }, [device_emap, utb_grids]);

    const drawWorld = canvi => {

        if (civ_player_address_0) {
            if (civ_player_address_0.address) {
                const player_0_addr = toBN (civ_player_address_0.address).toString()
                console.log ("civ_player_address_0.address", player_0_addr)
                if (player_0_addr === "0") {
                    console.log ("The address of player 0 is 0x0 => this universe is not active!")
                    drawIdleMessage (canvi)
                    return
                }

                if (device_emap && utb_grids) {
                    if (device_emap.emap && utb_grids.grids) {
                        drawGrid (canvi)
                        drawDevices (canvi)
                        _refs.current[1] = true
                    }
                }
            }
        }
    }

    const drawIdleMessage = canvi => {
        const tbox_idle_message = new fabric.Textbox(
            'This universe is not active.', {
                width: 200,
                top:  CANVAS_H/2 - 100,
                left: CANVAS_W/2 - 100,
                fontSize: 20,
                textAlign: 'left',
                fill: "#333333",
                hoverCursor: 'default'
            });
        canvi.add (tbox_idle_message)
    }

    const drawGrid = canvi => {

        //
        // Draw textObject for showing user mouse coordinate
        //
        canvi.add(textObject)
        // setCoordTextBox (textObject);
        _refs.current[2] = textObject

        canvi.add (cursorGridRect)
        _refs.current[3] = cursorGridRect

        //
        // Axes for coordinate system
        //
        const AXIS_EXTEND_GRID_MULTIPLE = 7
        canvi.add(new fabric.Line([
            PAD + 0,
            PAD + 0 - GRID*AXIS_EXTEND_GRID_MULTIPLE,
            PAD + 0,
            PAD + SIDE*GRID*3
        ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
        canvi.add(new fabric.Line([
            PAD + 0,
            PAD + SIDE*GRID*3,
            PAD + SIDE*GRID*4 + GRID*AXIS_EXTEND_GRID_MULTIPLE,
            PAD + SIDE*GRID*3
        ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));

        const triangle_y_axis = createTriangle (
            PAD-(TRIANGLE_W/2),
            PAD - GRID*AXIS_EXTEND_GRID_MULTIPLE - TRIANGLE_H,
            0
        )
        const triangle_x_axis = createTriangle (
            PAD + SIDE*GRID*4 + GRID*AXIS_EXTEND_GRID_MULTIPLE,
            PAD + SIDE*GRID*3 - TRIANGLE_W,
            90
        )
        canvi.add (triangle_y_axis);
        canvi.add (triangle_x_axis);

        //
        // Axis ticks
        //
        const tbox_origin = new fabric.Textbox(
            '(0,0)', {
                width: 100,
                top:  PAD + SIDE*GRID*3 + GRID,
                left: PAD + 0 - GRID*2,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_y_d = '(0,' + SIDE.toString() + ')'
        const tbox_y_d = new fabric.Textbox(
            text_y_d, {
                width: 100,
                top:  PAD + SIDE*GRID*2 - GRID*2,
                left: PAD + 0 - GRID*6,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_y_2d = '(0,' + (2*SIDE).toString() + ')'
        const tbox_y_2d = new fabric.Textbox(
            text_y_2d, {
                width: 100,
                top:  PAD + SIDE*GRID*1 - GRID*2,
                left: PAD + 0 - GRID*6,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_y_3d = '(0,' + (3*SIDE).toString() + ')'
        const tbox_y_3d = new fabric.Textbox(
            text_y_3d, {
                width: 100,
                top:  PAD + SIDE*GRID*0 - GRID*2,
                left: PAD + 0 - GRID*6,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_x_d = '(' + SIDE.toString() + ',0)'
        const tbox_x_d = new fabric.Textbox(
            text_x_d, {
                width: 100,
                top:  PAD + SIDE*GRID*3 + GRID,
                left: PAD + SIDE*GRID*1 - GRID*2,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_x_2d = '(' + (2*SIDE).toString() + ',0)'
        const tbox_x_2d = new fabric.Textbox(
            text_x_2d, {
                width: 100,
                top:  PAD + SIDE*GRID*3 + GRID,
                left: PAD + SIDE*GRID*2 - GRID*2,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_x_3d = '(' + (3*SIDE).toString() + ',0)'
        const tbox_x_3d = new fabric.Textbox(
            text_x_3d, {
                width: 100,
                top:  PAD + SIDE*GRID*3 + GRID,
                left: PAD + SIDE*GRID*3 - GRID*2,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        const text_x_4d = '(' + (4*SIDE).toString() + ',0)'
        const tbox_x_4d = new fabric.Textbox(
            text_x_4d, {
                width: 100,
                top:  PAD + SIDE*GRID*3 + GRID,
                left: PAD + SIDE*GRID*4 - GRID*2,
                fontSize: 16,
                textAlign: 'left',
                fill: STROKE_EDGE,
                hoverCursor: 'default'
            });

        canvi.add (tbox_origin)
        canvi.add (tbox_y_d)
        canvi.add (tbox_y_2d)
        canvi.add (tbox_y_3d)
        canvi.add (tbox_x_d)
        canvi.add (tbox_x_2d)
        canvi.add (tbox_x_3d)
        canvi.add (tbox_x_4d)

        //
        // Grid lines parallel to Y-axis
        //
        for (var xi = 0; xi < SIDE; xi++){
            canvi.add(new fabric.Line([
                PAD + xi*GRID,
                PAD + SIDE*GRID,
                PAD + xi*GRID,
                PAD + SIDE*GRID*2
            ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
        }
        for (var xi = SIDE; xi < SIDE*2+1; xi++){
            canvi.add(new fabric.Line([
                PAD + xi*GRID,
                PAD + 0,
                PAD + xi*GRID,
                PAD + SIDE*GRID*3
            ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
        }
        for (var xi = 2*SIDE+1; xi < SIDE*4+1; xi++){
            canvi.add(new fabric.Line([
                PAD + xi*GRID,
                PAD + SIDE*GRID,
                PAD + xi*GRID,
                PAD + SIDE*GRID*2
            ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
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
            ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
        }
        for (var yi = SIDE; yi < 2*SIDE+1; yi++){
            canvi.add(new fabric.Line([
                PAD + 0,
                PAD + yi*GRID,
                PAD + SIDE*GRID*4,
                PAD + yi*GRID
            ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
        }
        for (var yi = 2*SIDE+1; yi < 3*SIDE+1; yi++){
            canvi.add(new fabric.Line([
                PAD + SIDE*GRID,
                PAD + yi*GRID,
                PAD + SIDE*GRID*2,
                PAD + yi*GRID
            ], { stroke: STROKE, selectable: false, hoverCursor: 'default' }));
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
                fill: device_color,
                selectable: false,
                hoverCursor: 'pointer'
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
                    fill: device_color,
                    selectable: false,
                    hoverCursor: 'pointer'
                });
                canvi.add(rect);
        }

            // }
        // }

        canvi.renderAll();
    }

    //
    // Grid assists and popup window
    //

    const [ClickPositionNorm, setClickPositionNorm] = useState({
        left: 0,
        top: 0
    })
    const [MousePositionNorm, setMousePositionNorm] = useState({
        x: 0,
        y: 0
    })
    const [modalVisibility, setModalVisibility] = useState(false)
    const [modalInfo, setModalInfo] = useState({})

    function is_valid_coord (x, y) {
        const x0 = x >= 0 && x <= 24
        const x1 = x >= 25 && x <= 49
        const x2 = x >= 50 && x <= 74
        const x3 = x >= 75 && x <= 99

        const y0 = y >= 0 && y <= 24
        const y1 = y >= 25 && y <= 49
        const y2 = y >= 50 && y <= 74

        // face 0
        if (x0 && y1) {
            return true
        }

        // face 1
        if (x1 && y0) {
            return true
        }

        // face 2
        if (x1 && y1) {
            return true
        }

        // face 3
        if (x1 && y2) {
            return true
        }

        // face 4
        if (x2 && y1) {
            return true
        }

        // face 5
        if (x3 && y1) {
            return true
        }

        return false
    }

    function handleMouseMove(ev) {
        const x_norm = Math.floor( (ev.pageX - PAD) / GRID )
        const y_norm = SIDE*3 - 1 - Math.floor( (ev.pageY - PAD) / GRID )
        const bool = is_valid_coord (x_norm, y_norm)

        if (bool && !modalVisibility) {
            setMousePositionNorm ({
                x: x_norm,
                y: y_norm
            })
            console.log ("Yep")
        }
        else {
            setMousePositionNorm ({
                x: '-',
                y: '-'
            })
            console.log ("Nope")
        }
    }

    function drawMouseCoordTextObject (canvi, mPosNorm) {
        if (_refs.current[2]) {
            _refs.current[2].text = '(' + mPosNorm.x.toString() + ',' + mPosNorm.y.toString() + ')'
            _refs.current[2].dirty  = true
            // console.log ("drawMouseCoordTextObject:", _refs.current[2].text, mPosNorm)

            if (mPosNorm.x.toString() === '-') {
                _refs.current[3].visible = false
            }
            else {
                _refs.current[3].left = PAD + mPosNorm.x*GRID
                _refs.current[3].top  = PAD + (SIDE*3 - mPosNorm.y - 1)*GRID
                _refs.current[3].visible = true
            }
            _refs.current[3].dirty  = true

            canvi.renderAll();
        }
    }

    useEffect (() => {
        // console.log("useEffect(callback, [MousePositionNorm]) called.")
        drawMouseCoordTextObject (_refs.current[0], MousePositionNorm)
    }, [MousePositionNorm]);


    function handleClick(ev) {
        const x_norm = Math.floor( (ev.pageX - PAD) / GRID )
        const y_norm = SIDE*3 - 1 - Math.floor( (ev.pageY - PAD) / GRID )
        const bool = is_valid_coord (x_norm, y_norm)

        if (bool && !modalVisibility) {
            setClickPositionNorm ({
                x: x_norm,
                y: y_norm
            })
            setModalInfo ({
                grid_x: x_norm,
                grid_y: y_norm
            })
            setModalVisibility (true);
            console.log ("Good click.")
        }
        else {
            // setMousePositionNorm ({
            //     x: '-',
            //     y: '-'
            // })
            console.log ("Bad click.")
        }
    }

    //
    // Return component
    //
    return(
        <div
            onMouseMove={(ev)=> handleMouseMove(ev)}
            onClick={(ev)=> handleClick(ev)}
        >
            <Modal
                show   = {modalVisibility}
                onHide = {() => setModalVisibility (false)}
                // name   = {"Grid (x,y)"}
                info = {modalInfo}
            />

            <canvas id="c" />
        </div>
    );
}
