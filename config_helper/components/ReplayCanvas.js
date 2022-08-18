import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { toBN } from 'starknet/dist/utils/number'
import { BigNumber } from 'bignumber.js'
import { fabric } from 'fabric';

import {
    useCivStates
} from '../lib/api'

export default function ReplayCanvas (props) {

    // Constant
    const CANVAS_H = 450
    const CANVAS_W = 700
    const CANVAS_BG_LIGHT = '#f9ffff'
    const ORIGIN_X = CANVAS_W / 2
    const ORIGIN_Y = CANVAS_H / 2
    const DISPLAY_SCALE = 25
    const SUN0_RADIUS = 0.89 // from contract
    const SUN1_RADIUS = 1.36 // from contract
    const SUN2_RADIUS = 0.61 // from contract
    const PLNT_RADIUS = 0.03 // arbitrary
    const SUN0_STROKE_WIDTH = 0.5
    const SUN1_STROKE_WIDTH = 0.7
    const SUN2_STROKE_WIDTH = 0.7
    const SUN0_FILL_LIGHT = '#f0e3d0'
    const SUN1_FILL_LIGHT = '#e3bab4'
    const SUN2_FILL_LIGHT = '#b9e3f3'
    const EV_FILL_LIGHT   = '#7777AA'

    // React states and references
    const [macroStatesLen, setMacroStatesLen] = useState(0)
    const [slideBlockHeightRel, setSlideBlockHeightRel] = useState(0)
    const _canvasRef = useRef()
    const _sunsRef = useRef({})
    const _plntRef = useRef()

    useEffect(() => {
        if (!props.open) {
            setSlideBlockHeightRel (0) // reset slide at window close
        }
    }, [props.open])

    useEffect(() => {
        if (!props.macro_states) return;

        setMacroStatesLen (props.macro_states.length)

        // draw canvas
        _canvasRef.current = new fabric.Canvas('c', {
            height: CANVAS_H,
            width: CANVAS_W,
            backgroundColor: CANVAS_BG_LIGHT,
            selection: false,
            stopContextMenu: true
        })

        // get initial positions of suns + planet
        const sun0_x_raw = props.macro_states[0].dynamics.sun0.q.x
        const sun0_y_raw = props.macro_states[0].dynamics.sun0.q.y
        const sun1_x_raw = props.macro_states[0].dynamics.sun1.q.x
        const sun1_y_raw = props.macro_states[0].dynamics.sun1.q.y
        const sun2_x_raw = props.macro_states[0].dynamics.sun2.q.x
        const sun2_y_raw = props.macro_states[0].dynamics.sun2.q.y
        const plnt_x_raw = props.macro_states[0].dynamics.planet.q.x
        const plnt_y_raw = props.macro_states[0].dynamics.planet.q.y

        // normalize positions
        const sun0_left = ORIGIN_X + (sun0_x_raw - SUN0_RADIUS) *DISPLAY_SCALE
        const sun0_top  = ORIGIN_Y + (sun0_y_raw - SUN0_RADIUS) *DISPLAY_SCALE
        const sun1_left = ORIGIN_X + (sun1_x_raw - SUN1_RADIUS) *DISPLAY_SCALE
        const sun1_top  = ORIGIN_Y + (sun1_y_raw - SUN1_RADIUS) *DISPLAY_SCALE
        const sun2_left = ORIGIN_X + (sun2_x_raw - SUN2_RADIUS) *DISPLAY_SCALE
        const sun2_top  = ORIGIN_Y + (sun2_y_raw - SUN2_RADIUS) *DISPLAY_SCALE
        const plnt_left = ORIGIN_X + (plnt_x_raw - PLNT_RADIUS) *DISPLAY_SCALE
        const plnt_top  = ORIGIN_Y + (plnt_y_raw - PLNT_RADIUS) *DISPLAY_SCALE

        // draw the suns
        var sun0_circle = new fabric.Circle ({
            left: sun0_left, top:  sun0_top,
            radius: SUN0_RADIUS * DISPLAY_SCALE,
            stroke: '#000000', strokeWidth: SUN0_STROKE_WIDTH,
            fill: SUN0_FILL_LIGHT,
            selectable: false, hoverCursor: "default"
        });

        var sun1_circle = new fabric.Circle ({
            left: sun1_left, top:  sun1_top,
            radius: SUN1_RADIUS * DISPLAY_SCALE,
            stroke: '#000000', strokeWidth: SUN1_STROKE_WIDTH,
            fill: SUN1_FILL_LIGHT,
            selectable: false, hoverCursor: "default"
        });

        var sun2_circle = new fabric.Circle ({
            left: sun2_left, top:  sun2_top,
            radius: SUN2_RADIUS * DISPLAY_SCALE,
            stroke: '#000000', strokeWidth: SUN2_STROKE_WIDTH,
            fill: SUN2_FILL_LIGHT,
            selectable: false, hoverCursor: "default"
        });

        const phi_degree = parse_phi_to_degree (props.macro_states[0].phi)
        var plnt_square = createPlnt (
            plnt_left,
            plnt_top,
            PLNT_RADIUS * 2 * DISPLAY_SCALE,
            phi_degree,
            EV_FILL_LIGHT,
            '#000000',
            1.5,
            "pointer",
            1.0
        )

        // add objects to canvas and save to reference
        _canvasRef.current.add (sun0_circle)
        _canvasRef.current.add (sun1_circle)
        _canvasRef.current.add (sun2_circle)
        _canvasRef.current.add (plnt_square)
        _sunsRef.current = {
            0 : sun0_circle,
            1 : sun1_circle,
            2 : sun2_circle
        }
        _plntRef.current = plnt_square

    }, [props.macro_states])

    function drawUniverse (block_height_rel) {

        const idx = block_height_rel
        const sun0_x_raw = props.macro_states[idx].dynamics.sun0.q.x
        const sun0_y_raw = props.macro_states[idx].dynamics.sun0.q.y
        const sun1_x_raw = props.macro_states[idx].dynamics.sun1.q.x
        const sun1_y_raw = props.macro_states[idx].dynamics.sun1.q.y
        const sun2_x_raw = props.macro_states[idx].dynamics.sun2.q.x
        const sun2_y_raw = props.macro_states[idx].dynamics.sun2.q.y
        const plnt_x_raw = props.macro_states[idx].dynamics.planet.q.x
        const plnt_y_raw = props.macro_states[idx].dynamics.planet.q.y

        const sun0_left = ORIGIN_X + (sun0_x_raw - SUN0_RADIUS) *DISPLAY_SCALE
        const sun0_top  = ORIGIN_Y + (sun0_y_raw - SUN0_RADIUS) *DISPLAY_SCALE
        const sun1_left = ORIGIN_X + (sun1_x_raw - SUN1_RADIUS) *DISPLAY_SCALE
        const sun1_top  = ORIGIN_Y + (sun1_y_raw - SUN1_RADIUS) *DISPLAY_SCALE
        const sun2_left = ORIGIN_X + (sun2_x_raw - SUN2_RADIUS) *DISPLAY_SCALE
        const sun2_top  = ORIGIN_Y + (sun2_y_raw - SUN2_RADIUS) *DISPLAY_SCALE
        const plnt_left = ORIGIN_X + (plnt_x_raw - PLNT_RADIUS) *DISPLAY_SCALE
        const plnt_top  = ORIGIN_Y + (plnt_y_raw - PLNT_RADIUS) *DISPLAY_SCALE
        const phi_degree = parse_phi_to_degree (props.macro_states[idx].phi)
        console.log ('phi_degree', phi_degree)

        _sunsRef.current[0].left = sun0_left
        _sunsRef.current[0].top  = sun0_top
        _sunsRef.current[1].left = sun1_left
        _sunsRef.current[1].top  = sun1_top
        _sunsRef.current[2].left = sun2_left
        _sunsRef.current[2].top  = sun2_top

        _plntRef.current.left     = plnt_left
        _plntRef.current.top      = plnt_top
        _plntRef.current.rotate (phi_degree)

        _canvasRef.current.renderAll()
    }

    // Handle slider changes
    function handleSlideChange (evt) {
        const slide_val = evt.target.value
        setSlideBlockHeightRel (slide_val)
        drawUniverse (slide_val)
    }

    return (
        <div style={{
            display:'flex',flexDirection:'column',textAlign:'center',
            justifyContent:"center",alignItems:"center",
            marginTop: '20px'
        }}>

            <input
                id="typeinp"
                type="range"
                min="0" max={ (macroStatesLen-1).toString(10)}
                value={slideBlockHeightRel}
                onChange={handleSlideChange}
                step="1"
            />
            <h4>block height since civ birth: {slideBlockHeightRel}</h4>

            <div>
                <canvas id="c" />
            </div>

        </div>
    );
}

function parse_phi_to_degree (phi)
{
    const phi_bn = new BigNumber(Buffer.from(phi, 'base64').toString('hex'), 16)
    const phi_degree = (phi_bn / 10**20) / (Math.PI * 2) * 360

    return phi_degree
}

function createPlnt (x, y, d, rotation, fill, stroke, stroke_w, cursor, opacity)
{
    var pos = fabric.util.rotatePoint(
        new fabric.Point(x, y),
        new fabric.Point(x + d/2, y + d/2),
        fabric.util.degreesToRadians(rotation)
    );

    return new fabric.Rect(
    {
        width: d,
        height: d,
        selectable: false,
        fill: fill,
        stroke: stroke,
        strokeWidth: stroke_w,
        left: pos.x,
        top: pos.y,
        originX: "center",
        originY: "center",
        angle: rotation,
        hoverCursor: cursor,
        opacity: opacity
    });
}