import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import { DEVICE_COLOR_MAP } from './ConstantDeviceColors'
import { DEVICE_RESOURCE_MAP } from './ConstantDeviceResources'
import { PERLIN_COLOR_MAP } from './ConstantPerlinColors'

// import sound_open from '../public/sound-open.ogg'
// import sound_close from '../public/sound-close.ogg';

import {
    useCivState,
    usePlayerBalances,
    useDeployedDevices,
    useUtxSets,

    useDeployedPgs,
    useDeployedHarvesters,
    useDeployedTransformers,
    useDeployedUpsfs,
    useDeployedNdpes
} from '../lib/api'

import Modal from "./Modal";
import HUD from "./HUD"

import {
    useStarknet
} from '@starknet-react/core'

//
// Note: reading requirement (translated to Apibara integration design)
//
// 1. get the type & grid of all deployed-devices (for display)
// -- const { data: deployed_all } = useDeployedAll ()
// 2. given a grid, know if the grid is empty, or the device-id of the deployed-device there
// -- const { data: }
// 3. given the device-id of a deployed-device, know its owner, type, resource balance, energy balance
// 4. given an account, know the number of undeployed-devices of all types owned by it
// 5. know all acocunts in this universe
// 6. know if this universe is active or not, and if active, know this universe's civ-id
// 7. know how many L2 blocks left for this universe till max age reached
// UX: click at one grid => show it's empty or the device info of deployed-device
// UX: press key 'q' to toggle 'emphasize my deployed-devices' on/off

//
// Note: writing requirement
//
// 1. deploy device (single grid)
// 2. deploy UTX (multple grids; check contiguity at frontend or not?)
// 3. pick up device
// 4. pick up UTX
// 5. manufacture at UPSF
// 6. launch NDPE
// 7. transfer undeployed device
// UX: multi call

//
// Import pre-generated perlin values
//
const PERLIN_VALUES = require('../public/perlin_planet_dim_25.json');

//
// Dimensions
//
const SIDE = 25 // number of grids per size (planet dimension)
const GRID = 8 // grid size
const PAD_X = 160 // pad size
const PAD_Y = 120 // pad size
const CANVAS_W = 1122
const CANVAS_H = 900
const TRIANGLE_W = 6
const TRIANGLE_H = 10

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
DEVICE_DIM_MAP.set(12, 1);
DEVICE_DIM_MAP.set(13, 1);
DEVICE_DIM_MAP.set(14, 5);
DEVICE_DIM_MAP.set(15, 5);

//
// Sizes
//
const STROKE_WIDTH_CURSOR_FACE = 2
const STROKE_WIDTH_AXIS = 0.4
const STROKE_WIDTH_GRID = 0.1
const STROKE_WIDTH_GRID_FACE = 0.4

//
// Styles
//
const PALETTE = 'DARK'
const STROKE             = PALETTE === 'DARK' ? '#DDDDDD' : '#BBBBBB' // grid stroke color
const CANVAS_BG          = PALETTE === 'DARK' ? '#282828' : '#E3EDFF'
const STROKE_CURSOR_FACE = PALETTE === 'DARK' ? '#DDDDDD' : '#999999'
const STROKE_GRID_FACE   = PALETTE === 'DARK' ? '#CCCCCC' : '#333333'
const GRID_ASSIST_TBOX   = PALETTE === 'DARK' ? '#CCCCCC' : '#333333'
const FILL_CURSOR_GRID            = PALETTE === 'DARK' ? '#AAAAAA55' : '#AAAAAA55'
const FILL_CURSOR_SELECTED_GRID   = PALETTE === 'DARK' ? '#DDDDDD55' : '#AAAAAA55'

//
// Animation
//
const ANIM_UPDATE_INTERVAL_MS = 150

//
// Sound effect
//
const VOLUME = 0.2

