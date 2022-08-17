import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useLobbyQueue,
    useCivState,
    usePlayerBalances,
    useMacroStates
} from '../lib/api'
import { useUniverseContract } from "./UniverseContract";
import { useLobbyContract } from "./LobbyContract";

import {
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core'

const CIV_SIZE = 5

export default function View () {

    //
    // Interact with Starknet
    //
    const { account } = useStarknet ()
    const { contract: lobby_contract } = useLobbyContract ()

    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        contract: lobby_contract,
        method: 'anyone_ask_to_queue'
    })

    //
    // Data fetched from backend on Apibara
    //
    const { data: db_lobby_queue } = useLobbyQueue ()
    const { data: db_civ_state } = useCivState ()
    const { data: db_player_balances } = usePlayerBalances ()
    const { data: db_macro_states } = useMacroStates ()

    //
    // React states and references
    //
    const [lobbyQueueLength, setLobbyQueueLength] = useState ('loading ...')
    const [hasLoadedDB, setHasLoadedDB] = useState (false)
    const [universeStatus, setUniverseStatus] = useState ('loading ...')
    const [universeInfo, setUniverseInfo] = useState ([])
    const [accountQueueInfo, setAccountQueueInfo] = useState ('')
    const [queueInfo, setQueueInfo] = useState ('')
    const [joinButtonText, setJoinButtonText] = useState ('')
    const [joinButtonColor, setJoinButtonColor] = useState ('#333333')

    //
    // Check if all db collections are loaded
    //
    useEffect (() => {
        if (hasLoadedDB) {
            return
        }
        if (!db_lobby_queue || !db_civ_state || !db_player_balances || !db_macro_states) {
            console.log ('View: db loading ...')
            return
        }
        else {
            console.log ('> View: db loaded!')
            setHasLoadedDB (true)
        }
    }, [hasLoadedDB, db_lobby_queue, db_civ_state, db_player_balances, db_macro_states]);

    //
    // Set display once database collections are all loaded
    //
    useEffect (() => {
        if (hasLoadedDB) {
            // console.log (db_civ_state)
            // console.log (db_lobby_queue)

            //
            // set display queue length
            //
            const queue_length = db_lobby_queue.lobby_queue.length
            setLobbyQueueLength (queue_length)


            if (!db_civ_state.civ_state || (db_civ_state.civ_state.length == 0)) {
                //
                // no universe launched ever
                //
                setUniverseStatus ('idle')
                // console.log('aaa')
            }
            else if (db_civ_state.civ_state[0].active == 0) {
                setUniverseStatus ('idle')
                // console.log('bbb')
            }
            else {
                setUniverseStatus ('active')
                // console.log('ccc')
                const civ_idx = db_civ_state.civ_state[0].civ_idx
                const ticks_since_birth = db_macro_states.macro_states.length - 1 // at age 0 a macro state event is emitted
                const population = db_player_balances.player_balances.length

                const p_style = {textAlign:'center',marginTop:'0',marginBottom:'0'}
                const info = [
                    <p key='civ-num' style={p_style}>Civilization number: {civ_idx}</p>,
                    <p key='population' style={p_style}>Population: {population}</p>,
                    <p key='univ-age' style={p_style}>Universe age: {ticks_since_birth} / 2520 ticks</p>,
                    <p key='transport' style={p_style}>
                        <a href="" target="_blank" rel="noopener noreferrer">
                            Space View
                        </a>
                        /
                        <a href="" target="_blank" rel="noopener noreferrer">
                            Working View
                        </a>
                    </p>
                ]
                setUniverseInfo (info)
            }

            if (!account) {
                setAccountQueueInfo ('no account connected')
            }
            else if (queue_length == 0) {
                setAccountQueueInfo ('queue is empty')
                setQueueInfo (`waiting for ${CIV_SIZE} more players before attempting dispatch`)
                setJoinButtonText ('join queue')
            }
            else if (queue_length == CIV_SIZE) {
                setQueueInfo (`queue is full; ready for dispatch`)
                setJoinButtonText ('queue full')
                setJoinButtonColor ('#999999')
            }
            else {

                //
                // check if all universes are active or if some is available
                //
                if (!db_civ_state.civ_state[0]) {
                    setQueueInfo (`waiting for ${CIV_SIZE-queue_length} more players before dispatching`)
                }
                else if (db_civ_state.civ_state[0].active == 0) {
                    setQueueInfo (`waiting for ${CIV_SIZE-queue_length} more players before dispatching`)
                }
                else {
                    setQueueInfo (`all universes are active`)
                }
                const account_int_str = toBN(account).toString(10)

                //
                // get queue head idx to calculate effective queue index for account
                //
                const head_idx = db_lobby_queue.lobby_queue[0].queue_idx

                //
                // find if account is in queue
                //
                var queue_accounts = []
                for (const entry of db_lobby_queue.lobby_queue) {
                    queue_accounts.push (entry.account)
                }
                if (queue_accounts.includes(account_int_str)) {
                    const index = queue_accounts.indexOf (account_int_str)
                    console.log('index:',index)
                    const effective_queue_idx = db_lobby_queue.lobby_queue[index].queue_idx - head_idx
                    setAccountQueueInfo (`ALREADY IN QUEUE: account is at queue position ${effective_queue_idx}`)
                    setJoinButtonText ('already in queue')
                    setJoinButtonColor ('#999999')
                }
                else {
                    //
                    // find if account is in the civilization of active universe
                    //
                    var civ_accounts = []
                    for (const balance of db_player_balances.player_balances) {
                        civ_accounts.push (balance.account)
                    }
                    if (civ_accounts.includes(account_int_str)) {
                        // setAccountQueueInfo ('account is in the civilization of the active universe #0')
                        setAccountQueueInfo ('CANNOT QUEUE: account already in active universe #0')
                        setJoinButtonColor ('#999999')
                    }
                    else {
                        setAccountQueueInfo ('CAN QUEUE')
                        setJoinButtonColor ('#333333')
                    }

                    setJoinButtonText ('join queue')
                }

            }

        }
    }, [hasLoadedDB, account, db_civ_state, db_lobby_queue, db_player_balances, db_macro_states])


    //
    // Handler for button click
    //
    function onClick () {
        // console.log ('Join queue button clicked')
        if (joinButtonColor==='#333333') {
            invoke ({ args: [] })
        }
    }

    const join_button_color = {color:joinButtonColor}
    const join_button_style = {
        ...{padding:'0',margin:'0',height:'25px',border:'0',width:'160px',fontFamily:'Poppins-Light', borderRadius: '10px'},
        ...join_button_color
    }

    return (
        <div style={{display:'flex',flexDirection:'column'}}>

            <div style={{textAlign:'center'}}>
                <p style={{marginTop:'0.5em'}}>Queue length: {lobbyQueueLength} / {accountQueueInfo} / {queueInfo}</p>
            </div>

            <div style={{height:'3em'}}>
                {
                    account && (
                        <div style={{textAlign:'center'}}>
                            <button
                                style = {join_button_style}
                                onClick = {onClick}
                                className = 'action-button'
                            >
                                {joinButtonText}
                            </button>
                            {/* <p>Error: {error || 'No error'}</p> */}
                            {/* <p>Data: {data || 'No data'}</p> */}
                        </div>
                    )
                }
            </div>

            <div className='sun'>
            </div>

            <div>
                <h3 style={{textAlign:'center',marginBottom:'0'}}>
                    Universe #0
                </h3>
                <h4 style={{textAlign:'center'}}>
                    Status: {universeStatus}
                </h4>

                {
                    (universeStatus == 'active') && universeInfo
                }
            </div>
        </div>
    );
  }
