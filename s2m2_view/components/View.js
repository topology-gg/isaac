import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';

import {
    usePuzzles,
    useS2mState
} from '../lib/api'

import Modal from "./Modal";
import Record from './Record'

import {
    useStarknet
} from '@starknet-react/core'


export default function View () {
    return (
      <Parent>
        <Record />
      </Parent>
    );
  }

function Parent (props) {

    const { account } = useStarknet()

    //
    // Data fetched from backend on Apibara
    //
    const { data: db_state } = useS2mState ()
    const { data: db_puzzles } = usePuzzles ()


    //
    // Constants
    //
    const DIM = 8 // board is DIM * DIM
    const GRID = 40 // grid size
    const CANVAS_H = DIM * GRID
    const CANVAS_W = DIM * GRID
    const RADIUS = GRID/2 * 0.7

    // const PAD_X = 160 // pad size
    // const PAD_Y = 0 // pad size

    const CR = 1
    const ST = 2
    const CR_COLOR = "#0066b2"
    const ST_COLOR = "#F06105"

    //
    // References & States
    //
    const _canvasRef = useRef ()
    const _hasDrawnRef = useRef (false)
    const _crCirclesRef = useRef ([])
    const _stCirclesRef = useRef ([])
    const _cursorGridRectRef = useRef()
    const _selectStateRef = useRef('idle')
    const _selectedGridsRef = useRef([])
    const _gridAssistRectsRef = useRef({});
    const _mouseInCanvasRef = useRef(false);
    const _modalVisibilityRef = useRef (false)
    const [hasLoadedDB, setHasLoadedDB] = useState (false)
    const [shownPuzzleId, setShownPuzzleId] = useState (0)
    const [children, setChildren] = useState([])
    const [mousePositionNorm, setMousePositionNorm] = useState({x: 0, y: 0})
    const [selectedGrids, setSelectedGrids] = useState([])
    const [modalVisibility, setModalVisibility] = useState (false)
    const [mouseInCanvas, setMouseInCanvas] = useState (false)
    const [modalInfo, setModalInfo] = useState({'grids':[]})

    //
    // Initialize canvas, and register mouse/key event handlers
    //
    useEffect (() => {

        _canvasRef.current = new fabric.Canvas('c', {
            height: CANVAS_H,
            width: CANVAS_W,
            backgroundColor: '#282828',
            selection: false
        })

        _canvasRef.current.on("mouse:over" ,function(opt){
            setMouseInCanvas (true)
            _mouseInCanvasRef.current = true
            document.getElementById('canvas_wrap').focus();
        })

        _canvasRef.current.on("mouse:out" ,function(opt){
            setMouseInCanvas (false)
            _mouseInCanvasRef.current = false
        })

        _canvasRef.current.on("mouse:down" ,function(opt){

            const pointer = _canvasRef.current.getPointer(opt.e);
            const x = Math.floor (pointer.x / GRID);
            const y = Math.floor (pointer.y / GRID);

            if (opt.e.button == 0){ // LMB
                handleLeftMouseDown (x, y)
            }
        })

        _canvasRef.current.on("mouse:up" ,function(opt){
            const pointer = _canvasRef.current.getPointer(opt.e);
            const x = Math.floor (pointer.x / GRID);
            const y = Math.floor (pointer.y / GRID);

            if (opt.e.button == 0){ // LMB
                handleLeftMouseUp (x, y)
            }
        })

        _canvasRef.current.on("mouse:move" ,function(opt){
            //
            // mouse x & y adjustment
            // ref: https://stackoverflow.com/a/30869635
            //
            const pointer = _canvasRef.current.getPointer(opt.e);
            const x = Math.floor (pointer.x / GRID);
            const y = Math.floor (pointer.y / GRID);

            if (_selectStateRef.current === 'select'){
                handleMouseDrag (x, y)
            }

        })

        document.addEventListener("keydown", handleKeyDown, false);
        return () => {
            document.removeEventListener("keydown", handleKeyDown, false);
        };

    }, []);

    //
    // Key event handler
    //
    const handleKeyDown = useCallback((ev) => {

        if (!_hasDrawnRef.current) {
            return
        }

        if (ev.key === "Escape") {
            if (_modalVisibilityRef.current) {
                hidePopup ()
            }
        }

      }, [modalVisibility]);

    //
    // Mouse event handlers
    //
    function handleLeftMouseDown (x, y) {

        const bool_state_in_idle = (_selectStateRef.current === 'idle')

        if (_mouseInCanvasRef.current && bool_state_in_idle) {
            _selectStateRef.current = 'select'

            _selectedGridsRef.current.push ({x:x, y:y})
            setSelectedGrids (selectedGrids.concat({x:x, y:y}) )

            _gridAssistRectsRef.current [`(${x},${y})`].visible = true
        }
    }

    function handleLeftMouseUp (x, y) {

        const bool_not_empty = (_selectedGridsRef.current.length !== 0)

        if (_mouseInCanvasRef.current && bool_not_empty) {
            _selectStateRef.current = 'popup'
            setModalVisibility (true)
            _modalVisibilityRef.current = true

            const info = {
                'grids' : _selectedGridsRef.current
            }
            setModalInfo (info)
        }
    }

    function handleMouseDrag (x, y) {

        const bool_state_in_select = (_selectStateRef.current === 'select')
        var bool_exist = _selectedGridsRef.current.some (ele =>{
            return JSON.stringify({x:x, y:y}) === JSON.stringify(ele);
        });

        const bool_mouse_in_canvas = (x >= 0) && (x <= 7) && (y >= 0) && (y <= 7)

        if ( (!bool_exist) && bool_state_in_select && bool_mouse_in_canvas) {
            console.log (`(${x},${y})`)

            _selectedGridsRef.current.push ({x:x, y:y})
            setSelectedGrids (selectedGrids.concat({x:x, y:y}) )

            _gridAssistRectsRef.current [`(${x},${y})`].visible = true
        }
    }

    useEffect (() => {
        _canvasRef.current.renderAll ()
    }, [selectedGrids])


    //
    // Check if all db collections are loaded
    //
    useEffect (() => {
        if (hasLoadedDB) {
            return
        }
        if (!db_state || !db_puzzles) {
            console.log ('db loading ...')
            return
        }
        else {
            console.log ('db loaded!')
            setHasLoadedDB (true)
        }
    }, [db_state, db_puzzles]);


    //
    // If db collections all loaded => draw canvas
    //
    useEffect (() => {

        if (!_hasDrawnRef.current & hasLoadedDB) {
            populateCanvas (_canvasRef.current)
            _hasDrawnRef.current = true
        }

    }, [hasLoadedDB]);


    //
    // Populate canvas
    //
    function populateCanvas (canvi) {

        // Draw variable CR & ST circles
        drawCircles (canvi)

        // Draw variable assist rects
        drawCursorGridRect  (canvi)
        drawAssistGridRects (canvi)

        // Draw variable grid texts
        drawGridTexts (canvi)

        // Pull in the starting puzzle and update visibilities of circles
        updatePuzzle (canvi)

        canvi.renderAll();
    }

    function drawGridTexts (canvi) {
        for (var cell_idx=0; cell_idx<8*8; cell_idx++) {
            const coord = convertCellIdxToCoord (cell_idx)
            const virtual_rect = new fabric.Rect({
                height: GRID, width: GRID,
                originX: 'center', originY: 'center',
                fill: '#FFFFFF00',
                stroke: '#CCCCCC',
                selectable: false,
                hoverCursor: 'default',
                visible: false
            });
            const grid_text = new fabric.Text( `${cell_idx}`,
                {
                fontSize: 13, fill: '#CCCCCC',
                originX: 'center', originY: 'center',
                selectable: false,
                fontFamily: "Poppins-Light",
                hoverCursor: 'default',
            });
            const grid_text_group = new fabric.Group(
                [virtual_rect, grid_text], {
                    left: coord.left,
                    top: coord.top,
                    selectable: false,
                    hoverCursor: 'default'
                }
            )
            canvi.add (grid_text_group)
        }
    }

    function drawCircles (canvi) {

        //
        // draw all the circles and turn off their visibilities
        //

        var cr_circles = []
        var st_circles = []
        for (var cell_idx=0; cell_idx<8*8; cell_idx++) {
            const coord = convertCellIdxToCoord (cell_idx)

            var cr_circle = new fabric.Circle ({
                left: coord.left + GRID/2 - RADIUS,
                top:  coord.top + GRID/2 - RADIUS,
                radius: RADIUS,
                stroke: '',
                strokeWidth: 0,
                fill: CR_COLOR,
                selectable: false,
                hoverCursor: "default",
                visible: false
            });
            canvi.add (cr_circle)
            cr_circles.push (cr_circle)

            var st_circle = new fabric.Circle ({
                left: coord.left + GRID/2 - RADIUS,
                top:  coord.top + GRID/2 - RADIUS,
                radius: RADIUS,
                stroke: '',
                strokeWidth: 0,
                fill: ST_COLOR,
                selectable: false,
                hoverCursor: "default",
                visible: false
            });
            canvi.add (st_circle)
            st_circles.push (st_circle)
        }

        _crCirclesRef.current = cr_circles
        _stCirclesRef.current = st_circles
    }

    function drawCursorGridRect (canvi) {
        var cursorGridRect = new fabric.Rect({
            height: GRID,
            width: GRID,
            left: 0,
            top: 0,
            fill: '#CCCCCC33',
            selectable: false,
            hoverCursor: 'default',
            visible: false,
            strokeWidth: 0
        });
        canvi.add (cursorGridRect)
        _cursorGridRectRef.current = cursorGridRect
    }

    function drawAssistGridRects (canvi) {

        for (var x=0; x<8; x++) {
            for (var y=0; y<8; y++) {
                var rect = new fabric.Rect({
                    height: GRID, width: GRID,
                    left: x * GRID,
                    top:  y * GRID,
                    fill: '#DDDDDD77',
                    selectable: false,
                    hoverCursor: 'default',
                    visible: false,
                    strokeWidth: 0
                });
                canvi.add (rect)
                _gridAssistRectsRef.current [`(${x},${y})`] = rect
            }
        }

    }

    function convertCellIdxToCoord (cell_idx) {
        const col = cell_idx % 8
        const row = Math.floor (cell_idx / 8);
        return {
            left: CANVAS_W/2 -4*GRID + col*GRID,
            top:  row*GRID
        }
    }

    //
    // update puzzle shown by selectively turning on visibility of CR and ST circles
    //
    useEffect (() => {

        if (db_puzzles) {
            updatePuzzle ()
        }

    }, [shownPuzzleId]);

    function updatePuzzle () {
        //
        // first turn off all circles
        //
        for (var cell_idx=0; cell_idx<64; cell_idx++) {
            _crCirclesRef.current [cell_idx].visible = false
            _stCirclesRef.current [cell_idx].visible = false
        }

        //
        // then turn on circles for the shown puzzle
        //
        const circles = db_puzzles.puzzles [shownPuzzleId].circles
        for (const c of circles) {
            const cell_idx = c.cell_idx
            const typ = c.typ

            if (typ == CR) {
                _crCirclesRef.current [cell_idx].visible = true
            }
            else if (typ == ST) {
                _stCirclesRef.current [cell_idx].visible = true
            }
        }
        _canvasRef.current.renderAll();
    }


    //
    // Child callback registry and handling
    // ref: https://stackoverflow.com/questions/71641063/react-communicate-between-parent-and-child-component
    //
    useEffect(() => {
      let _children = React.Children.map(props.children, (child) => {
        return {
          ...child,
          props: {
            ...child.props,
            callBack: childCallBack
          }
        };
      });
      setChildren(_children);
    }, []);

    function childCallBack(val) {
        setShownPuzzleId (val)
    }


    //
    // Handle mouse move
    //
    function handleMouseMove(ev) {

        if (!_canvasRef.current) {
            return
        }

        var pointer = _canvasRef.current.getPointer(ev);
        var x = pointer.x;
        var y = pointer.y;

        const x_norm = Math.floor( x / GRID )
        const y_norm = Math.floor( y / GRID )
        // console.log (`mouseMove: (${x_norm},${y_norm})`)

        setMousePositionNorm ({
            x: x_norm,
            y: y_norm
        })
    }


    //
    // Draw grid assist object
    //
    useEffect (() => {
        if (!_cursorGridRectRef.current) {
            return
        }

        if (!mouseInCanvas) {
            _cursorGridRectRef.current.visible = false
        }
        else {
            _cursorGridRectRef.current.visible = true
            _cursorGridRectRef.current.left = mousePositionNorm.x * GRID
            _cursorGridRectRef.current.top  = mousePositionNorm.y * GRID
        }

        _canvasRef.current.renderAll ()

    }, [mousePositionNorm, mouseInCanvas]);


    //
    // Hiding popup
    //
    function hidePopup () {

        for (const grid of _selectedGridsRef.current) {
            _gridAssistRectsRef.current [`(${grid.x},${grid.y})`].visible = false
        }

        setModalVisibility (false)
        _modalVisibilityRef.current = false

        _selectStateRef.current = 'idle'
        _selectedGridsRef.current = []
        setSelectedGrids ([])
    }

    //
    // Return rendered element
    //
    return(
        <div style={{textAlign:'center',display:'flex',flexDirection:'column'}}>
            <div style={{textAlign:'center',display:'flex',flexDirection:'row'}}>

                <div style={{marginTop:'1em'}}>
                    <h3>Puzzle Id: {shownPuzzleId}</h3>

                    {
                        !hasLoadedDB && (
                            <div style={{zIndex:10,width:'320px',height:'320px'}}>
                                <p style={{textAlign:'center',lineHeight:'320px',fontSize:'14px'}}>Loading ...</p>
                            </div>
                        )

                    }
                    {/* <div style={{zIndex:10,width:'320px',height:'320px',visibility:loading_visibility}}>
                        <p style={{textAlign:'center',lineHeight:'320px'}}>Heyy</p>
                    </div> */}

                    <div
                        id="canvas_wrap" tabIndex="-1"
                        onMouseMove={(ev)=> handleMouseMove(ev)}
                    >
                        <canvas id="c" />
                    </div>
                </div>

                <div style={{marginLeft:'5em',marginTop:'1em',width:'18em'}}>
                    {children}
                </div>

            </div>

            <div style={{paddingTop:'2em'}}>
                <Modal
                    show    = {modalVisibility}
                    onHide  = {hidePopup}
                    info    = {modalInfo}
                    account = {account}
                    puzzle_id = {shownPuzzleId}
                />
            </div>
        </div>
    );

}
