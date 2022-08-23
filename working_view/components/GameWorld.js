import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'
import { BigNumber } from 'bignumber.js'

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
    useDeployedNdpes,

    useMacroStates
} from '../lib/api'

import { Modal } from "./Modal"
import HUD from "./HUD"

import {
    useStarknet
} from '@starknet-react/core'
import { DEVICE_TYPE_MAP } from './ConstantDeviceTypes'
import DEVICE_DIM_MAP from './ConstantDeviceDimMap'
import {
    SIDE,
    GRID,
    PAD_X,
    PAD_Y,
    CANVAS_W,
    CANVAS_H,
    TRIANGLE_W,
    TRIANGLE_H,
    GRID_SPACING,
    STROKE_WIDTH_CURSOR_FACE,
    STROKE_WIDTH_GRID_MEDIUM,
    HOVER_DEVICE_STROKE_WIDTH,
    STROKE_WIDTH_AXIS,
    VOLUME,
    ANIM_UPDATE_INTERVAL_MS,
    FILL_CURSOR_SELECTED_GRID,
    GRID_ASSIST_TBOX,
    CANVAS_BG,
    STROKE,
} from "../lib/constants/gameWorld";
import deviceFromGridCoord from '../lib/deviceFromGridCoord'
import drawPendingDevices from "../lib/helpers/drawPendingDevices";
import drawPendingPickups from "../lib/helpers/drawPendingPickups";
import {
    createCursorGridRect, createCursorFaceRect, createCursorHoverDeviceRect
} from './fabricObjects/assists';

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
// const PERLIN_VALUES_FE_RAW = require(`../public/perlin_planet_dim_${SIDE}_element_0.json`);
// const PERLIN_VALUES_AL_RAW = require(`../public/perlin_planet_dim_${SIDE}_element_2.json`);
// const PERLIN_VALUES_CU_RAW = require(`../public/perlin_planet_dim_${SIDE}_element_4.json`);
// const PERLIN_VALUES_SI_RAW = require(`../public/perlin_planet_dim_${SIDE}_element_6.json`);
// const PERLIN_VALUES_PU_RAW = require(`../public/perlin_planet_dim_${SIDE}_element_8.json`);
// const PERLIN_VALUES = {
//     'fe' : PERLIN_VALUES_FE_RAW,
//     'al' : PERLIN_VALUES_AL_RAW,
//     'cu' : PERLIN_VALUES_CU_RAW,
//     'si' : PERLIN_VALUES_SI_RAW,
//     'pu' : PERLIN_VALUES_PU_RAW
// }

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

//
// Helper function to convert api-returned phi value into degree
//
function parse_phi_to_degree (phi)
{
    const phi_bn = new BigNumber(Buffer.from(phi, 'base64').toString('hex'), 16)
    const phi_degree = (phi_bn / 10**20) / (Math.PI * 2) * 360

    return phi_degree
}

//
// Helper function to rotate 2d vector
//
function vec2_rotate_by_degree (vec, ang) {
    ang = -ang * (Math.PI/180);
    var cos = Math.cos(ang);
    var sin = Math.sin(ang);
    return [
        Math.round(10000*(vec[0] * cos - vec[1] * sin))/10000,
        Math.round(10000*(vec[0] * sin + vec[1] * cos))/10000
    ]
}

//
// Helper function to convert solar exposure value to face rect fill color
//
const FILL_MIN = [17, 26, 0]
const FILL_MAX = [50, 77, 0]
function convert_exposure_to_fill (exposure) {

    const exposure_capped = exposure > 20 ? 20 : exposure
    const ratio = exposure_capped / 20

    const R = FILL_MIN[0] + (FILL_MAX[0]-FILL_MIN[0]) * ratio
    const G = FILL_MIN[1] + (FILL_MAX[1]-FILL_MIN[1]) * ratio
    const B = FILL_MIN[2] + (FILL_MAX[2]-FILL_MIN[2]) * ratio

    return (`rgb(${R}, ${G}, ${B})`)
}

