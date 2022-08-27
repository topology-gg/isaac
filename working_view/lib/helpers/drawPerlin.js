import lerp from "../../lib/helpers/lerp"
import { PERLIN_COLOR_MAP } from '../../components/ConstantPerlinColors'

// PERLIN_VALUES
export const drawPerlin = canvi => {

    //
    // build colors
    //
    var perlin_colors_per_element = {}
    for (const element of ['fe','al','cu','si','pu']){

        var perlin_colors = {}
        const perlin_values = PERLIN_VALUES[element]
        // console.log (`${element} / max perline value: ${perlin_values['max']}`)
        // console.log (`${element} / min perline value: ${perlin_values['min']}`)

        for (var face=0; face<6; face++) {

            for (var row=0; row<SIDE; row++) {
                for (var col=0; col<SIDE; col++) {

                    const perlin_value = perlin_values[face][row][col]
                    const perlin_value_normalized = (perlin_value - perlin_values['min']) / (perlin_values['max'] - perlin_values['min'])

                    const hi = PERLIN_COLOR_MAP[element]['hi']
                    const lo = PERLIN_COLOR_MAP[element]['lo']
                    const r = lerp (lo[0], hi[0], perlin_value_normalized)
                    const g = lerp (lo[1], hi[1], perlin_value_normalized)
                    const b = lerp (lo[2], hi[2], perlin_value_normalized)
                    const rect_color = `rgb(${r}, ${g}, ${b})`

                    perlin_colors [`(${face},${row},${col})`] = rect_color
                }
            }
        }
        perlin_colors_per_element [element] = perlin_colors
    }
    _perlinColorsPerElementRef.current = perlin_colors_per_element

    //
    // build rects
    //
    const perlin_rects = []
    const perlin_rects_dict = {}
    for (var face=0; face<6; face++) {

        const face_ori = find_face_ori (face)

        for (var row=0; row<SIDE; row++) {

            for (var col=0; col<SIDE; col++) {

                var rect = new fabric.Rect({
                    height: GRID,
                    width: GRID,
                    left: PAD_X + (col + face_ori[0]) * GRID,
                    top: PAD_Y + (SIDE*3 - (row + face_ori[1]) - 1) * GRID,
                    fill: '#FFFFFF',
                    selectable: false,
                    hoverCursor: 'default',
                    visible: false,
                    strokeWidth: 0,

                    objectCaching: true
                });
                perlin_rects.push (rect)
                perlin_rects_dict [`(${face},${row},${col})`] = rect
                canvi.add (rect) // if we need per-rect control we need to add each rect to the canvas
            }
        }
    }
    _elementDisplayRectsRef.current = perlin_rects_dict

    // // TODO: may be able to fix text blurring at high zoom by messing with cache
    // // see: http://fabricjs.com/fabric-object-caching
    // var perlin_rects_group = new fabric.Group(
    //     perlin_rects, {
    //         visible: false,
    //         selectable: false,
    //         // objectCaching: false
    //     });
    // canvi.add(perlin_rects_group)
    // _elementDisplayRef.current = perlin_rects_group

    // canvi.requestRenderAll();
}
