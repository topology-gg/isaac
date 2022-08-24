//
// Helper function to convert solar exposure value to face rect fill color
//
const FILL_MIN = [17, 26, 0]
const FILL_MAX = [50, 77, 0]

export default function convert_exposure_to_fill (exposure) {

    const exposure_capped = exposure > 20 ? 20 : exposure
    const ratio = exposure_capped / 20

    const R = FILL_MIN[0] + (FILL_MAX[0]-FILL_MIN[0]) * ratio
    const G = FILL_MIN[1] + (FILL_MAX[1]-FILL_MIN[1]) * ratio
    const B = FILL_MIN[2] + (FILL_MAX[2]-FILL_MIN[2]) * ratio

    return (`rgb(${R}, ${G}, ${B})`)
}