//
// Helper function for creating the triangles at the tips of axes
//
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

    const { account } = useStarknet()

    //
    // Data fetched from backend on Apibara
    //
    const { data: db_civ_state } = useCivState ()
    const { data: db_player_balances } = usePlayerBalances ()
    const { data: db_deployed_devices } = useDeployedDevices ()
    const { data: db_utx_sets } = useUtxSets ()

    const { data: db_deployed_pgs } = useDeployedPgs ()
    const { data: db_deployed_harvesters } = useDeployedHarvesters ()
    const { data: db_deployed_transformers } = useDeployedTransformers ()
    const { data: db_deployed_upsfs } = useDeployedUpsfs ()
    // const { data: db_deployed_ndpes } = useDeployedNdpes ()

    //
    // React References
    //
    const _canvasRef = useRef();
    const _hasDrawnRef = useRef();
    const _coordTextRef = useRef();
    const _cursorGridRectRef = useRef();
    const _cursorFaceRectRef = useRef();
    const modalVisibilityRef = useRef(false)
    const _displayModeRef = useRef('devices')
    const _displayModeTextRef = useRef('');

    const _deviceDisplayRef = useRef();
    const _feDisplayRef = useRef();

    const _gridAssistRectsGroupRef = useRef();
    const _gridAssistRectsRef = useRef({});

    const _mouseStateRef = useRef('up'); // up => down => up
    const _selectStateRef = useRef('idle'); // idle => select => popup => idle
    const _selectedGridsRef = useRef([]);

    const _utxAnimRectsRef = useRef([]); // references to the animation rectangles
    const _utxAnimGridsRef = useRef([]); // references to the animation grids for each rectangle (2d array)
    const _utxAnimGridIndicesRef = useRef([]); // references to the current animation index for each rectangle

    const _gridMapping = useRef({});

    const _panStateRef = useRef({'panning':false, 'last_x':0, 'last_y':0});

    //
    // React States
    //
    const [hasLoadedDB, setHasLoadedDB] = useState(false)
    const [hasDrawnState, setHasDrawnState] = useState(0)
    const [ClickPositionNorm, setClickPositionNorm] = useState({left: 0, top: 0})
    const [MousePositionNorm, setMousePositionNorm] = useState({x: 0, y: 0})
    const [modalVisibility, setModalVisibility] = useState(false)
    const [modalInfo, setModalInfo] = useState({})
    const [selectedGrids, setSelectedGrids] = useState([])
    const [gridMapping, setGridMapping] = useState()
    const [accountInCiv, setAccountInCiv] = useState(false)

    const [hudLines, setHudLines] = useState([])
    const [hudVisible, setHudVisible] = useState (false)

    // const [hoverTransferDeviceRect, setHoverTransferDeviceRect] = useState(false)

    //
    // useEffect for checking if all database collections are loaded
    //
    useEffect (() => {
        if (hasLoadedDB) {
            return
        }
        if (!db_civ_state || !db_player_balances || !db_deployed_devices || !db_utx_sets || !db_deployed_pgs || !db_deployed_harvesters || !db_deployed_transformers || !db_deployed_upsfs) {
            console.log ('db not loaded..')
            return
        }
        else {
            console.log ('db loaded!')
            setHasLoadedDB (true)
        }
    }, [db_civ_state, db_player_balances, db_deployed_devices, db_deployed_pgs, db_deployed_harvesters, db_deployed_transformers, db_deployed_upsfs]);

    //
    // useEffect to check if the signed in account is in current civilization
    //
    useEffect (() => {
        if (!db_player_balances) return
        if (!account) return

        const player_balances = db_player_balances.player_balances
        var account_intstr_list = []
        for (const entry of player_balances) {
            account_intstr_list.push (entry['account'])
        }

        const account_intstr = toBN(account).toString()

        if (account_intstr_list.includes(account_intstr)) {
            console.log ('account is in this civilization')
            setAccountInCiv (true)
        }
        else {
            console.log ('account is not in this civilization')
            setAccountInCiv (false)
        }

    }, [db_player_balances, account]);


    //
    // Function to build mapping from device id to device info for various device classes
    //
    function prepare_grid_mapping () {

        //
        // Build mapping for device id => resource & energy balances
        //
        const deployed_pg_mapping = new Map();
        for (const pg of db_deployed_pgs.deployed_pgs) {
            deployed_pg_mapping.set(
                pg['id'],
                {
                    'energy' : pg['energy']
                }
            );
        }

        // ref: https://stackoverflow.com/questions/10640159/key-for-javascript-dictionary-is-not-stored-as-value-but-as-variable-name
        const deployed_harvester_mapping = new Map();
        for (const harvester of db_deployed_harvesters.deployed_harvesters) {
            const resource_type = DEVICE_RESOURCE_MAP [harvester['type']]

            deployed_harvester_mapping.set(
                harvester['id'],
                {
                    [resource_type] : harvester['resource'],
                    'energy' : harvester['energy']
                }
            );
        }

        const deployed_transformer_mapping = new Map();
        for (const transformer of db_deployed_transformers.deployed_transformers) {
            const resource_type_pre  = DEVICE_RESOURCE_MAP [transformer['type']] ['pre']
            const resource_type_post = DEVICE_RESOURCE_MAP [transformer['type']] ['post']

            deployed_transformer_mapping.set(
                transformer['id'],
                {
                    [resource_type_pre]  : transformer['resource_pre'],
                    [resource_type_post] : transformer['resource_post'],
                    'energy' : transformer['energy']
                }
            );
        }

        const deployed_upsf_mapping = new Map();
        for (const upsf of db_deployed_upsfs.deployed_upsfs) {
            deployed_upsf_mapping.set(
                upsf['id'],
                {
                    'FE raw     ' : upsf['resource_0'],
                    'AL raw     ' : upsf['resource_1'],
                    'CU raw     ' : upsf['resource_2'],
                    'SI raw     ' : upsf['resource_3'],
                    'PU raw     ' : upsf['resource_4'],
                    'FE refined ' : upsf['resource_5'],
                    'AL refined ' : upsf['resource_6'],
                    'CU refined ' : upsf['resource_7'],
                    'SI refined ' : upsf['resource_8'],
                    'PU enriched' : upsf['resource_9'],
                    'Energy     ' : upsf['energy']
                }
            );
        }

        // const deployed_ndpe_mapping = new Map();
        // for (const ndpe of db_deployed_ndpes) {
        //     deployed_ndpe_mapping.set(
        //         ndpe['id'],
        //         {
        //             'energy' : ndpe['energy']
        //         }
        //     );
        // }


        for (const entry of db_deployed_devices.deployed_devices){
            const x = entry.grid.x
            const y = entry.grid.y
            const typ = parseInt (entry.type)
            const id = entry.id

            const owner_hexstr = toBN(entry.owner).toString(16)
            const owner_hexstr_abbrev = "0x" + owner_hexstr.slice(0,3) + "..." + owner_hexstr.slice(-4)

            const device_dim = DEVICE_DIM_MAP.get (typ)

            var balances
            if (typ in [0, 1]) {
                balances = deployed_pg_mapping.get (id)
            }
            else if (typ in [2,3,4,5,6]) {
                balances = deployed_harvester_mapping.get (id)
            }
            else if (typ in [7,8,9,10,11]) {
                balances = deployed_transformer_mapping.get (id)
            }
            else if (typ == 14) {
                balances = deployed_upsf_mapping.get (id)
            }
            else {
                balances = {}
            }

            // Use device dimension to insert entry into grid mapping (every device is a square)
            for (const i=0; i<device_dim; i++) {
                for (const j=0; j<device_dim; j++) {
                    _gridMapping.current [`(${x+i},${y+j})`] = {
                        'owner' : owner_hexstr_abbrev,
                        'type' : typ,
                        'balances' : balances
                    }
                }
            }

        }

        setGridMapping (_gridMapping.current)

        return
    }

    function convert_screen_to_grid_x (x) {
        return Math.floor( (x - PAD_X) / GRID )
    }

    function convert_screen_to_grid_y (y) {
        return SIDE*3 - 1 - Math.floor( (y - PAD_Y) / GRID )
    }

    //
    // Selection control mechanism -- linear state transitions:
    // - mouse down, if select state in 'idle', if in grid range => select state = 'select', mouse state = 'down', push {x,y} to selectedGridsState
    // - mouse drag, if select state in 'select', if mouse state in 'down', if in grid range and not in selectedGridsState => push {x,y} to selectedGridsState
    // - mouse up, if in grid range and if selectedGridsState is not empty => select state = 'popup'
    // - esc keypress / esc button clicked, if select state in 'popup' => select state = 'idle', setSelectedGridsState([])
    //

    function handleLeftMouseDown (x, y) {
        _mouseStateRef.current = 'down'
        if (_displayModeRef.current !== 'devices') {
            return
        }

        const x_grid = convert_screen_to_grid_x (x)
        const y_grid = convert_screen_to_grid_y (y)
        const bool_in_range = is_valid_coord (x_grid, y_grid)
        const bool_in_idle = (_selectStateRef.current === 'idle')

        if (bool_in_idle && bool_in_range) {
            _selectStateRef.current = 'select'
            _selectedGridsRef.current.push ({x: x_grid, y: y_grid})

            setSelectedGrids( selectedGrids.concat({x: x_grid, y: y_grid}) )

            const face = find_face_given_grid (x_grid, y_grid)
            const face_ori = find_face_ori (face)
            _gridAssistRectsRef.current [`(${face},${x_grid-face_ori[0]},${y_grid-face_ori[1]})`].visible = true
        }
    }

    function handleMouseDrag (x, y) { // selectState in 'select' confirmed already
        if (_displayModeRef.current !== 'devices') {
            return
        }

        const bool_mouse_down = (_mouseStateRef.current === 'down')

        const x_grid = convert_screen_to_grid_x (x)
        const y_grid = convert_screen_to_grid_y (y)
        const bool_in_range = is_valid_coord (x_grid, y_grid)

        // ref:
        // https://stackoverflow.com/questions/50371188/javascripts-includes-function-not-working-correctly-with-array-of-objects
        var bool_exist = _selectedGridsRef.current.some (ele =>{
            return JSON.stringify({x: x_grid, y: y_grid}) === JSON.stringify(ele);
        });

        if (bool_mouse_down && bool_in_range && !bool_exist) {
            _selectedGridsRef.current.push ({x: x_grid, y: y_grid})
            setSelectedGrids( selectedGrids.concat({x: x_grid, y: y_grid}) )

            const face = find_face_given_grid (x_grid, y_grid)
            const face_ori = find_face_ori (face)
            _gridAssistRectsRef.current [`(${face},${x_grid-face_ori[0]},${y_grid-face_ori[1]})`].visible = true
        }
    }

    function handleLeftMouseUp (x, y) {
        _mouseStateRef.current = 'up'
        if (_displayModeRef.current !== 'devices') {
            return
        }

        // pause and reset all sounds
        for (const id of ['sound-popup-close', 'sound-popup-open']) {
            var sound = document.getElementById(id);
            sound.pause ()
            sound.currentTime = 0
        }

        // play opening sound
        var sound_open = document.getElementById('sound-popup-open');
        sound_open.volume = VOLUME
        sound_open.play ()

        const x_grid = convert_screen_to_grid_x (x)
        const y_grid = convert_screen_to_grid_y (y)
        const bool_in_range = is_valid_coord (x_grid, y_grid)
        const bool_not_empty = (_selectedGridsRef.current.length !== 0)

        if (bool_in_range && bool_not_empty) {
            _selectStateRef.current = 'popup'
            setModalVisibility (true)
            modalVisibilityRef.current = true

            const info = {
                'grids' : _selectedGridsRef.current
            }
            setModalInfo (info)
        }
    }

    function hidePopup () {

        // pause and reset all sounds
        for (const id of ['sound-popup-close', 'sound-popup-open']) {
            var sound = document.getElementById(id);
            sound.pause ()
            sound.currentTime = 0
        }

        // play closing sound
        var sound_close = document.getElementById('sound-popup-close');
        sound_close.volume = VOLUME
        sound_close.play ()

        for (const grid of _selectedGridsRef.current) {
            const face = find_face_given_grid (grid.x, grid.y)
            const face_ori = find_face_ori (face)
            _gridAssistRectsRef.current [`(${face},${grid.x-face_ori[0]},${grid.y-face_ori[1]})`].visible = false
        }

        setModalVisibility (false)
        modalVisibilityRef.current = false

        _selectStateRef.current = 'idle'
        _selectedGridsRef.current = []
        setSelectedGrids ([])
    }

    //
    // Handle key down events
    // ref: https://stackoverflow.com/questions/37440408/how-to-detect-esc-key-press-in-react-and-how-to-handle-it
    //
    const handleKeyDown = useCallback((ev) => {

        if (!_hasDrawnRef.current) {
            return
        }

        if (ev.key === 'c') {

            _canvasRef.current.setZoom(1)  // reset zoom so pan actions work as expected
            _canvasRef.current.absolutePan({
                x: 0,
                y: 0
            });
            _canvasRef.current.renderAll ()
        }

        if (ev.key === "Escape") {
            if (modalVisibilityRef.current) {
                hidePopup ()
            }
        }
        else if(ev.key === '1'){
            console.log('1')
            _displayModeRef.current = 'devices'

            change_working_view_visibility (true)

            _feDisplayRef.current.visible = false
            updateMode (_canvasRef.current, 'devices')
            setHudLines ( arr => [
                arr[0], `Display: devices`
            ])
        }
        else if(ev.key === '2'){
            console.log('2')
            _displayModeRef.current = 'fe'

            change_working_view_visibility (false)

            _feDisplayRef.current.visible = true
            updateMode (_canvasRef.current, 'FE distribution')
            setHudLines ( arr => [
                arr[0], `Display: FE distribution`
            ])
        }
        else if(ev.key === '3'){
            console.log('3')
            _displayModeRef.current = 'al'
            updateMode (_canvasRef.current, 'AL distribution')
            setHudLines ( arr => [
                arr[0], `Display: AL distribution`
            ])
        }
        else if(ev.key === '4'){
            console.log('4')
            _displayModeRef.current = 'cu'
            updateMode (_canvasRef.current, 'CU distribution')
            setHudLines ( arr => [
                arr[0], `Display: CU distribution`
            ])
        }
        else if(ev.key === '5'){
            console.log('5')
            _displayModeRef.current = 'si'
            updateMode (_canvasRef.current, 'SI distribution')
            setHudLines ( arr => [
                arr[0], `Display: SI distribution`
            ])
        }
        else if(ev.key === '6'){
            console.log('6')
            _displayModeRef.current = 'pu'
            updateMode (_canvasRef.current, 'PU distribution')
            setHudLines ( arr => [
                arr[0], `Display: PU distribution`
            ])
        }

        else if(ev.key === '7') {
            console.log('7')

            // pause and reset all sounds
            for (const id of ['sound-popup-close', 'sound-popup-open']) {
                var sound = document.getElementById(id);
                sound.pause ()
                sound.currentTime = 0
            }

            // play opening sound
            var sound_open = document.getElementById('sound-popup-open');
            sound_open.volume = VOLUME
            sound_open.play ()

            _selectStateRef.current = 'popup'
            setModalVisibility (true)
            modalVisibilityRef.current = true
            const info = {
                'grids' : null
            }
            setModalInfo (info)
        }

      }, [modalVisibility]);

    function change_working_view_visibility (visibility) {

        _deviceDisplayRef.current.visible = visibility

        for (const rect of _utxAnimRectsRef.current) {
            rect.visible = visibility
        }
    }

    //
    // Grid / face assistance
    //
    var coordText = new fabric.IText( '(-,-)', {
        fontSize:14,
        left: PAD_X + 3.2*GRID*SIDE,
        top: PAD_Y - 3*GRID,
        radius:10,
        fill: GRID_ASSIST_TBOX,
        borderRadius: '25px',
        hasRotatingPoint: true,
        selectable: false,
        fontFamily: "Poppins-Light"
    });

    var cursorGridRect = new fabric.Rect({
        height: GRID,
        width: GRID,
        left: PAD_X,
        top: PAD_Y,
        fill: FILL_CURSOR_GRID,
        selectable: false,
        hoverCursor: 'default',
        visible: false,
        strokeWidth: 0
    });

    var cursorFaceRect = new fabric.Rect({
        height: GRID*SIDE,
        width: GRID*SIDE,
        left: PAD_X,
        top: PAD_Y,
        fill: "",
        stroke: STROKE_CURSOR_FACE,
        strokeWidth: STROKE_WIDTH_CURSOR_FACE,
        selectable: false,
        hoverCursor: 'default',
        visible: false,
        strokeWidth: 0
    });

    //
    // text box showing current display mode
    //
    var displayModeText = new fabric.Text( 'Display: devices',
    {
        fontSize: 14, fill: '#CCCCCC',
        left: PAD_X + 3.2*GRID*SIDE,
        top: PAD_Y,
        width: "150px",
        selectable: false,
        fontFamily: "Poppins-Light"
    });

    //
    // create canvas, and handle mouse events
    //
    useEffect (() => {

        _canvasRef.current = new fabric.Canvas('c', {
            height: CANVAS_H,
            width: CANVAS_W,
            backgroundColor: CANVAS_BG,
            selection: false,
            fireRightClick: true,
            stopContextMenu: true
        })

        _canvasRef.current.on("mouse:move" ,function(opt){

            //
            // mouse x & y adjustment
            // ref: https://stackoverflow.com/a/30869635
            //
            var pointer = _canvasRef.current.getPointer(opt.e);
            var posx = pointer.x;
            var posy = pointer.y;

            //
            // handle grid selection
            //
            if (_selectStateRef.current === 'select'){
                // handleMouseDrag (opt.e.clientX, opt.e.clientY)
                handleMouseDrag (posx, posy)
            }

            //
            // handle panning
            //
            if (_panStateRef.current['panning'] == true) {
                _canvasRef.current.relativePan({ x: opt.e.clientX - _panStateRef.current['last_x'], y: opt.e.clientY - _panStateRef.current['last_y'] });
                _canvasRef.current.requestRenderAll();
                _panStateRef.current['last_x'] = opt.e.clientX;
                _panStateRef.current['last_y'] = opt.e.clientY;
            }

        })
        _canvasRef.current.on("mouse:down" ,function(opt){

            var pointer = _canvasRef.current.getPointer(opt.e);
            var posx = pointer.x;
            var posy = pointer.y;

            //
            // handle mouse panning
            //
            // var evt= opt.e;
            // if (evt.altKey === true) {
            //     this.isDragging = true;
            //     this.selection = false;
            //     this.lastPosX = evt.clientX;
            //     this.lastPosY = evt.clientY;
            // }

            //
            // handle grid selection
            //
            if (opt.e.button == 0){
                handleLeftMouseDown (posx, posy)
            }

            //
            // handle pan state
            //
            if (opt.e.button == 2){
                _panStateRef.current['panning'] = true
                _panStateRef.current['last_x'] = opt.e.clientX
                _panStateRef.current['last_y'] = opt.e.clientY
            }
        })
        _canvasRef.current.on("mouse:up" ,function(opt){

            var pointer = _canvasRef.current.getPointer(opt.e);
            var posx = pointer.x;
            var posy = pointer.y;

            //
            // handle mouse panning
            //
            // this.setViewportTransform(this.viewportTransform);
            // this.isDragging = false;
            // this.selection = true;

            //
            // handle grid selection
            //
            if (opt.e.button == 0){
                handleLeftMouseUp (posx, posy)
            }

            //
            // handle pan state
            //
            if (opt.e.button == 2){
                _panStateRef.current['panning'] = false
            }
        })

        _canvasRef.current.on('mouse:wheel', function(opt) {
            var delta = opt.e.deltaY;
            var zoom = _canvasRef.current.getZoom();
            zoom *= 0.999 ** delta;
            if (zoom > 20) zoom = 20;
            if (zoom < 1) zoom = 1;

            _canvasRef.current.zoomToPoint({ x: opt.e.offsetX, y: opt.e.offsetY }, zoom);
            // _canvasRef.current.setZoom(zoom);
            opt.e.preventDefault();
            opt.e.stopPropagation();

            // var vpt = this.viewportTransform;
            // if (vpt[4] >= 0) {
            //     vpt[4] = 0;
            // } else if (vpt[4] < _canvasRef.current.getWidth() - 1000 * zoom) {
            //     vpt[4] = _canvasRef.current.getWidth() - 1000 * zoom;
            // }
            // if (vpt[5] >= 0) {
            //     vpt[5] = 0;
            // } else if (vpt[5] < _canvasRef.current.getHeight() - 1000 * zoom) {
            //     vpt[5] = _canvasRef.current.getHeight() - 1000 * zoom;
            // }

        })

        _hasDrawnRef.current = false

        document.addEventListener("keydown", handleKeyDown, false);
        return () => {
            document.removeEventListener("keydown", handleKeyDown, false);
        };

    }, []);

    useEffect (() => {
        if (!_hasDrawnRef.current) {
            drawWorld (_canvasRef.current)
            setHudVisible (true)
        }
    }, [hasLoadedDB]);

    const initializeGridAssistRectsRef = canvi => {

        //
        // traverse across all grids of all faces, push a var Rect object to _gridAssistRectsRef,
        // with key being stringified grid coord `(${face},${col},${row})`
        //
        var gridAssistRects = []
        for (var face=0; face<6; face++) {
            const face_ori = find_face_ori (face)
            for (var row=0; row<SIDE; row++) {
                for (var col=0; col<SIDE; col++) {

                    var gridAssistRect = new fabric.Rect({
                        height: GRID, width: GRID,
                        left: PAD_X + (col + face_ori[0]) * GRID,
                        top:  PAD_Y + (SIDE*3 - (row + face_ori[1]) - 1) * GRID,
                        fill: FILL_CURSOR_SELECTED_GRID,
                        selectable: false,
                        hoverCursor: 'default',
                        visible: false,
                        strokeWidth: 0
                    });

                    gridAssistRects.push (gridAssistRect)
                    _gridAssistRectsRef.current [`(${face},${col},${row})`] = gridAssistRect
                    canvi.add (gridAssistRect)
                }
            }
        }

        const group = new fabric.Group(
            gridAssistRects, {
                visible: false,
                selectable: false,
                hoverCursor: 'default'
        });
        _gridAssistRectsGroupRef.current = group
        canvi.add (group)

        canvi.renderAll();
    }

    const drawWorld = canvi => {

        if (hasLoadedDB) {

            if (db_civ_state.civ_state[0].active != 1) {
                console.log ("This universe is not active.")
                drawIdleMessage (canvi)
                return
            }
            else {
                prepare_grid_mapping ()

                drawGrid (canvi)
                drawDevices (canvi)
                drawPerlin (canvi)
                drawAssist (canvi) // draw assistance objects the last to be on top
                drawUtxAnim (canvi)
                // drawMode (canvi)
                initializeGridAssistRectsRef (canvi)

                setHudLines ([
                    'Face - / Grid (-,-)',
                    'Display: devices'
                ])

                _hasDrawnRef.current = true
                setHasDrawnState (1)

                document.getElementById('canvas_wrap').focus();
            }
        }
    }

    const drawIdleMessage = canvi => {
        const TBOX_FONT_FAMILY = 'Poppins-Light'

        const tbox_idle_message = new fabric.Textbox(
            'This universe is not active.', {
                width: 200,
                top:  CANVAS_H/2 - 100,
                left: CANVAS_W/2 - 100,
                fontSize: 20,
                textAlign: 'left',
                fill: "#333333",
                hoverCursor: 'default',
                fontFamily: TBOX_FONT_FAMILY
            });
        canvi.add (tbox_idle_message)
    }

    //
    // UTX animation
    //
    const drawUtxAnim = canvi => {
        if (!db_utx_sets) return

        for (const utx_set of db_utx_sets.utx_sets) {

            //
            // For each utx set, create a rect for animation
            //
            const color = DEVICE_COLOR_MAP.get(`${utx_set.type}-anim`)
            const rect = new fabric.Rect({
                height: GRID,
                width: GRID,
                left: PAD_X + utx_set.grids[0].x*GRID,
                top:  PAD_Y + (SIDE*3 - utx_set.grids[0].y - 1)*GRID,
                fill: color,
                selectable: false,
                hoverCursor: 'default',
                strokeWidth: 0
            });
            _utxAnimRectsRef.current.push (rect)

            //
            // For each utx set, set the grids along its animation path;
            // set animation index to 0
            //
            _utxAnimGridsRef.current.push (utx_set.grids)
            _utxAnimGridIndicesRef.current.push (0)

            canvi.add (rect)
        }
    }
    // reference: https://stackoverflow.com/questions/57137094/implementing-a-countdown-timer-in-react-with-hooks
    useEffect(() => {

        if (!db_utx_sets) return;
        if (hasDrawnState === 0) return;
        if (_canvasRef === null) return;

        const n_utx_set = db_utx_sets.utx_sets.length

        const interval = setInterval(() => {

            for (const i=0; i<n_utx_set; i++) {

                //
                // get the next animation index
                //
                const anim_length = _utxAnimGridsRef.current[i].length
                const anim_idx_ = _utxAnimGridIndicesRef.current[i] + 1
                const anim_idx = (anim_idx_ == anim_length) ? 0 : anim_idx_
                // console.log (`${i} anim_idx=${anim_idx}`)
                _utxAnimGridIndicesRef.current[i] = anim_idx

                //
                // animate x
                //
                const x = _utxAnimGridsRef.current[i][anim_idx].x
                _utxAnimRectsRef.current[i].left = PAD_X + x*GRID

                //
                // animate y
                //
                const y = _utxAnimGridsRef.current[i][anim_idx].y
                _utxAnimRectsRef.current[i].top = PAD_Y + (SIDE*3 - y - 1)*GRID

                // console.log (`ANIMATE: new grid (${x}, ${y})`)
            }
            _canvasRef.current.renderAll ();

        }, ANIM_UPDATE_INTERVAL_MS);

        return () => clearInterval(interval);
    }, [hasDrawnState]);


    const drawGrid = canvi => {
        const TBOX_FONT_FAMILY = "Poppins-Light"
        const TBOX_FONT_SIZE = 14

        //
        // Axes for coordinate system
        //
        const AXIS_EXTEND_GRID_MULTIPLE_X = 7
        const AXIS_EXTEND_GRID_MULTIPLE_Y = 6
        canvi.add(new fabric.Line([
            PAD_X + 0,
            PAD_Y + 0 - GRID*AXIS_EXTEND_GRID_MULTIPLE_Y,
            PAD_X + 0,
            PAD_Y + SIDE*GRID*3
        ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_AXIS, selectable: false, hoverCursor: 'default' }));
        canvi.add(new fabric.Line([
            PAD_X + 0,
            PAD_Y + SIDE*GRID*3,
            PAD_X + SIDE*GRID*4 + GRID*AXIS_EXTEND_GRID_MULTIPLE_X,
            PAD_Y + SIDE*GRID*3
        ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_AXIS, selectable: false, hoverCursor: 'default' }));

        const triangle_y_axis = createTriangle (
            PAD_X -(TRIANGLE_W/2),
            PAD_Y - GRID*AXIS_EXTEND_GRID_MULTIPLE_Y - TRIANGLE_H,
            0
        )
        const triangle_x_axis = createTriangle (
            PAD_X + SIDE*GRID*4 + GRID*AXIS_EXTEND_GRID_MULTIPLE_X,
            PAD_Y + SIDE*GRID*3 - TRIANGLE_W,
            90
        )
        canvi.add (triangle_y_axis);
        canvi.add (triangle_x_axis);

        //
        // Axis ticks and labels
        //
        const DRAW_AXIS_TICKS_AND_LABELS = true
        if (DRAW_AXIS_TICKS_AND_LABELS) {
            const tbox_x = new fabric.Textbox(
                'x', {
                    width: 100,
                    left: PAD_X + SIDE*GRID*4 + GRID*AXIS_EXTEND_GRID_MULTIPLE_X + GRID*2.5,
                    top:  PAD_Y + SIDE*GRID*2.9 + 1.3*GRID,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });
            const tbox_y = new fabric.Textbox(
                'y', {
                    width: 100,
                    left: PAD_X - 0.4*GRID,
                    top:  PAD_Y - 11*GRID,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const tbox_origin = new fabric.Textbox(
                '(0,0)', {
                    width: 100,
                    left: PAD_X + 0 - GRID*2,
                    top:  PAD_Y + SIDE*GRID*3 + GRID*1.3,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_y_d = '(0,' + SIDE.toString() + ')'
            const tbox_y_d = new fabric.Textbox(
                text_y_d, {
                    width: 100,
                    left: PAD_X + 0 - GRID*6,
                    top:  PAD_Y + SIDE*GRID*2 - GRID*1.5,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_y_2d = '(0,' + (2*SIDE).toString() + ')'
            const tbox_y_2d = new fabric.Textbox(
                text_y_2d, {
                    width: 100,
                    left: PAD_X + 0 - GRID*6,
                    top:  PAD_Y + SIDE*GRID*1 - GRID*1.5,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_y_3d = '(0,' + (3*SIDE).toString() + ')'
            const tbox_y_3d = new fabric.Textbox(
                text_y_3d, {
                    width: 100,
                    left: PAD_X + 0 - GRID*6,
                    top:  PAD_Y + SIDE*GRID*0 - GRID*1.5,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_x_d = '(' + SIDE.toString() + ',0)'
            const tbox_x_d = new fabric.Textbox(
                text_x_d, {
                    width: 100,
                    left: PAD_X + SIDE*GRID*1 - GRID*2.5,
                    top:  PAD_Y + SIDE*GRID*3 + GRID*1.3,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_x_2d = '(' + (2*SIDE).toString() + ',0)'
            const tbox_x_2d = new fabric.Textbox(
                text_x_2d, {
                    width: 100,
                    left: PAD_X + SIDE*GRID*2 - GRID*2.5,
                    top:  PAD_Y + SIDE*GRID*3 + GRID*1.3,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_x_3d = '(' + (3*SIDE).toString() + ',0)'
            const tbox_x_3d = new fabric.Textbox(
                text_x_3d, {
                    width: 100,
                    left: PAD_X + SIDE*GRID*3 - GRID*2.5,
                    top:  PAD_Y + SIDE*GRID*3 + GRID*1.3,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            const text_x_4d = '(' + (4*SIDE).toString() + ',0)'
            const tbox_x_4d = new fabric.Textbox(
                text_x_4d, {
                    width: 100,
                    left: PAD_X + SIDE*GRID*4 - GRID*2.5,
                    top:  PAD_Y + SIDE*GRID*3 + GRID*1.3,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    hoverCursor: 'default',
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false
                });

            canvi.add (tbox_x)
            canvi.add (tbox_y)
            canvi.add (tbox_origin)
            canvi.add (tbox_y_d)
            canvi.add (tbox_y_2d)
            canvi.add (tbox_y_3d)
            canvi.add (tbox_x_d)
            canvi.add (tbox_x_2d)
            canvi.add (tbox_x_3d)
            canvi.add (tbox_x_4d)
        }

        //
        // Grid lines
        //
        const DRAW_GRID_LINES = true
        if (DRAW_GRID_LINES) {
            //
            // Grid lines parallel to Y-axis
            //
            for (var xi = 0; xi < SIDE; xi++){
                canvi.add(new fabric.Line([
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID,
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID*2
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID, selectable: false, hoverCursor: 'default' }));
            }
            for (var xi = SIDE; xi < SIDE*2+1; xi++){
                canvi.add(new fabric.Line([
                    PAD_X + xi*GRID,
                    PAD_Y + 0,
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID*3
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID, selectable: false, hoverCursor: 'default' }));
            }
            for (var xi = 2*SIDE+1; xi < SIDE*4+1; xi++){
                canvi.add(new fabric.Line([
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID,
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID*2
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID, selectable: false, hoverCursor: 'default' }));
            }

            //
            // Grid lines parallel to X-axis
            //
            for (var yi = 0; yi < SIDE; yi++){
                canvi.add(new fabric.Line([
                    PAD_X + SIDE*GRID,
                    PAD_Y + yi*GRID,
                    PAD_X + SIDE*GRID*2,
                    PAD_Y + yi*GRID
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID, selectable: false, hoverCursor: 'default' }));
            }
            for (var yi = SIDE; yi < 2*SIDE+1; yi++){
                canvi.add(new fabric.Line([
                    PAD_X + 0,
                    PAD_Y + yi*GRID,
                    PAD_X + SIDE*GRID*4,
                    PAD_Y + yi*GRID
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID, selectable: false, hoverCursor: 'default' }));
            }
            for (var yi = 2*SIDE+1; yi < 3*SIDE+1; yi++){
                canvi.add(new fabric.Line([
                    PAD_X + SIDE*GRID,
                    PAD_Y + yi*GRID,
                    PAD_X + SIDE*GRID*2,
                    PAD_Y + yi*GRID
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID, selectable: false, hoverCursor: 'default' }));
            }
        }

        //
        // Grid lines for faces
        //
        const DRAW_GRID_FACE = true
        if (DRAW_GRID_FACE) {
            //
            // Lines parallel to x-axis
            //
            canvi.add(new fabric.Line([
                PAD_X + 0*GRID,    PAD_Y + SIDE*GRID,
                PAD_X + SIDE*GRID, PAD_Y + SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 0*GRID,    PAD_Y + 2*SIDE*GRID,
                PAD_X + SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + SIDE*GRID,   PAD_Y + 0*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 0*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + SIDE*GRID,   PAD_Y + 3*SIDE*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 3*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 2*SIDE*GRID, PAD_Y + SIDE*GRID,
                PAD_X + 3*SIDE*GRID, PAD_Y + SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 2*SIDE*GRID, PAD_Y + 2*SIDE*GRID,
                PAD_X + 3*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 3*SIDE*GRID, PAD_Y + SIDE*GRID,
                PAD_X + 4*SIDE*GRID, PAD_Y + SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 3*SIDE*GRID, PAD_Y + 2*SIDE*GRID,
                PAD_X + 4*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 1*SIDE*GRID, PAD_Y + 1*SIDE*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 1*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 1*SIDE*GRID, PAD_Y + 2*SIDE*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));

            //
            // Lines parallel to y-axis
            //
            canvi.add(new fabric.Line([
                PAD_X + SIDE*GRID, PAD_Y + 2*SIDE*GRID,
                PAD_X + SIDE*GRID, PAD_Y + 3*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 2*SIDE*GRID, PAD_Y + 2*SIDE*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 3*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 0*GRID, PAD_Y + SIDE*GRID,
                PAD_X + 0*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 4*SIDE*GRID, PAD_Y + SIDE*GRID,
                PAD_X + 4*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + SIDE*GRID, PAD_Y + 0*SIDE*GRID,
                PAD_X + SIDE*GRID, PAD_Y + 1*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 2*SIDE*GRID, PAD_Y + 0*SIDE*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 1*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 1*SIDE*GRID, PAD_Y + 1*SIDE*GRID,
                PAD_X + 1*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 2*SIDE*GRID, PAD_Y + 1*SIDE*GRID,
                PAD_X + 2*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
            canvi.add(new fabric.Line([
                PAD_X + 3*SIDE*GRID, PAD_Y + 1*SIDE*GRID,
                PAD_X + 3*SIDE*GRID, PAD_Y + 2*SIDE*GRID
            ], { stroke: STROKE_GRID_FACE, strokeWidth: STROKE_WIDTH_GRID_FACE, selectable: false, hoverCursor: 'default' }));
        }

        canvi.renderAll();
    }

    const drawMode = canvi => {
        canvi.add (displayModeText)
        _displayModeTextRef.current = displayModeText

        canvi.renderAll();
    }

    const updateMode = (canvi, mode) => {
        console.log ('updateMode()')
        _displayModeTextRef.current.text = 'Display: ' + mode
        _displayModeTextRef.current.dirty = true

        canvi.renderAll();
    }

    const drawAssist = canvi => {
        //
        // Draw textObject for showing user mouse coordinate
        //
        // canvi.add(coordText)
        // _coordTextRef.current = coordText

        canvi.add (cursorGridRect)
        _cursorGridRectRef.current = cursorGridRect

        canvi.add (cursorFaceRect)
        _cursorFaceRectRef.current = cursorFaceRect

        canvi.renderAll();
    }

    function lerp (start, end, ratio){
        return start + (end-start) * ratio
    }

    function find_face_ori (face) {
        if (face === 0) {
            return [0, SIDE]
        }
        else if (face === 1) {
            return [SIDE, 0]
        }
        else if (face === 2) {
            return [SIDE, SIDE]
        }
        else if (face === 3) {
            return [SIDE, 2*SIDE]
        }
        else if (face === 4) {
            return [2*SIDE, SIDE]
        }
        else { // face === 5
            return [3*SIDE, SIDE]
        }
    }

    // PERLIN_VALUES
    const drawPerlin = canvi => {

        const perlin_cells = []
        // console.log ("max perline value:", PERLIN_VALUES['max'])
        // console.log ("min perline value:", PERLIN_VALUES['min'])

        for (var face=0; face<6; face++) {

            const face_ori = find_face_ori (face)
            for (var row=0; row<SIDE; row++) {
                for (var col=0; col<SIDE; col++) {
                    const perlin_value = PERLIN_VALUES[face][row][col]
                    const perlin_value_normalized = (perlin_value - PERLIN_VALUES['min']) / (PERLIN_VALUES['max'] - PERLIN_VALUES['min'])
                    // console.log("perlin_value_normalized:", perlin_value_normalized)

                    const hi = PERLIN_COLOR_MAP['fe']['hi']
                    const lo = PERLIN_COLOR_MAP['fe']['lo']

                    const r = lerp (lo[0], hi[0], perlin_value_normalized)
                    const g = lerp (lo[1], hi[1], perlin_value_normalized)
                    const b = lerp (lo[2], hi[2], perlin_value_normalized)
                    const rect_color = `rgb(${r}, ${g}, ${b})`

                    const rect = new fabric.Rect({
                        height: GRID,
                        width: GRID,
                        // left: PAD_X + (col + face_ori[0]) * GRID,
                        // top:  PAD_Y + (SIDE*3 - (row + face_ori[1]) - 1) * GRID,
                        originX: 'center', originY: 'center',
                        fill: rect_color,
                        selectable: false,
                        strokeWidth: 0
                    });
                    var text = new fabric.Text(
                        perlin_value.toString(), {
                        fontSize: 4.1, fill: '#CCCCCC',
                        // left: PAD_X + (col + face_ori[0]) * GRID,
                        // top:  PAD_Y + (SIDE*3 - (row + face_ori[1]) - 1) * GRID,
                        // width: GRID,
                        originX: 'center', originY: 'center',
                        selectable: false,
                        fontFamily: "Poppins-Light"
                    });

                    const cell = new fabric.Group(
                        [ rect, text ], {
                        left: PAD_X + (col + face_ori[0]) * GRID,
                        top: PAD_Y + (SIDE*3 - (row + face_ori[1]) - 1) * GRID,
                    });
                    perlin_cells.push (cell)
                }
            }
            // break
        }

        var perlin_rect_face0_group = new fabric.Group(
            perlin_cells, {
                visible: false,
                selectable: false
            });
        canvi.add(perlin_rect_face0_group)
        _feDisplayRef.current = perlin_rect_face0_group

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
        const device_rects = []
        for (const entry of db_deployed_devices.deployed_devices){
            const x = entry.grid.x
            const y = entry.grid.y
            const typ = parseInt (entry.type)

            const device_dim = DEVICE_DIM_MAP.get(typ)
            const device_color = DEVICE_COLOR_MAP.get(typ)

            const rect = new fabric.Rect({
                height: device_dim*GRID,
                width: device_dim*GRID,
                left: PAD_X + x*GRID,
                top:  PAD_Y + (SIDE*3-y-device_dim)*GRID,
                fill: device_color,
                selectable: false,
                hoverCursor: 'pointer',
                strokeWidth: 0
            });
            device_rects.push (rect)
        }

        var device_rect_face0_group = new fabric.Group(
            device_rects, {
                visible: true,
                selectable: false
            });
        canvi.add(device_rect_face0_group)
        _deviceDisplayRef.current = device_rect_face0_group

        canvi.renderAll();
    }

    //
    // Grid assists and popup window
    //
    function find_face_given_grid (x, y) {
        const x0 = x >= 0 && x < SIDE
        const x1 = x >= SIDE && x < SIDE*2
        const x2 = x >= SIDE*2 && x < SIDE*3
        const x3 = x >= SIDE*3 && x < SIDE*4

        const y0 = y >= 0 && y < SIDE
        const y1 = y >= SIDE && y < SIDE*2
        const y2 = y >= SIDE*2 && y < SIDE*3

        // face 0
        if (x0 && y1) {
            return 0
        }

        // face 1
        if (x1 && y0) {
            return 1
        }

        // face 2
        if (x1 && y1) {
            return 2
        }

        // face 3
        if (x1 && y2) {
            return 3
        }

        // face 4
        if (x2 && y1) {
            return 4
        }

        // face 5
        if (x3 && y1) {
            return 5
        }

        return -1
    }

    function x_transform_normalized_to_canvas (x) {
        return PAD_X + x*GRID
    }
    function y_transform_normalized_to_canvas (y) {
        return PAD_Y + (SIDE*3 - y - 1)*GRID
    }

    function map_face_to_left_top (face) {
        if (face === 0){
            return ({
                left : x_transform_normalized_to_canvas (0),
                top  : y_transform_normalized_to_canvas (2*SIDE-1)
            })
        }
        if (face === 1){
            return ({
                left : x_transform_normalized_to_canvas (SIDE),
                top  : y_transform_normalized_to_canvas (SIDE-1)
            })
        }
        if (face === 2){
            return ({
                left : x_transform_normalized_to_canvas (SIDE),
                top  : y_transform_normalized_to_canvas (2*SIDE-1)
            })
        }
        if (face === 3){
            return ({
                left : x_transform_normalized_to_canvas (SIDE),
                top  : y_transform_normalized_to_canvas (3*SIDE-1)
            })
        }
        if (face === 4){
            return ({
                left : x_transform_normalized_to_canvas (2*SIDE),
                top  : y_transform_normalized_to_canvas (2*SIDE-1)
            })
        }
        else { // face === 5
            return ({
                left : x_transform_normalized_to_canvas (75),
                top  : y_transform_normalized_to_canvas (50-1)
            })
        }

    }

    function is_valid_coord (x, y) {
        const face = find_face_given_grid (x, y)

        if (face >= 0) {
            return true
        }
        else{
            return false
        }
    }

    function drawAssistObject (canvi, mPosNorm) {

        if (_cursorGridRectRef.current && _cursorFaceRectRef.current) {
            if (mPosNorm.x.toString() === '-') {
                //
                // Show face & coordinate textbox
                //
                // _coordTextRef.current.text = 'Face - / Grid (' + mPosNorm.x.toString() + ',' + mPosNorm.y.toString() + ')'
                // _coordTextRef.current.dirty  = true
                setHudLines ( arr => [
                    'Face - / Grid (' + mPosNorm.x.toString() + ',' + mPosNorm.y.toString() + ')', arr[1]
                ])

                //
                // Hide grid assist square
                //
                _cursorGridRectRef.current.visible = false

                //
                // Hide face assist square
                //
                _cursorFaceRectRef.current.visible = false
            }
            else {
                const face = find_face_given_grid (mPosNorm.x, mPosNorm.y)
                const ori  = map_face_to_left_top (face)

                //
                // Show face & coordinate textbox
                //
                // _coordTextRef.current.text = 'Face ' + face.toString() + ' / Grid (' + mPosNorm.x.toString() + ', ' + mPosNorm.y.toString() + ')'
                // _coordTextRef.current.dirty  = true
                setHudLines ( arr => [
                    'Face - / Grid (' + mPosNorm.x.toString() + ',' + mPosNorm.y.toString() + ')', arr[1]
                ])

                //
                // Show grid assist square
                //
                _cursorGridRectRef.current.left = PAD_X + mPosNorm.x*GRID
                _cursorGridRectRef.current.top  = PAD_Y + (SIDE*3 - mPosNorm.y - 1)*GRID
                _cursorGridRectRef.current.visible = true

                //
                // Show face assist square
                //
                _cursorFaceRectRef.current.left = ori.left
                _cursorFaceRectRef.current.top  = ori.top
                _cursorFaceRectRef.current.visible = true
            }
            _cursorGridRectRef.current.dirty = true
            _cursorFaceRectRef.current.dirty = true

            canvi.renderAll();
        }
    }

    useEffect (() => {
        drawAssistObject (_canvasRef.current, MousePositionNorm)
    }, [MousePositionNorm]);

    function drawAssistObjects (canvi, grids) {
        if (_coordTextRef.current) {
            if (grids.length === 0){
                // console.log ('drawAssistObjects() with empty grids')
                _gridAssistRectsGroupRef.current.visible = false
            }
            else {
                // console.log ('drawAssistObjects() with non-empty grids')
                _gridAssistRectsGroupRef.current.visible = true
            }
            _gridAssistRectsGroupRef.current.dirty = true

            canvi.renderAll();
        }
    }

    useEffect (() => {
        drawAssistObjects (_canvasRef.current, selectedGrids)
    }, [selectedGrids])

    function handleMouseMove(ev) {

        // const x = ev.pageX
        // const y = ev.pageY


        var pointer = _canvasRef.current.getPointer(ev);
        var x = pointer.x;
        var y = pointer.y;

        const x_norm = Math.floor( (x - PAD_X) / GRID )
        const y_norm = SIDE*3 - 1 - Math.floor( (y - PAD_Y) / GRID )
        const bool = is_valid_coord (x_norm, y_norm)

        console.log (`mouse moving, bool=${bool}, modalVisibility=${modalVisibility}`)

        if (bool && !modalVisibility) {
            setMousePositionNorm ({
                x: x_norm,
                y: y_norm
            })
        }
        else {
            setMousePositionNorm ({
                x: '-',
                y: '-'
            })
        }
    }

    //
    // Return component
    // Reference:
    // keydown event - https://stackoverflow.com/questions/43503964/onkeydown-event-not-working-on-divs-in-react
    // script focusing div - https://stackoverflow.com/questions/53868070/need-to-put-focus-on-div-in-react
    //

    return(
        <div
            onMouseMove={(ev)=> handleMouseMove(ev)}
            // onClick={(ev)=> handleClick(ev)}
            id="canvas_wrap"
            tabIndex="-1"
        >
            <Modal
                show   = {modalVisibility}
                onHide = {hidePopup}
                info = {modalInfo}
                gridMapping = {gridMapping}
                account = {account}
                in_civ = {accountInCiv}
            />

            <HUD lines={hudLines} />

            <canvas id="c" />
        </div>
    );
}
