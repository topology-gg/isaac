import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import { DEVICE_COLOR_MAP } from './ConstantDeviceColors'

// import sound_open from '../public/sound-open.ogg'
// import sound_close from '../public/sound-close.ogg';

import {
    useCivState,
    useFungiblePlayerBalances,
    useDeployedDevices,
    useUtxSets,

    usePgs,
    useHarvesters,
    useTransformers,
    useUpsfs,
    useNdpes,

    useMacroStates,
    usePlayerFungibleBalances,
    usePlayerNonfungibleDevices
} from '../lib/api'

import { Modal } from "./Modal"
import HUD from "./HUD"
import HUDLeft from "./HUDLeft"

import {
    useStarknet, useStarknetInvoke
} from '@starknet-react/core'
import { useUniverseContract } from './UniverseContract'
import { DEVICE_TYPE_FULL_NAME_MAP } from './ConstantDeviceTypes'
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
    DEVICE_STROKE_WIDTH,
    STROKE_WIDTH_CURSOR_FACE,
    STROKE_WIDTH_GRID_MEDIUM,
    HOVER_DEVICE_STROKE_WIDTH,
    STROKE_WIDTH_AXIS,
    VOLUME,
    FILL_CURSOR_SELECTED_GRID,
    GRID_ASSIST_TBOX,
    CANVAS_BG,
    STROKE,
} from "../lib/constants/gameWorld";
import deviceFromGridCoord from '../lib/deviceFromGridCoord'
import drawPendingDevices from "../lib/helpers/drawPendingDevices";
import drawPendingPickups from "../lib/helpers/drawPendingPickups";
import {
    createCursorGridRect, createCursorFaceRect, createCursorHoverDeviceRect, createPlacementAssistRect
} from './fabricObjects/assists';
import createTriangle from "./fabricObjects/createTriangle";
import convert_exposure_to_fill from "../lib/helpers/convertExposureToFill";
import find_face_ori from "../lib/helpers/findFaceOri";
import find_face_given_grid from "../lib/helpers/findFaceGivenGrid";
import is_valid_coord from "../lib/helpers/isValidCoord";
import map_face_to_left_top from "../lib/helpers/mapFaceToLeftTop";
import { convert_screen_to_grid_x, convert_screen_to_grid_y } from "../lib/helpers/convertScreenToGrid"
import gridMappingFromData from "../lib/helpers/gridMappingFromData"
import getWindowDimensions from "../lib/helpers/getWindowDimensions"
import utxFromSelectedGrids from "../lib/helpers/utxFromSelectedGrids"
import faceRadiationFromMacro from "../lib/helpers/faceRadiationFromMacro"

import useUtxAnimation from "../lib/hooks/useUtxAnimation"
import useDebouncedEffect from "../lib/hooks/useDebouncedEffect"
import usePlacementAssist from "../lib/hooks/usePlacementAssist"
import useSelectedGrids from "../lib/hooks/useSelectedGrids"
import FloatingMessage from "./FloatingMessage"

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

