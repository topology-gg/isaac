import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { toBN } from 'starknet/dist/utils/number'
import Button from './Button'

import { useUniverseContract } from "./UniverseContract";
import { useLobbyContract } from "./LobbyContract";
import { useDAOContract } from "./DAOContract";
import { useYagiRouterUniContract } from "./YagiRouterUniverseContract";
import { useFsmSubjectContract } from "./FsmSubjectContract";
import { useFsmCharterContract } from "./FsmCharterContract";
import { useFsmAngelContract } from "./FsmAngelContract";

import { isaac_addresses, yagi_addresses, s2m2_addr, gyoza_addr } from "./Addresses";

import {
    useStarknet,
    useStarknetInvoke
} from '@starknet-react/core'

const CIV_SIZE = 5

export default function Config () {

    //
    // Interact with Starknet
    //
    const { account } = useStarknet ()
    const { contract: universe_contract }    = useUniverseContract ()
    const { contract: lobby_contract }       = useLobbyContract ()
    const { contract: fsm_subject_contract } = useFsmSubjectContract ()
    const { contract: fsm_charter_contract } = useFsmCharterContract ()
    const { contract: fsm_angel_contract }   = useFsmAngelContract ()
    const { contract: dao_contract }         = useDAOContract ()
    const { contract: yagi_router_uni_contract } = useYagiRouterUniContract ()

    console.log ('universe_contract: ', universe_contract)

    const [completed1, setCompleted1] = useState(false);
    const [completed2, setCompleted2] = useState(false);
    const [completed3, setCompleted3] = useState(false);
    const [completed4, setCompleted4] = useState(false);
    const [completed5, setCompleted5] = useState(false);
    const [completed6, setCompleted6] = useState(false);
    const [completed7, setCompleted7] = useState(false);
    const [completed8, setCompleted8] = useState(false);
    const [completed9, setCompleted9] = useState(false);

    const {
        invoke : invoke_universe_set_lobby_address_once
    } = useStarknetInvoke ({
        contract: universe_contract,
        method: 'set_lobby_address_once'
    })

    const {
        invoke : invoke_lobby_set_universe_addresses_once
    } = useStarknetInvoke ({
        contract: lobby_contract,
        method: 'set_universe_addresses_once'
    })

    const {
        invoke : invoke_lobby_set_s2m2_address_once
    } = useStarknetInvoke ({
        contract: lobby_contract,
        method: 'set_s2m2_address_once'
    })

    const {
        invoke : invoke_lobby_set_dao_address_once
    } = useStarknetInvoke ({
        contract: lobby_contract,
        method: 'set_dao_address_once'
    })

    const {
        invoke : invoke_fsm_subject_init_owner_dao_address_once
    } = useStarknetInvoke ({
        contract: fsm_subject_contract,
        method: 'init_owner_dao_address_once'
    })

    const {
        invoke : invoke_fsm_charter_init_owner_dao_address_once
    } = useStarknetInvoke ({
        contract: fsm_charter_contract,
        method: 'init_owner_dao_address_once'
    })

    const {
        invoke : invoke_fsm_angel_init_owner_dao_address_once
    } = useStarknetInvoke ({
        contract: fsm_angel_contract,
        method: 'init_owner_dao_address_once'
    })

    const {
        invoke : invoke_dao_set_votable_and_fsm_addresses_once
    } = useStarknetInvoke ({
        contract: dao_contract,
        method: 'set_votable_and_fsm_addresses_once'
    })
    const DAO_ARGS = [
        isaac_addresses.lobby,
        isaac_addresses.charter,
        gyoza_addr,
        isaac_addresses.fsm_subject,
        isaac_addresses.fsm_charter,
        isaac_addresses.fsm_angel
    ]

    const {
        invoke : invoke_yagi_change_isaac_universe_address
    } = useStarknetInvoke ({
        contract: yagi_router_uni_contract,
        method: 'change_isaac_universe_address'
    })
    const YAGI_ARGS = [
        521118,
        isaac_addresses.universe
    ]

    return (
        <div style={{marginTop:'13px'}}>
            <Button onClick={ () => {
                invoke_universe_set_lobby_address_once ({args : [isaac_addresses.lobby]});
                setCompleted1 (true)
            } }>{completed1 ? '1 - completed' : '1'}</Button>

            <Button onClick={ () => {
                invoke_lobby_set_universe_addresses_once ({args : [ [isaac_addresses.universe] ]})
                setCompleted2 (true)
            } }>{completed2 ? '2 - completed' : '2'}</Button>
            <Button onClick={ () => {
                invoke_lobby_set_s2m2_address_once ({args : [s2m2_addr]})
                setCompleted3 (true)
            } }>{completed3 ? '3 - completed' : '3'}</Button>
            <Button onClick={ () => {
                invoke_lobby_set_dao_address_once ({args : [isaac_addresses.dao]})
                setCompleted4 (true)
            } }>{completed4 ? '4 - completed' : '4'}</Button>

            <Button onClick={ () => {
                invoke_fsm_subject_init_owner_dao_address_once ({args : [isaac_addresses.dao]})
                setCompleted5 (true)
            } }>{completed5 ? '5 - completed' : '5'}</Button>
            <Button onClick={ () => {
                invoke_fsm_charter_init_owner_dao_address_once ({args : [isaac_addresses.dao]})
                setCompleted6 (true)
            } }>{completed6 ? '6 - completed' : '6'}</Button>
            <Button onClick={ () => {
                invoke_fsm_angel_init_owner_dao_address_once ({args : [isaac_addresses.dao]})
                setCompleted7 (true)
            } }>{completed7 ? '7 - completed' : '7'}</Button>

            <Button onClick={ () => {
                invoke_dao_set_votable_and_fsm_addresses_once ({args : DAO_ARGS})
                setCompleted8 (true)
            } }>{completed8 ? '8 - completed' : '8'}</Button>

            <Button onClick={ () => {
                invoke_yagi_change_isaac_universe_address ({args : YAGI_ARGS})
                setCompleted9 (true)
            } }>{completed9 ? '9 - completed' : '9'}</Button>
        </div>
    );
  }
