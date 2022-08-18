import React, { Component, useState, useEffect, useRef, useCallback, useMemo } from "react";
import { toBN } from 'starknet/dist/utils/number'

import {
    useCivStates,
} from '../lib/api'

import ReplayCanvas from "../components/ReplayCanvas"

export default function ReplayWindow (props) {

    const title = `Civilization Number ${props.dbStatesReplayWindow.civ_idx}`

    function handleClick () {
        props.toggleReplayWindow ()
    }

    return (
        <div style={{display:'flex',flexDirection:'column',textAlign:'center',justifyContent:"center",alignItems:"center"}}>
            <h2 style={{marginBottom:'10px'}}>{title}</h2>
            <button
                onClick={() => handleClick()}
                style={{padding:'0',margin:'0',height:'25px',border:'0',width:'160px',color:'#333333',fontSize:'13.33px',fontFamily:'Poppins-Light'}}
            >
                Close
            </button>

            <ReplayCanvas macro_states={props.dbStatesReplayWindow.macro_states} open={props.open}/>

        </div>
    );
  }
