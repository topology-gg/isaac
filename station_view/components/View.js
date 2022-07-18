import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { fabric } from 'fabric';
import { toBN } from 'starknet/dist/utils/number'

import {
    useLobbyQueue,
    useCivState,
    usePlayerBalances
} from '../lib/api'
import { useUniverseContract } from "./UniverseContract";
import { useLobbyContract } from "./LobbyContract";

import {
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core'


export default function View () {

    //
    // Interact with Starknet
    //
    const { account } = useStarknet ()
    const { contract: lobby_contract } = useLobbyContract ()

    const { data, loading, error, reset, invoke } = useStarknetInvoke ({
        lobby_contract,
        method: 'anyone_ask_to_queue'
    })

    //
    // Data fetched from backend on Apibara
    //
    const { data: db_lobby_queue } = useLobbyQueue ()
    const { data: db_civ_state } = useCivState ()
    const { data: db_player_balances } = usePlayerBalances ()

    //
    // React states and references
    //
    const [lobbyQueueLength, setLobbyQueueLength] = useState ('loading ...')
    const [hasLoadedDB, setHasLoadedDB] = useState (false)
    const [universeStatus, setUniverseStatus] = useState ('loading ...')
    const [universeInfo, setUniverseInfo] = useState ([])
    const [accountQueueInfo, setAccountQueueInfo] = useState ('')

    //
    // Check if all db collections are loaded
    //
    useEffect (() => {
        if (hasLoadedDB) {
            return
        }
        if (!db_lobby_queue || !db_civ_state || !db_player_balances) {
            console.log ('db loading ...')
            return
        }
        else {
            console.log ('db loaded!')
            setHasLoadedDB (true)
        }
    }, [hasLoadedDB, db_lobby_queue, db_civ_state, db_player_balances]);

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

            //
            // set display text based on queue condition
            //
            // console.log (`db_civ_state.civ_state.length: ${db_civ_state.civ_state.length}`)
            if (db_civ_state.civ_state.length == 0) {
                //
                // no universe launched ever
                //
                setUniverseStatus ('idle')
            }
            else if (db_civ_state.civ_state[0].active == 0) {
                setUniverseStatus ('idle')
            }
            else {
                setUniverseStatus ('active')
                const civ_idx = db_civ_state.civ_state[0].civ_idx

                const info = [
                    <p key='civ-num' style={{textAlign:'center'}}>Civilization number: {civ_idx}</p>,
                    <p key='univ-age' style={{textAlign:'center'}}>Universe age: __ / 2160 ticks</p>,
                    <p key='transport' style={{textAlign:'center'}}>Transport to Space View and Working View</p>
                ]
                setUniverseInfo (info)
            }

            // ...
            if (!account) {
                setAccountQueueInfo ('no account connected')
            }
            else if (queue_length == 0) {
                setAccountQueueInfo ('queue is empty')
            }
            else {
                const account_int_str = toBN(account).toString(10)

                //
                // find if account is in queue (array.includes);
                //
                var queue_accounts = []
                for (const entry of db_lobby_queue.lobby_queue) {
                    queue_accounts.push (entry.account)
                }
                if (queue_accounts.includes(account_int_str)) {
                    setAccountQueueInfo ('account is in queue')
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
                        setAccountQueueInfo ('account is in the civilization of the active universe #0')
                    }
                    else {
                        setAccountQueueInfo ('account is not queue nor in the civilization of the active universe #0')
                    }
                }

            }

        }
    }, [hasLoadedDB, account, db_civ_state, db_lobby_queue, db_player_balances])


    //
    // Handler for button click
    //
    function onClick () {
        console.log ('Join queue button clicked')
        invoke ({ args: [] })
    }

    const sun_radius = '15em'
    const sun_dim = '30em'
    const sun_style = {
        marginTop: '50px',
        width: sun_dim,
        height: sun_dim,
        borderRadius: sun_radius,
        border: '1px #333333 solid',

        display: 'flex',
        justifyContent: 'center',
        alignContent: 'center',
        flexDirection: 'column',

        backgroundColor: '#CCCCCC44'
    }

    return (
        <div style={{display:'flex',flexDirection:'column'}}>

            <div style={{textAlign:'center'}}>
                <p>Queue length: {lobbyQueueLength} / {accountQueueInfo}</p>
            </div>

            <div style={{height:'1em'}}>
                {
                    account && (
                        <div style={{textAlign:'center'}}>
                            <button
                                // style = {BUTTON_SINGLE_STYLE}
                                onClick = {onClick}
                                className = 'action-button'
                            >
                                Join queue
                            </button>
                            <p>Error: {error || 'No error'}</p>
                            <p>Data: {data || 'No data'}</p>
                        </div>
                    )
                }
            </div>

            <div style={sun_style}>
                <h3 style={{textAlign:'center'}}>
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
