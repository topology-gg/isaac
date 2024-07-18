import cubeIconSvg from "../public/cubeIcon.svg";

import React from "react";

const CubeIcon = ({ face, theme }) => {
    return (
        <svg width={20} height={20} viewBox="0 0 34 34">
            <use href={`${cubeIconSvg.src}#${theme}${face}`} />
        </svg>
    );
};

CubeIcon.defaultProps = {
    theme: "light",
};

export default CubeIcon;
