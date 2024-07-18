import React, { Component, useState, useEffect, useRef} from "react";
// import coverArtImage from './cover-art.png';

// refs:
// https://stackoverflow.com/questions/65731647/how-to-fade-out-and-fade-in-in-react
// https://stackoverflow.com/questions/68016644/hiding-div-after-a-few-seconds-reactjs

export default function CoverArt () {

    const [showElement,setShowElement] = React.useState(true)
    useEffect(()=>{
        setTimeout(function() {
            setShowElement(false)
                }, 2.5 * 1000);
            },
    [])

    return (
        <div className={ showElement ? "show cover_art" : "hide_slow cover_art"}>
        </div>
      );
  }
