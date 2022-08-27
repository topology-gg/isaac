import { useEffect, useRef } from "react";
import { DEVICE_COLOR_MAP } from "../../components/ConstantDeviceColors";
import { GRID, SIDE, PAD_X, PAD_Y, ANIM_UPDATE_INTERVAL_MS } from "../constants/gameWorld";

export default function useUtxAnimation(db_utx_sets, hasDrawnState, canvasRef) {
    const utxAnimRectsRef = useRef([]);
    const utxAnimGridsRef = useRef([]);
    const utxAnimGridIndicesRef = useRef([]);

    console.log("useUtxAnimation. db_utx_sets: ", db_utx_sets)

    const draw = () => {
        if (!db_utx_sets) return;

        console.log("drawing utx animation");

        for (const utx_set of db_utx_sets.utx_sets) {
            //
            // If not tethered, don't create animation
            //
            if (utx_set.tethered == 0) {
                console.log("utx set not tethered");
                continue;
            }
            console.log("utx set tethered. drawing rect", utx_set);

            //
            // For each utx set, create a rect for animation
            //
            const color = DEVICE_COLOR_MAP.get(`${utx_set.type}-anim`);
            const rect = new fabric.Rect({
                height: GRID,
                width: GRID,
                left: PAD_X + utx_set.grids[0].x * GRID,
                top: PAD_Y + (SIDE * 3 - utx_set.grids[0].y - 1) * GRID,
                fill: color,
                opacity: 0.2,
                selectable: false,
                hoverCursor: "default",
                strokeWidth: 0,
            });
            utxAnimRectsRef.current.push(rect);

            //
            // For each utx set, set the grids along its animation path, with first grid as redundant for full transparent rect (enable flashing effect for single-utx)
            // set animation index to 0
            //
            const grids = [utx_set.grids[0]].concat(utx_set.grids);
            utxAnimGridsRef.current.push(grids);
            utxAnimGridIndicesRef.current.push(0);

            canvasRef.current.add(rect);
        }
    };

    // reference: https://stackoverflow.com/questions/57137094/implementing-a-countdown-timer-in-react-with-hooks
    useEffect(() => {
        if (!db_utx_sets) return;
        if (hasDrawnState === 0) return;
        if (canvasRef === null) return;

        var n_utx_set = 0;
        for (const utx_set of db_utx_sets.utx_sets) {
            if (utx_set.tethered == 1) {
                n_utx_set += 1;
            }
        }

        console.log("starting utx animation");

        const interval = setInterval(() => {
            for (const i = 0; i < n_utx_set; i++) {
                //
                // get the next animation index
                //
                const anim_length = utxAnimGridsRef.current[i].length;
                const anim_idx_ = utxAnimGridIndicesRef.current[i] + 1;
                const anim_idx = anim_idx_ == anim_length ? 0 : anim_idx_;
                // console.log (`${i} anim_idx=${anim_idx}`)
                utxAnimGridIndicesRef.current[i] = anim_idx;

                //
                // animate x
                //
                const x = utxAnimGridsRef.current[i][anim_idx].x;
                utxAnimRectsRef.current[i].left = PAD_X + x * GRID;

                //
                // animate y
                //
                const y = utxAnimGridsRef.current[i][anim_idx].y;
                utxAnimRectsRef.current[i].top =
                    PAD_Y + (SIDE * 3 - y - 1) * GRID;

                //
                // animate opacity - make transparent at i=0
                //
                if (anim_idx == 0) {
                    utxAnimRectsRef.current[i].opacity = 0;
                } else {
                    utxAnimRectsRef.current[i].opacity = 0.2;
                }

                // console.log (`ANIMATE: new grid (${x}, ${y})`)
            }
            canvasRef.current.requestRenderAll();
        }, ANIM_UPDATE_INTERVAL_MS);

        return () => clearInterval(interval);
    }, [hasDrawnState, db_utx_sets]);

    const toggleVisible = (visibility) => {
        for (const rect of utxAnimRectsRef.current) {
            rect.visible = visibility;
        }
    };

    const reset = () => {
        utxAnimRectsRef.current = [];
        utxAnimGridsRef.current = [];
        utxAnimGridIndicesRef.current = [];
    };

    return { draw, reset, toggleVisible };
}
