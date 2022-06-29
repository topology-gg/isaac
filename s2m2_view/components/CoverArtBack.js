import React, { Component, useState, useEffect, useRef} from "react";
// import coverArtImage from './cover-art.png';

// refs:
// https://stackoverflow.com/questions/65731647/how-to-fade-out-and-fade-in-in-react
// https://stackoverflow.com/questions/68016644/hiding-div-after-a-few-seconds-reactjs

export default function CoverArtBack () {
    const [isShowingAlert, setShowingAlert] = React.useState(false);

    const [showElement,setShowElement] = React.useState(true)
    useEffect(()=>{
        setTimeout(function() {
            setShowElement(false)
                }, 3 * 1000);
            },
    [])

    return (
        <div className={ showElement ? "show cover_art_back" : "hide cover_art_back"}>
          {/* <img src={coverArtImage} /> */}
          {/* <img src={require('./cover-art.png').default} /> */}
        </div>
      );
}