export default function GameWorld (props) {

    fabric.perfLimitSizeTotal = 4194304;
    fabric.maxCacheSideLimit = 5000*2;

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
    const { data: db_deployed_ndpes } = useDeployedNdpes ()

    const { data: db_macro_states } = useMacroStates ()

    //
    // React References
    //
    const _canvasRef = useRef();
    const _universeActiveRef = useRef(false);
    const _hasDrawnRef = useRef();
    const _coordTextRef = useRef();
    const _cursorGridRectRef = useRef(createCursorGridRect());
    const _cursorFaceRectRef = useRef(createCursorFaceRect());
    const _cursorHoverDeviceRectRef = useRef(createCursorHoverDeviceRect());
    const modalVisibilityRef = useRef(false)
    const _displayModeRef = useRef('devices')
    const _displayModeTextRef = useRef('');

    const _deviceDisplayRef = useRef();
    const _deviceRectsRef = useRef({});
    const _elementDisplayRef = useRef();
    const _elementDisplayRectsRef = useRef({});
    const _perlinColorsPerElementRef = useRef({});

    const _gridAssistRectsGroupRef = useRef();
    const _gridAssistRectsRef = useRef({});

    const _pendingDevicesRef = useRef([]); // Devices pending deployment
    const _pendingPickupsRef = useRef([]); // Devices pending pickup

    const _mouseStateRef = useRef('up'); // up => down => up
    const _selectStateRef = useRef('idle'); // idle => select => popup => idle
    const _selectedGridsRef = useRef([]);

    const _utxAnimRectsRef = useRef([]); // references to the animation rectangles
    const _utxAnimGridsRef = useRef([]); // references to the animation grids for each rectangle (2d array)
    const _utxAnimGridIndicesRef = useRef([]); // references to the current animation index for each rectangle

    const _gridMapping = useRef({});

    const _panStateRef = useRef({'panning':false, 'last_x':0, 'last_y':0});

    const _currZoom = useRef();

    const _textureRef = useRef({});

    const imageLeftToBeDrawnRef = useRef(6*5);

    //
    // React States
    //
    const [hasLoadedDB, setHasLoadedDB] = useState(false)
    const [universeActive, setUniverseActive] = useState (false)
    const [hasDrawnState, setHasDrawnState] = useState(0)
    const [imageAllDrawnState, setImageAllDrawnState] = useState(false)
    const [ClickPositionNorm, setClickPositionNorm] = useState({left: 0, top: 0})
    const [MousePositionNorm, setMousePositionNorm] = useState({x: 0, y: 0})
    const [modalVisibility, setModalVisibility] = useState(false)
    const [modalInfo, setModalInfo] = useState({})
    const [selectedGrids, setSelectedGrids] = useState([])
    const [gridMapping, setGridMapping] = useState()
    const [accountInCiv, setAccountInCiv] = useState(false)
    const [accountDeviceBalance, setAccountDeviceBalance] = useState({})
    /** Whether your own devices are highlighted, making it easier to tell them apart from other players' */
    const [highlightOwnDevices, setHighlightOwnDevices] = useState(false)

    const [hudLines, setHudLines] = useState([])
    const [hudVisible, setHudVisible] = useState (false)

    const [pendingDevices, _setPendingDevices] = useState([])
    const [pendingPickups, _setPendingPickups] = useState([])

    const setPendingDevices = (setValueFn) => {
        _pendingDevicesRef.current = setValueFn(_pendingDevicesRef.current)
        _setPendingDevices(setValueFn)
    }

    const setPendingPickups = (setValueFn) => {
        _pendingPickupsRef.current = setValueFn(_pendingPickupsRef.current)
        _setPendingPickups(setValueFn)
    }

    // const [hoverTransferDeviceRect, setHoverTransferDeviceRect] = useState(false)

    //
    // useEffect for checking if all database collections are loaded
    //
    useEffect (() => {
        // if (hasLoadedDB) {
        //     return
        // }
        if (!_canvasRef.current) {
            console.log ('canvas not created..')
            return
        }

        if (!db_macro_states || !db_civ_state || !db_player_balances || !db_deployed_devices || !db_utx_sets || !db_deployed_pgs || !db_deployed_harvesters || !db_deployed_transformers || !db_deployed_upsfs || !db_deployed_ndpes) {
            console.log ('db not fully loaded..')
            return
        }
        else {
            // console.log ('db fully loaded!')
            // setHasLoadedDB (true)
            // console.log ('drawWorld()')

            //
            // reset references, states, and fabric canvas
            //
            _currZoom.current = _canvasRef.current.getZoom();
            _canvasRef.current.remove(..._canvasRef.current.getObjects())
            _utxAnimRectsRef.current = []
            _utxAnimGridsRef.current = []
            _utxAnimGridIndicesRef.current = []
            updatePendingDevices(db_deployed_devices)
            updatePendingPickups(db_deployed_devices)

            imageLeftToBeDrawnRef.current = 6*5
            setImageAllDrawnState (false)

            //
            // draw the world
            //
            drawWorldUpToImages (_canvasRef.current)
            setHudVisible (true)
        }
    }, [db_macro_states, db_civ_state, db_player_balances, db_deployed_devices, db_utx_sets, db_deployed_pgs, db_deployed_harvesters, db_deployed_transformers, db_deployed_upsfs, db_deployed_ndpes]);

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

            var entry = player_balances.filter(obj => {
                return obj['account'] === account_intstr
            })
            setAccountDeviceBalance (entry[0])
            console.log ('setAccountDeviceBalance', entry[0])
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
                    'FE raw'      : upsf['resource_0'],
                    'AL raw'      : upsf['resource_2'],
                    'CU raw'      : upsf['resource_4'],
                    'SI raw'      : upsf['resource_6'],
                    'PU raw'      : upsf['resource_8'],
                    'FE refined'  : upsf['resource_1'],
                    'AL refined'  : upsf['resource_3'],
                    'CU refined'  : upsf['resource_5'],
                    'SI refined'  : upsf['resource_7'],
                    'PU enriched' : upsf['resource_9'],
                    'Energy'      : upsf['energy']
                }
            );
        }

        const deployed_ndpe_mapping = new Map();
        for (const ndpe of db_deployed_ndpes.deployed_ndpes) {
            deployed_ndpe_mapping.set(
                ndpe['id'],
                {
                    'energy' : ndpe['energy']
                }
            );
        }

        var base_grid_str_drawn = []
        for (const entry of db_deployed_devices.deployed_devices){
            const x = entry.grid.x
            const y = entry.grid.y
            const typ = parseInt (entry.type)
            const id = entry.id

            const owner_hexstr = toBN(entry.owner).toString(16)
            const owner_hexstr_abbrev = "0x" + owner_hexstr.slice(0,3) + "..." + owner_hexstr.slice(-4)

            const device_dim = DEVICE_DIM_MAP.get (typ)

            var balances
            if ([0,1].includes(typ)) {
                balances = deployed_pg_mapping.get (id)
            }
            else if ([2,3,4,5,6].includes(typ)) {
                balances = deployed_harvester_mapping.get (id)
            }
            else if ([7,8,9,10,11].includes(typ)) {
                balances = deployed_transformer_mapping.get (id)
            }
            else if (typ == 14) {
                balances = deployed_upsf_mapping.get (id)
            }
            else if (typ == 15) {
                balances = deployed_ndpe_mapping.get (id)
            }
            else {
                balances = {}
            }

            var base_grid
            if ('base_grid' in entry) {
                // base_grid is a key => entry is a grid with deployed device of non-utx type
                base_grid = entry.base_grid
                const base_grid_str = `(${base_grid.x},${base_grid.y})`
                if (base_grid_str_drawn.includes(base_grid_str)) {
                    continue
                }
                base_grid_str_drawn.push (base_grid_str)
            }
            else {
                // base_grid not a key => entry is a grid with deployed utx
                base_grid = entry.grid
            }

            for (const i=0; i<device_dim; i++) {
                for (const j=0; j<device_dim; j++) {
                    _gridMapping.current [`(${base_grid.x+i},${base_grid.y+j})`] = {
                        'owner' : owner_hexstr_abbrev,
                        'id' : id,
                        'type' : typ,
                        'balances' : balances
                    }
                }
            }

            // Use device dimension to insert entry into grid mapping (every device is a square)
            // for (const i=0; i<device_dim; i++) {
            //     for (const j=0; j<device_dim; j++) {
            //         _gridMapping.current [`(${x+i},${y+j})`] = {
            //             'owner' : owner_hexstr_abbrev,
            //             'type' : typ,
            //             'balances' : balances
            //         }
            //     }
            // }

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
        if (!_universeActiveRef.current) {
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
        if (!_universeActiveRef.current) {
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
        if (!_universeActiveRef.current) {
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
                'mode' : 'grids',
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

    function resetZoom () {
        _canvasRef.current.setZoom(1)  // reset zoom so pan actions work as expected
        _canvasRef.current.absolutePan({
            x: 0,
            y: 0
        });
        _canvasRef.current.requestRenderAll ()
    }


    function handleElementDisplayVisibility (visible, element) {
        console.log (`handleElementDisplayVisibility element=${element}`)

        for (var e of [0,2,4,6,8]) {
            if (e == element) {
                for (var face of [0,1,2,3,4,5]) {
                    _textureRef.current[e][face].visible = visible
                    _textureRef.current[e][face].dirty = true
                }
            }
            else {
                for (var face of [0,1,2,3,4,5]) {
                    _textureRef.current[e][face].visible = false
                    _textureRef.current[e][face].dirty = true
                }
            }
        }

        // for (var face=0; face<6; face++) {

        //     for (var row=0; row<SIDE; row++) {
        //         for (var col=0; col<SIDE; col++) {
        //             const idx = `(${face},${row},${col})`
        //             const fill = !visible ? '#000000' : _perlinColorsPerElementRef.current [element][idx]
        //             _elementDisplayRectsRef.current [idx].fill = fill
        //             _elementDisplayRectsRef.current [idx].visible = visible
        //             _elementDisplayRectsRef.current [idx].dirty = true

        //             if ( row==10 && col==10 && face==1 ) {
        //                 console.log (`fill at row=10, col=10, face=1: ${fill}`)
        //             }
        //         }
        //     }
        // }
    }

    //
    // Handle key down events
    // ref: https://stackoverflow.com/questions/37440408/how-to-detect-esc-key-press-in-react-and-how-to-handle-it
    //
    const handleKeyDown = useCallback((ev) => {

        if (!_hasDrawnRef.current) {
            return
        }
        if (!_universeActiveRef.current) {
            return
        }

        if (modalVisibilityRef.current) {
            // if modal is up, only handle ESC key
            if (ev.key === "Escape") {
                hidePopup ()
            }
            return
        }

        if (ev.key === 'c') {
            resetZoom ()
        }

        if(ev.key === '1'){
            console.log('1')
            _displayModeRef.current = 'devices'

            change_working_view_visibility (true)
            handleElementDisplayVisibility (false, '')

            setHudLines ( arr => [
                arr[0], `Display: devices`
            ])
        }
        else if(ev.key === '2'){
            console.log('2')
            _displayModeRef.current = 'fe'

            change_working_view_visibility (false)
            handleElementDisplayVisibility (true, 0) // raw fe

            setHudLines ( arr => [
                arr[0], `Display: Raw Fe distribution`
            ])
        }
        else if(ev.key === '3'){
            console.log('3')
            _displayModeRef.current = 'al'

            change_working_view_visibility (false)
            handleElementDisplayVisibility (true, 2) // raw al

            setHudLines ( arr => [
                arr[0], `Display: Raw Al distribution`
            ])
        }
        else if(ev.key === '4'){
            console.log('4')
            _displayModeRef.current = 'cu'

            change_working_view_visibility (false)
            handleElementDisplayVisibility (true, 4) // raw cu

            setHudLines ( arr => [
                arr[0], `Display: Raw Cu distribution`
            ])
        }
        else if(ev.key === '5'){
            console.log('5')
            _displayModeRef.current = 'si'

            change_working_view_visibility (false)
            handleElementDisplayVisibility (true, 6) // raw si

            setHudLines ( arr => [
                arr[0], `Display: Raw Si distribution`
            ])
        }
        else if(ev.key === '6'){
            console.log('6')
            _displayModeRef.current = 'pu'

            change_working_view_visibility (false)
            handleElementDisplayVisibility (true, 8) // raw pu

            setHudLines ( arr => [
                arr[0], `Display: Raw Pu distribution`
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
                'mode' : 'transfer',
                'grids' : null
            }
            setModalInfo (info)
        }

        else if (ev.key === 'q') {
            setHighlightOwnDevices (true);
        }

        else if (ev.key === 'i') {
            setModalVisibility (true)
            modalVisibilityRef.current = true
            _selectStateRef.current = 'popup'
            const info = {
                'mode' : 'inventory',
                'grids' : null
            }
            setModalInfo (info)
        }

      }, [modalVisibility]);

    const handleKeyUp = useCallback((ev) => {
        if (ev.key === "q") {
            setHighlightOwnDevices(false);
        }
    }, []);

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
        hoverCursor: 'default',
        fontFamily: "Poppins-Light"
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

            const MIN_ZOOM = 0.6
            const MAX_ZOOM = 15

            const delta = opt.e.deltaY;

            const curr_zoom = _canvasRef.current.getZoom();
            var new_zoom = curr_zoom * (0.99 ** delta);

            if (new_zoom > MAX_ZOOM) new_zoom = MAX_ZOOM;
            else if (new_zoom < MIN_ZOOM) new_zoom = MIN_ZOOM;

            _canvasRef.current.zoomToPoint({ x: opt.e.offsetX, y: opt.e.offsetY }, new_zoom);
            opt.e.preventDefault();
            opt.e.stopPropagation();

        })

        // _canvasRef.current.on('object:over', function(evt) {
        //     console.log ('object over')
        //     var object = evt.target
        //     if (isaac_class in object) {
        //         console.log ('object:over a device!')
        //     }
        // })
        // _canvasRef.current.on('object:out', function(evt) {
        //     var object = evt.target
        //     if (isaac_class in object) {
        //         console.log ('object:out a device!')
        //     }
        // })

        _hasDrawnRef.current = false

        document.addEventListener("keydown", handleKeyDown, false);
        document.addEventListener("keyup", handleKeyUp, false);
        return () => {

            // Remove canvas elements
            _canvasRef.current.dispose()

            document.removeEventListener("keydown", handleKeyDown, false);
            document.removeEventListener("keyup", handleKeyUp, false);
        };

    }, []);

    // useEffect (() => {
    //     if (!_hasDrawnRef.current) {
    //         drawWorld (_canvasRef.current)
    //         setHudVisible (true)
    //     }
    // }, [hasLoadedDB]);

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

        // canvi.requestRenderAll();
    }

    const drawWorldUpToImages = canvi => {

        // if (hasLoadedDB) {

        if (db_macro_states.macro_states.length == 0) {
            console.log ("This universe is not active.")
            _universeActiveRef.current = false
            setUniverseActive (false)
            drawIdleMessage (canvi)
            return
        }
        else {
            prepare_grid_mapping ()
            drawLandscape (canvi)
            drawDevices (canvi)
            drawUtxAnim (canvi)
            setHudLines ([
                'Face - / Grid (-,-)',
                'Display: devices'
            ])
            drawPendingDevices({ current: canvi }, _pendingDevicesRef)
            drawPendingPickups({ current: canvi }, _pendingPickupsRef, _deviceRectsRef)

            drawPerlinImage (canvi)

            // _hasDrawnRef.current = true
            // setHasDrawnState (1)
            // _universeActiveRef.current = true;
            // setUniverseActive (true)

            // document.getElementById('canvas_wrap').focus();
        }
        // }
    }
    useEffect(() => { // the second part of drawWorld - after all images are loaded and drawn, to ensure draw order (z-index)
        if (!imageAllDrawnState) return;

        const canvi = _canvasRef.current

        initializeGridAssistRectsRef (canvi)
        drawAssist (canvi)

        _hasDrawnRef.current = true
        setHasDrawnState (1)
        _universeActiveRef.current = true;
        setUniverseActive (true)

        document.getElementById('canvas_wrap').focus();

        canvi.requestRenderAll()

    }, [imageAllDrawnState])


    const drawIdleMessage = canvi => {
        const TBOX_FONT_FAMILY = 'Poppins-Light'

        const tbox_idle_message = new fabric.Textbox(
            'This universe is not active.', {
                width: 300,
                top:  CANVAS_H/2 - 100,
                left: CANVAS_W/2 - 100,
                fontSize: 17,
                textAlign: 'left',
                fill: "#CCCCCC",
                selectable: false,
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
            // If not tethered, don't create animation
            //
            if (utx_set.tethered == 0) {
                continue;
            }

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
                opacity: 0.2,
                selectable: false,
                hoverCursor: 'default',
                strokeWidth: 0
            });
            _utxAnimRectsRef.current.push (rect)

            //
            // For each utx set, set the grids along its animation path, with first grid as redundant for full transparent rect (enable flashing effect for single-utx)
            // set animation index to 0
            //
            const grids = [ utx_set.grids[0] ].concat (utx_set.grids)
            _utxAnimGridsRef.current.push (grids)
            _utxAnimGridIndicesRef.current.push (0)

            canvi.add (rect)
        }
    }
    // reference: https://stackoverflow.com/questions/57137094/implementing-a-countdown-timer-in-react-with-hooks
    useEffect(() => {

        if (!db_utx_sets) return;
        if (hasDrawnState === 0) return;
        if (_canvasRef === null) return;

        var n_utx_set = 0
        for (const utx_set of db_utx_sets.utx_sets) {
            if (utx_set.tethered == 1) {
                n_utx_set += 1
            }
        }

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

                //
                // animate opacity - make transparent at i=0
                //
                if (anim_idx==0) {
                    _utxAnimRectsRef.current[i].opacity = 0
                }
                else {
                    _utxAnimRectsRef.current[i].opacity = 0.2
                }

                // console.log (`ANIMATE: new grid (${x}, ${y})`)
            }
            _canvasRef.current.requestRenderAll ();

        }, ANIM_UPDATE_INTERVAL_MS);

        return () => clearInterval(interval);
    }, [hasDrawnState, db_utx_sets]);


    const drawLandscape = canvi => {
        const TBOX_FONT_FAMILY = "Poppins-Light"
        const TBOX_FONT_SIZE = 14

        //
        // Axes for coordinate system
        //
        const DRAW_AXIS = false
        const AXIS_EXTEND_GRID_MULTIPLE_X = 7
        const AXIS_EXTEND_GRID_MULTIPLE_Y = 6
        if (DRAW_AXIS) {
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
        }

        //
        // Axis ticks and labels
        //
        const DRAW_AXIS_TICKS_AND_LABELS = false
        if (DRAW_AXIS_TICKS_AND_LABELS) {
            const tbox_x = new fabric.Textbox(
                'x', {
                    width: 100,
                    left: PAD_X + SIDE*GRID*4 + GRID*AXIS_EXTEND_GRID_MULTIPLE_X + GRID*3.5,
                    top:  PAD_Y + SIDE*GRID*2.9 + 2.3*GRID,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false,
                    hoverCursor: 'default'
                });
            const tbox_y = new fabric.Textbox(
                'y', {
                    width: 100,
                    left: PAD_X - 0.4*GRID,
                    top:  PAD_Y - 13*GRID,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false,
                    hoverCursor: 'default'
                });

            const tbox_origin = new fabric.Textbox(
                '(0,0)', {
                    width: 100,
                    left: PAD_X + 0 - GRID*2,
                    top:  PAD_Y + SIDE*GRID*3 + GRID*1.3,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false,
                    hoverCursor: 'default'
                });

            const text_y_d = '(0,' + SIDE.toString() + ')'
            const tbox_y_d = new fabric.Textbox(
                text_y_d, {
                    width: 100,
                    left: PAD_X + 0 - GRID*9,
                    top:  PAD_Y + SIDE*GRID*2 - GRID*1.5,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false,
                    hoverCursor: 'default'
                });

            const text_y_2d = '(0,' + (2*SIDE).toString() + ')'
            const tbox_y_2d = new fabric.Textbox(
                text_y_2d, {
                    width: 100,
                    left: PAD_X + 0 - GRID*9,
                    top:  PAD_Y + SIDE*GRID*1 - GRID*1.5,
                    fontSize: TBOX_FONT_SIZE,
                    textAlign: 'left',
                    fill: STROKE,
                    fontFamily: TBOX_FONT_FAMILY,
                    selectable: false,
                    hoverCursor: 'default'
                });

            const text_y_3d = '(0,' + (3*SIDE).toString() + ')'
            const tbox_y_3d = new fabric.Textbox(
                text_y_3d, {
                    width: 100,
                    left: PAD_X + 0 - GRID*9.5,
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
        // Draw face rectangles
        //
        const DRAW_FACE_RECTS = true
        if (DRAW_FACE_RECTS) {

            if (!db_macro_states.macro_states[0]) {return;}

            //
            // Compute colors for each face according to (1) face number (2) distance to each suns (3) planet rotation
            // following the exact way solar exposure is computed in smart contract.
            //

            // Compute distances and vectors
            const sun0_q = db_macro_states.macro_states[0].dynamics.sun0.q
            const sun1_q = db_macro_states.macro_states[0].dynamics.sun1.q
            const sun2_q = db_macro_states.macro_states[0].dynamics.sun2.q
            const plnt_q = db_macro_states.macro_states[0].dynamics.planet.q
            const phi_degree = parse_phi_to_degree (db_macro_states.macro_states[0].phi)
            const dist_sqs = {
                0 : (sun0_q.x - plnt_q.x)**2 + (sun0_q.y - plnt_q.y)**2,
                1 : (sun1_q.x - plnt_q.x)**2 + (sun1_q.y - plnt_q.y)**2,
                2 : (sun2_q.x - plnt_q.x)**2 + (sun2_q.y - plnt_q.y)**2
            }
            const vec_suns = {
                0 : [sun0_q.x - plnt_q.x, sun0_q.y - plnt_q.y],
                1 : [sun1_q.x - plnt_q.x, sun1_q.y - plnt_q.y],
                2 : [sun2_q.x - plnt_q.x, sun1_q.y - plnt_q.y]
            }

            const normal_0 = vec2_rotate_by_degree ([1,0], -phi_degree)
            const normal_2 = vec2_rotate_by_degree (normal_0, -90)
            const normal_4 = vec2_rotate_by_degree (normal_0, -180)
            const normal_5 = vec2_rotate_by_degree (normal_0, -270)
            const normals = {
                0 : normal_0,
                2 : normal_2,
                4 : normal_4,
                5 : normal_5
            }
            // console.log ('normals', normals)

            // Compute radiation levels for top & bottom faces
            const BASE_RADIATION = 75 // from contract
            const OBLIQUE_RADIATION =  15 // from contract
            const face_1_exposure = (OBLIQUE_RADIATION / dist_sqs[0]) + (OBLIQUE_RADIATION / dist_sqs[1]) + (OBLIQUE_RADIATION / dist_sqs[2])
            const face_3_exposure = face_1_exposure

            // Compute radiation levels for side faces; compute fill color; draw rect
            for (const face of [0, 2, 4, 5]) {

                var exposure = 0
                for (const sun of [0,1,2]) {
                    const dot = vec_suns[sun][0] * normals[face][0] + vec_suns[sun][1] * normals[face][1]
                    if (dot <= 0) { exposure += 0 }
                    else {
                        const mag_normal = Math.sqrt ( normals[face][0]**2 + normals[face][1]**2 )
                        const mag_vec_sun = Math.sqrt ( vec_suns[sun][0]**2 + vec_suns[sun][1]**2 )
                        const cos = dot / (mag_normal * mag_vec_sun)
                        exposure += BASE_RADIATION * cos / dist_sqs[sun]
                    }
                }
                // const exposure_sides[face] = exposure

                const face_fill = convert_exposure_to_fill (exposure)

                const ori = map_face_to_left_top (face)

                const rect = new fabric.Rect({
                    height: GRID*SIDE,
                    width: GRID*SIDE,
                    left: ori.left,
                    top: ori.top,
                    fill: face_fill,
                    selectable: false,
                    hoverCursor: 'default',
                    visible: true,
                    strokeWidth: 0,
                    objectCaching: true
                });
                canvi.add (rect)
            }


            // face 1
            const face_nonside_fill = convert_exposure_to_fill (face_1_exposure)
            const ori_1 = map_face_to_left_top (1)
            const rect_1 = new fabric.Rect({
                height: GRID*SIDE,
                width: GRID*SIDE,
                left: ori_1.left,
                top: ori_1.top,
                fill: face_nonside_fill,
                selectable: false,
                hoverCursor: 'default',
                visible: true,
                strokeWidth: 0,
                objectCaching: true
            });
            canvi.add (rect_1)
            const ori_3 = map_face_to_left_top (3)
            const rect_3 = new fabric.Rect({
                height: GRID*SIDE,
                width: GRID*SIDE,
                left: ori_3.left,
                top: ori_3.top,
                fill: face_nonside_fill,
                selectable: false,
                hoverCursor: 'default',
                visible: true,
                strokeWidth: 0,
                objectCaching: true
            });
            canvi.add (rect_3)

        }

         //
        // Grid lines
        //
        const DRAW_GRID_LINES = true
        if (DRAW_GRID_LINES) {
            //
            // Grid lines parallel to Y-axis
            //
            for (var xi = 0; xi < SIDE; xi += GRID_SPACING){
                canvi.add(new fabric.Line([
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID,
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID*2
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID_MEDIUM, selectable: false, hoverCursor: 'default' }));
            }
            for (var xi = SIDE; xi <= SIDE*2; xi += GRID_SPACING){
                canvi.add(new fabric.Line([
                    PAD_X + xi*GRID,
                    PAD_Y + 0,
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID*3
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID_MEDIUM, selectable: false, hoverCursor: 'default' }));
            }
            for (var xi = 2*SIDE+GRID_SPACING; xi <= SIDE*4; xi += GRID_SPACING){
                canvi.add(new fabric.Line([
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID,
                    PAD_X + xi*GRID,
                    PAD_Y + SIDE*GRID*2
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID_MEDIUM, selectable: false, hoverCursor: 'default' }));
            }

            //
            // Grid lines parallel to X-axis
            //
            for (var yi = 0; yi < SIDE; yi += GRID_SPACING){
                canvi.add(new fabric.Line([
                    PAD_X + SIDE*GRID,
                    PAD_Y + yi*GRID,
                    PAD_X + SIDE*GRID*2,
                    PAD_Y + yi*GRID
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID_MEDIUM, selectable: false, hoverCursor: 'default' }));
            }
            for (var yi = SIDE; yi < 2*SIDE+1; yi += GRID_SPACING){
                canvi.add(new fabric.Line([
                    PAD_X + 0,
                    PAD_Y + yi*GRID,
                    PAD_X + SIDE*GRID*4,
                    PAD_Y + yi*GRID
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID_MEDIUM, selectable: false, hoverCursor: 'default' }));
            }
            for (var yi = 2*SIDE+GRID_SPACING; yi <= 3*SIDE; yi += GRID_SPACING){
                canvi.add(new fabric.Line([
                    PAD_X + SIDE*GRID,
                    PAD_Y + yi*GRID,
                    PAD_X + SIDE*GRID*2,
                    PAD_Y + yi*GRID
                ], { stroke: STROKE, strokeWidth: STROKE_WIDTH_GRID_MEDIUM, selectable: false, hoverCursor: 'default' }));
            }
        }

    }

    const drawMode = canvi => {
        canvi.add (displayModeText)
        _displayModeTextRef.current = displayModeText

        // canvi.requestRenderAll();
    }

    // const updateMode = (canvi, mode) => {
    //     console.log ('updateMode()')
    //     _displayModeTextRef.current.text = 'Display: ' + mode
    //     _displayModeTextRef.current.dirty = true

    //     canvi.requestRenderAll();
    // }

    const drawAssist = canvi => {
        //
        // Draw textObject for showing user mouse coordinate
        //
        // canvi.add(coordText)
        // _coordTextRef.current = coordText

        canvi.add (_cursorGridRectRef.current)
        canvi.add (_cursorFaceRectRef.current)
        canvi.add (_cursorHoverDeviceRectRef.current)

        canvi.requestRenderAll();
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

    const drawPerlinImage = canvi => {

        for (var element of [0,2,4,6,8]) {

            var collection = {}
            for (var face of [0,1,2,3,4,5]) {

                const face_ori = find_face_ori (face)
                const left = PAD_X + face_ori[0] * GRID
                const top = PAD_Y + (SIDE*3 - face_ori[1] - SIDE) * GRID

                fabric.Image.fromURL(
                    `texture_element${element}_face${face}.png`,

                    function (myImg) { // callback function once image is loaded
                        var img = myImg.set({
                            left: left,
                            top: top,
                            cropX: 0,
                            cropY: 0,
                            visible: false
                        });
                        img.scaleToHeight (SIDE*GRID)
                        img.scaleToWidth (SIDE*GRID)
                        canvi.add(img)
                        collection[face] = img

                        imageLeftToBeDrawnRef.current -= 1

                        if (imageLeftToBeDrawnRef.current == 0) {
                            setImageAllDrawnState (true)
                        }
                });
            }

            _textureRef.current[element] = collection
        }

    }

    // PERLIN_VALUES
    const drawPerlin = canvi => {

        //
        // build colors
        //
        var perlin_colors_per_element = {}
        for (const element of ['fe','al','cu','si','pu']){

            var perlin_colors = {}
            const perlin_values = PERLIN_VALUES[element]
            // console.log (`${element} / max perline value: ${perlin_values['max']}`)
            // console.log (`${element} / min perline value: ${perlin_values['min']}`)

            for (var face=0; face<6; face++) {

                for (var row=0; row<SIDE; row++) {
                    for (var col=0; col<SIDE; col++) {

                        const perlin_value = perlin_values[face][row][col]
                        const perlin_value_normalized = (perlin_value - perlin_values['min']) / (perlin_values['max'] - perlin_values['min'])

                        const hi = PERLIN_COLOR_MAP[element]['hi']
                        const lo = PERLIN_COLOR_MAP[element]['lo']
                        const r = lerp (lo[0], hi[0], perlin_value_normalized)
                        const g = lerp (lo[1], hi[1], perlin_value_normalized)
                        const b = lerp (lo[2], hi[2], perlin_value_normalized)
                        const rect_color = `rgb(${r}, ${g}, ${b})`

                        perlin_colors [`(${face},${row},${col})`] = rect_color
                    }
                }
            }
            perlin_colors_per_element [element] = perlin_colors
        }
        _perlinColorsPerElementRef.current = perlin_colors_per_element

        //
        // build rects
        //
        const perlin_rects = []
        const perlin_rects_dict = {}
        for (var face=0; face<6; face++) {

            const face_ori = find_face_ori (face)

            for (var row=0; row<SIDE; row++) {

                for (var col=0; col<SIDE; col++) {

                    var rect = new fabric.Rect({
                        height: GRID,
                        width: GRID,
                        left: PAD_X + (col + face_ori[0]) * GRID,
                        top: PAD_Y + (SIDE*3 - (row + face_ori[1]) - 1) * GRID,
                        fill: '#FFFFFF',
                        selectable: false,
                        hoverCursor: 'default',
                        visible: false,
                        strokeWidth: 0,

                        objectCaching: true
                    });
                    perlin_rects.push (rect)
                    perlin_rects_dict [`(${face},${row},${col})`] = rect
                    canvi.add (rect) // if we need per-rect control we need to add each rect to the canvas
                }
            }
        }
        _elementDisplayRectsRef.current = perlin_rects_dict

        // // TODO: may be able to fix text blurring at high zoom by messing with cache
        // // see: http://fabricjs.com/fabric-object-caching
        // var perlin_rects_group = new fabric.Group(
        //     perlin_rects, {
        //         visible: false,
        //         selectable: false,
        //         // objectCaching: false
        //     });
        // canvi.add(perlin_rects_group)
        // _elementDisplayRef.current = perlin_rects_group

        // canvi.requestRenderAll();
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
        var base_grid_str_drawn = []
        _deviceRectsRef.current = {}
        for (const entry of db_deployed_devices.deployed_devices){

            const typ = parseInt (entry.type)

            var base_grid
            if ('base_grid' in entry) {
                base_grid = entry.base_grid
                const base_grid_str = `(${base_grid.x},${base_grid.y})`
                if (base_grid_str_drawn.includes(base_grid_str)) {
                    continue
                }
                base_grid_str_drawn.push (base_grid_str)
                // console.log (`typ ${typ}, base_grid_str ${base_grid_str}`)
            }
            else { // base_grid not a key => entry is a grid with deployed utx
                base_grid = entry.grid
            }

            const device_dim = DEVICE_DIM_MAP.get(typ)
            const device_color = DEVICE_COLOR_MAP.get(typ)

            const rect = new fabric.Rect({
                height: device_dim*GRID,
                width: device_dim*GRID,
                left: PAD_X + base_grid.x*GRID,
                top:  PAD_Y + (SIDE*3-base_grid.y-device_dim)*GRID,
                fill: device_color,
                selectable: false,
                hoverCursor: 'pointer',
                strokeWidth: 0,
                stroke: device_color,
                isaac_class: 'device'
            });
            if ('base_grid' in entry) {
                _deviceRectsRef.current[entry.id] = rect
            } else {
                // Add utx rects as array items to the same id
                _deviceRectsRef.current[entry.id] = _deviceRectsRef.current[entry.id] ? [..._deviceRectsRef.current[entry.id], rect] : [rect]
            }
            device_rects.push (rect)
            canvi.add (rect)
            // console.log (`>> Drawing device typ=${typ}, dim=${device_dim}, grid=(${x},${y})`)
        }

        var device_rect_face0_group = new fabric.Group(
            device_rects, {
                visible: true,
                selectable: false,
                hoverCursor: 'default'
            });
        canvi.add(device_rect_face0_group)
        _deviceDisplayRef.current = device_rect_face0_group

        // canvi.requestRenderAll();
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
                left : x_transform_normalized_to_canvas (3*SIDE),
                top  : y_transform_normalized_to_canvas (2*SIDE-1)
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

    useEffect(() => {
        drawPendingDevices(_canvasRef, _pendingDevicesRef)
    }, [pendingDevices])

    useEffect(() => {
        drawPendingPickups(_canvasRef, _pendingPickupsRef, _deviceRectsRef)
    }, [pendingPickups])

    function drawAssistObject (canvi, mPosNorm) {

        if (mPosNorm.x.toString() === '-' || !gridMapping) {
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

            // Hide hover device selection
            _cursorHoverDeviceRectRef.current.visible = false
        }
        else {
            const face = find_face_given_grid (mPosNorm.x, mPosNorm.y)
            const ori  = map_face_to_left_top (face)
            const gridData = gridMapping[`(${mPosNorm.x},${mPosNorm.y})`]

            // Grid data mapped to lines for HUD
            const gridDataLines = gridData
                ? [
                    DEVICE_TYPE_MAP[gridData.type],
                    _pendingPickupsRef.current && _pendingPickupsRef.current.find(({id}) => id === gridData.id) ? 'Pending pick-up' : null,
                    ...Object.keys(gridData.balances)
                    .map(
                        (key) =>
                        gridData.balances[key] &&
                        key + ': ' + gridData.balances[key]
                    ),
                ].filter((x) => x)
                : []

            //
            // Show face & coordinate textbox
            // Along with info about the device
            //
            // _coordTextRef.current.text = 'Face ' + face.toString() + ' / Grid (' + mPosNorm.x.toString() + ', ' + mPosNorm.y.toString() + ')'
            // _coordTextRef.current.dirty  = true
            setHudLines((arr) => [
                `Face ${face} / Grid (${mPosNorm.x}, ${mPosNorm.y})`,
                arr[1],
                ...gridDataLines,
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
            _cursorFaceRectRef.current.left = ori.left - STROKE_WIDTH_CURSOR_FACE/2
            _cursorFaceRectRef.current.top  = ori.top - STROKE_WIDTH_CURSOR_FACE/2
            _cursorFaceRectRef.current.visible = true
            // console.log (`draw face assist square, face: ${face}`)

            // Show device hover selection
            const device = deviceFromGridCoord (mPosNorm.x, mPosNorm.y, db_deployed_devices.deployed_devices)
            if (device) {
                _cursorHoverDeviceRectRef.current.left    = PAD_X + device.device.base_grid.x * GRID - HOVER_DEVICE_STROKE_WIDTH
                _cursorHoverDeviceRectRef.current.top     = PAD_Y + (SIDE * 3 - (device.device.base_grid.y + device.dimension)) * GRID - HOVER_DEVICE_STROKE_WIDTH
                _cursorHoverDeviceRectRef.current.width   = GRID * device.dimension + HOVER_DEVICE_STROKE_WIDTH
                _cursorHoverDeviceRectRef.current.height  = GRID * device.dimension + HOVER_DEVICE_STROKE_WIDTH
                _cursorHoverDeviceRectRef.current.visible = true
            } else {
                _cursorHoverDeviceRectRef.current.visible = false
            }
        }
        _cursorGridRectRef.current.dirty        = true
        _cursorFaceRectRef.current.dirty        = true
        _cursorHoverDeviceRectRef.current.dirty = true

        canvi.requestRenderAll();
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

            canvi.requestRenderAll();
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

    function handleDeployStarted ({x, y, utxGrids, typ, txid}) {
        console.log(`handleDeployStarted() x: ${x}, y: ${y}, typ: ${typ}, txid: ${txid}`)
        const device = {
            x, y, type: typ,
            utxGrids,
            dimension: DEVICE_DIM_MAP.get(typ),
            color: DEVICE_COLOR_MAP.get(typ),
            rectRef: React.createRef(),
            txid
        }
        // Add the device to the list of pending devices
        setPendingDevices ((pendingDevices) => {
            if (pendingDevices.find(d => d.txid === txid)) {
                console.warn('Cannot add device with the same txid')
                return pendingDevices
            }
            return [...pendingDevices, device]
        })
    }

    function updatePendingDevices (db_deployed_devices) {
        setPendingDevices((prev) => {
            // Only keep pending devices that are not deployed
            return prev.filter((d) =>
                !db_deployed_devices.deployed_devices.find(
                    (dd) => parseInt(dd.type) === d.type && dd.grid.x === d.x && dd.grid.y === d.y
                )
            )
        })
    }

    function handlePendingPickup({id, txid}) {
        console.log(`handlePendingPickup() id: ${id}, txid: ${txid}`)

        // Add the device to the list of pending pickups
        setPendingPickups ((prev) => {
            if (prev.find(d => d.txid === txid)) {
                console.log('Cannot pickup device with the same txid')
                return prev;
            }
            return [
                ...prev,
                {
                    id,
                    txid,
                }
            ]
        })
    }

    function updatePendingPickups (db_deployed_devices) {
        // Clear the rect refs for the pending pickups so they can be redrawn again
        _pendingPickupsRef.current.forEach((p) => {
            p.rect = null
        });
        setPendingPickups((prev) => {
            // Only keep pending pickups that still deployed
            return prev.filter((d) =>
                db_deployed_devices.deployed_devices.find(
                    (dd) => d.id === dd.id
                )
            )
        })
    }

    // Set the display style of the player's own devices (based on highlight mode)
    useEffect(() => {
        if (!db_deployed_devices || !account || !_deviceDisplayRef.current) return;

        const accountHexStr = toBN(account).toString(16);

        Object.keys(_deviceRectsRef.current).forEach((id) => {
            let rects = _deviceRectsRef.current[id];
            if (!Array.isArray(rects)) {
                rects = [rects];
            }
            if (highlightOwnDevices) {
                const deviceData = db_deployed_devices.deployed_devices.find(
                    (d) => d.id === id
                );
                const ownerHexStr = toBN(deviceData.owner).toString(16);
                if (ownerHexStr !== accountHexStr) {
                    rects.forEach((rect) => {
                        rect.opacity = 0.1;
                        rect.dirty = true;
                    });
                    // TODO: set the UTX animation opacity as well
                }
            } else {
                // Reset opacity to 1 for all devices
                rects.forEach((rect) => {
                    rect.opacity = 1;
                    rect.dirty = true;
                });
            }
        });

        // Set the group dirty flag so it can redraw after we change the invidual rects
        _deviceDisplayRef.current.dirty = true;

        _canvasRef.current.requestRenderAll();
    }, [highlightOwnDevices, db_deployed_devices, account]);

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
                device_balance = {accountDeviceBalance}
                pendingPickups = {pendingPickups}
                onDeployStarted = {handleDeployStarted}
                onPendingPickup = {handlePendingPickup}
            />

            <HUD lines={hudLines} universeActive={universeActive}/>

            <canvas id="c" />
        </div>
    );
}