export default function GameWorld(props) {

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
    const { data: db_player_fungible_balances } = usePlayerFungibleBalances ()
    const { data: db_deployed_devices } = useDeployedDevices ()
    const { data: db_utx_sets } = useUtxSets ()
    const { data: db_pgs } = usePgs ()
    const { data: db_harvesters } = useHarvesters ()
    const { data: db_transformers } = useTransformers ()
    const { data: db_upsfs } = useUpsfs ()
    const { data: db_ndpes } = useNdpes ()
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
    const _deviceBeingPlacedRef = useRef(null); // Device being placed by user

    const _mouseStateRef = useRef('up'); // up => down => up

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
    const [gridMapping, setGridMapping] = useState()
    const [accountInCiv, setAccountInCiv] = useState(false)
    const [accountDeviceBalance, setAccountDeviceBalance] = useState({})
    /** Whether your own devices are highlighted, making it easier to tell them apart from other players' */
    const [highlightOwnDevices, setHighlightOwnDevices] = useState(false)

    const [hudLines, setHudLines] = useState([])
    const [hudVisible, setHudVisible] = useState (false)

    const [pendingDevices, _setPendingDevices] = useState([])
    const [pendingPickups, _setPendingPickups] = useState([])
    const [deviceBeingPlaced, _setDeviceBeingPlaced] = useState(null)

    // Whether the player is choosing where to deploy UTX, and which type it is (number)
    const _deployingUtxRef = useRef()
    const [deployingUtx, _setDeployingUtx] = useState(null)
    const setDeployingUtx = (setValueFn) => {
        _deployingUtxRef.current = setValueFn(_deployingUtxRef.current)
        _setDeployingUtx(setValueFn)
    }

    // const [debugCounter, setDebugCounter] = useState(0)

    const {
        draw: drawUtxAnim,
        reset: resetUtxAnim,
        toggleVisible: toggleUtxAnimationVisible
    } = useUtxAnimation(db_utx_sets, hasDrawnState, _canvasRef)
    usePlacementAssist(deviceBeingPlaced, MousePositionNorm, _canvasRef)
    const { selectedGridsRef, addToSelection, reset: resetSelectedGrids } = useSelectedGrids(_canvasRef)

    const setPendingDevices = (setValueFn) => {
        _pendingDevicesRef.current = setValueFn(_pendingDevicesRef.current)
        _setPendingDevices(setValueFn)
    }

    const setPendingPickups = (setValueFn) => {
        _pendingPickupsRef.current = setValueFn(_pendingPickupsRef.current)
        _setPendingPickups(setValueFn)
    }

    const setDeviceBeingPlaced = (setValueFn) => {
        _deviceBeingPlacedRef.current = setValueFn(_deviceBeingPlacedRef.current)
        _setDeviceBeingPlaced(setValueFn)
    }

    // Used for invoking contract directly from the game world
    const { contract } = useUniverseContract ()

    const { data: deployDeviceTxid, loading, error: deployDeviceError, reset, invoke: invokePlayerDeployDevice } = useStarknetInvoke ({
        contract,
        method: 'player_deploy_device'
    })

    // Use a ref to hold the reference to the current invoke function
    // So it can be used in event callbacks, etc.
    const invokePlayerDeployDeviceRef = useRef(invokePlayerDeployDevice)
    // Always set the current ref when the function changes (contract is loaded, etc)
    invokePlayerDeployDeviceRef.current = invokePlayerDeployDevice

    const { data: deployUtxTxid, error: deployUtxError, loading: deployUtxLoading, invoke: invokePlayerDeployUtx } = useStarknetInvoke ({
        contract,
        method: 'player_deploy_utx_by_grids'
    })
    // Debug
    // const [deployUtxTxid, setDeployUtxTxid] = useState()

    // Use a ref to hold the reference to the current invoke function
    // So it can be used in event callbacks, etc.
    const invokePlayerDeployUtxRef = useRef(invokePlayerDeployUtx)
    // Always set the current ref when the function changes (contract is loaded, etc)
    invokePlayerDeployUtxRef.current = invokePlayerDeployUtx

    // const [hoverTransferDeviceRect, setHoverTransferDeviceRect] = useState(false)

    const faceRadiationRef = useRef()
    if (db_macro_states?.macro_states && db_macro_states.macro_states[0]) {
        faceRadiationRef.current = faceRadiationFromMacro(db_macro_states.macro_states[0])
    }

    const face = find_face_given_grid (MousePositionNorm.x, MousePositionNorm.y)

    //
    // useEffect for checking if all database collections are loaded
    //
    useDebouncedEffect(() => {
        // if (hasLoadedDB) {
        //     return
        // }
        if (!_canvasRef.current) {
            console.log ('> canvas not created..')
            return
        }

        if (!db_macro_states || !db_civ_state || !db_player_fungible_balances || !db_deployed_devices || !db_utx_sets || !db_pgs || !db_harvesters || !db_transformers || !db_upsfs || !db_ndpes) {
            console.log ('> db not fully loaded..')
            return
        }
        else {
            console.log ('> db fully loaded!')

            // setHasLoadedDB (true)
            // console.log ('drawWorld()')

            //
            // reset references, states, and fabric canvas
            //
            _currZoom.current = _canvasRef.current.getZoom();

            // Clear canvas, but check whether context is defined
            // If the context is not available, clearing will throw
            if (_canvasRef.current.getContext()) {
                // console.log("Clearing canvas")
                _canvasRef.current.clear();
            }

            resetUtxAnim()
            updatePendingDevices(db_deployed_devices)
            updatePendingPickups(db_deployed_devices)
            setDeviceBeingPlaced(() => null)
            // _cursorGridRectRef.current = null

            imageLeftToBeDrawnRef.current = 6*5
            requestAnimationFrame(() => {
                setImageAllDrawnState (false)
            })

            //
            // draw the world
            //
            drawWorldUpToImages (_canvasRef.current)
            setHudVisible (true)
        }
    }, [db_macro_states, db_civ_state, db_player_fungible_balances, db_deployed_devices, db_utx_sets, db_pgs, db_harvesters, db_transformers, db_upsfs, db_ndpes], 1000);

    //
    // useEffect to check if the signed in account is in current civilization
    //
    useEffect (() => {
        if (!db_player_fungible_balances) return
        if (!account) return

        const player_fungible_balances = db_player_fungible_balances.player_fungible_balances
        var account_intstr_list = []
        for (const entry of player_fungible_balances) {
            account_intstr_list.push (entry['account'])
        }

        const account_intstr = toBN(account).toString()

        if (account_intstr_list.includes(account_intstr)) {
            console.log ('account is in this civilization')
            setAccountInCiv (true)

            var entry = player_fungible_balances.filter(obj => {
                return obj['account'] === account_intstr
            })
            setAccountDeviceBalance (entry[0])
            console.log ('setAccountDeviceBalance', entry[0])
        }
        else {
            console.log ('account is not in this civilization')
            setAccountInCiv (false)
        }

    }, [db_player_fungible_balances, account]);


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

        if (bool_in_range && !_deviceBeingPlacedRef.current) {
            addToSelection ({x: x_grid, y: y_grid})
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

        if (bool_mouse_down && bool_in_range) {
            addToSelection ({x: x_grid, y: y_grid})
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
        const bool_not_empty = (selectedGridsRef.current.length !== 0)

        if (_deviceBeingPlacedRef.current) {
            // TODO: check if device placement is valid
            console.log("invoke", ({ args: [_deviceBeingPlacedRef.current.id, { x: x_grid, y: y_grid }] }))
            invokePlayerDeployDeviceRef.current ({
                args: [_deviceBeingPlacedRef.current.id, { x: x_grid, y: y_grid }]
            })
            setDeviceBeingPlaced((prev) => ({ ...prev, x: x_grid, y: y_grid }))
        } else if (bool_in_range && bool_not_empty && _deployingUtxRef.current) {
            // Deploying specific UTX
            const utx = utxFromSelectedGrids(selectedGridsRef.current)
            console.log("invoke contract with selected grids. utx: ", utx)
            invokePlayerDeployUtxRef.current ({ args: [
                _deployingUtxRef.current,
                utx.src,
                utx.dst,
                utx.grids
            ] })
        } else if (bool_in_range && bool_not_empty) {
            setModalVisibility (true)
            modalVisibilityRef.current = true

            const info = {
                'mode' : 'grids',
                'grids' : selectedGridsRef.current
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

        setModalVisibility (false)
        modalVisibilityRef.current = false

        resetSelectedGrids()
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

        if (ev.key === "Escape") {
            // console.log("escape key pressed, resetting device placement")
            setDeviceBeingPlaced(() => null)
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

        toggleUtxAnimationVisible(visibility)
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

        const { height: windowHeight } = getWindowDimensions()

        _canvasRef.current = new fabric.Canvas('c', {
            height: windowHeight,
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
            handleMouseDrag (posx, posy)

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
            setGridMapping (gridMappingFromData(
                db_pgs,
                db_harvesters,
                db_transformers,
                db_upsfs,
                db_ndpes,
                db_deployed_devices
            ))
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

            if (!faceRadiationRef.current) {return;}

            faceRadiationRef.current.forEach((exposure, face) => {
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
            });

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
        // console.log("drawAssist")

        canvi.add (_cursorGridRectRef.current)
        canvi.add (_cursorFaceRectRef.current)
        canvi.add (_cursorHoverDeviceRectRef.current)

        canvi.requestRenderAll();
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
                            requestAnimationFrame(() => {
                                setImageAllDrawnState (true)
                            })
                        }
                });
            }

            _textureRef.current[element] = collection
        }

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
                    DEVICE_TYPE_FULL_NAME_MAP [gridData.type],
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
            _cursorGridRectRef.current.left = PAD_X + mPosNorm.x*GRID - STROKE_WIDTH_GRID_MEDIUM/2
            _cursorGridRectRef.current.top  = PAD_Y + (SIDE*3 - mPosNorm.y - 1)*GRID - STROKE_WIDTH_GRID_MEDIUM/2
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
            // Only change object in state if coordinates differ
            if (MousePositionNorm.x !== x_norm || MousePositionNorm.y !== y_norm) {
                setMousePositionNorm ({
                    x: x_norm,
                    y: y_norm
                })
            }
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
            utxGrids: utxGrids && utxGrids.map((grid) => ({...grid, rectRef: React.createRef()})),
            dimension: DEVICE_DIM_MAP.get(typ),
            color: DEVICE_COLOR_MAP.get(typ),
            rectRef: React.createRef(),
            txid
        }
        // Add the device to the list of pending devices
        setPendingDevices ((pendingDevices) => {
            if (pendingDevices.find(d => d.txid === txid)) {
                console.log('Cannot add device with the same txid')
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

    function handleDeployDevice(device) {
        hidePopup()
        // After hiding the popup, the state needs to trigger with a
        // bit of delay in order for the device placement assist to be
        // rendered properly (fabric.js quirk?)
        // Edit: still Not working properly...
        setTimeout(() => {
            setDeviceBeingPlaced(() => device)
        }, 200)
    }

    useEffect(() => {
        const deviceBeingPlaced = _deviceBeingPlacedRef.current
        if (deployDeviceTxid && deviceBeingPlaced) {
            handleDeployStarted({ ...deviceBeingPlaced, typ: deviceBeingPlaced.type, txid: deployDeviceTxid })
            setDeviceBeingPlaced(() => null)
        }
    }, [deployDeviceTxid])

    function handleDeployUtx(type) {
        hidePopup()
        setDeployingUtx(() => type)
    }

    useEffect(() => {
        const deployingUtx = _deployingUtxRef.current
        if (deployUtxTxid && deployingUtx) {
            const utxGrids = selectedGridsRef.current
            handleDeployStarted({
                x: utxGrids[0].x, y: utxGrids[0].y, utxGrids,
                typ: deployingUtx, txid: deployUtxTxid
            })
            setDeployingUtx(() => null)
            resetSelectedGrids()
        }
    }, [deployUtxTxid, deployUtxLoading])

    useEffect(() => {
        if (!deployUtxLoading && deployUtxError) {
            // console.log("error", deployUtxError)
            setDeployingUtx(() => null)
            resetSelectedGrids()
        }
    }, [deployUtxError, deployUtxLoading])

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
                onDeployDevice = {handleDeployDevice}
                onDeployUtx = {handleDeployUtx}
                onPendingPickup = {handlePendingPickup}
            />


            {deviceBeingPlaced && <FloatingMessage message={<>Choose the location you want deploy your device, then press <kbd>LMB</kbd> to initiate the deploy.</>} />}

            {deployingUtx && <FloatingMessage message={<>Choose the location of the {DEVICE_TYPE_FULL_NAME_MAP[deployingUtx]} by pressing <kbd>LMB</kbd> and dragging along the path.</>} />}

            {universeActive && <HUDLeft faceRadiation={faceRadiationRef.current} selectedFace={face} />}

            <HUD lines={hudLines} universeActive={universeActive}/>

            <canvas id="c" />

            {/* DEBUG PANEL */}
            {/* <button onClick={() => setDebugCounter((c) => c + 1)}>Trigger redraw</button>
            <button
                onClick={() =>
                    setDeviceBeingPlaced((d) => ({
                        type: 14,
                        dimension: DEVICE_DIM_MAP.get(14),
                        color: DEVICE_COLOR_MAP.get(14),
                    }))
                }
            >
                Place device
            </button>
            <button
                onClick={() =>
                    setDeployUtxTxid(() => '12345')
                }
            >
                Set utx deploy txid
            </button> */}
        </div>
    );
}
