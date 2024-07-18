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

import {
    isaac_proxy_addresses, yagi_addresses, s2m2_addr,
    gyoza_addr, gyoza_oxford_addr, gyoza_charlie_addr, gyoza_pensive_addr, gyoza_longboard_addr
} from "./Addresses";

import {
    useStarknet,
    useStarknetCall
} from '@starknet-react/core'

const CIV_SIZE = 5

export default function View () {

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

    const { data: macro_state_curr } = useStarknetCall ({
        contract: universe_contract,
        method: 'macro_state_curr_read',
        args: [],
    })

    return (
        <div style={{marginTop:'13px'}}>
            {macro_state_curr ? <p>{JSON.stringify(macro_state_curr.macro_state)}</p> : <></>}
        </div>
    );
  }
