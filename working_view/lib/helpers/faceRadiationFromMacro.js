import parse_phi_to_degree from "./parsePhiToDegree";
import vec2_rotate_by_degree from "./vec2RotateByDegree";

const BASE_RADIATION = 75; // from contract
const OBLIQUE_RADIATION = 15; // from contract

//
// Compute colors for each face according to (1) face number (2) distance to each suns (3) planet rotation
// following the exact way solar exposure is computed in smart contract.
//
export default function faceRadiationFromMacro(macroState) {

    // Compute distances and vectors
    const sun0_q = macroState.dynamics.sun0.q;
    const sun1_q = macroState.dynamics.sun1.q;
    const sun2_q = macroState.dynamics.sun2.q;
    const plnt_q = macroState.dynamics.planet.q;
    const phi_degree = parse_phi_to_degree(macroState.phi);
    const dist_sqs = {
        0: (sun0_q.x - plnt_q.x) ** 2 + (sun0_q.y - plnt_q.y) ** 2,
        1: (sun1_q.x - plnt_q.x) ** 2 + (sun1_q.y - plnt_q.y) ** 2,
        2: (sun2_q.x - plnt_q.x) ** 2 + (sun2_q.y - plnt_q.y) ** 2,
    };
    const vec_suns = {
        0: [sun0_q.x - plnt_q.x, sun0_q.y - plnt_q.y],
        1: [sun1_q.x - plnt_q.x, sun1_q.y - plnt_q.y],
        2: [sun2_q.x - plnt_q.x, sun1_q.y - plnt_q.y],
    };

    const normal_0 = vec2_rotate_by_degree([1, 0], -phi_degree);
    const normal_2 = vec2_rotate_by_degree(normal_0, -90);
    const normal_4 = vec2_rotate_by_degree(normal_0, -180);
    const normal_5 = vec2_rotate_by_degree(normal_0, -270);
    const normals = {
        0: normal_0,
        2: normal_2,
        4: normal_4,
        5: normal_5,
    };
    // console.log ('normals', normals)

    const faceExposures = {};

    // Compute radiation levels for top & bottom faces
    faceExposures[1] =
        OBLIQUE_RADIATION / dist_sqs[0] +
        OBLIQUE_RADIATION / dist_sqs[1] +
        OBLIQUE_RADIATION / dist_sqs[2];
    faceExposures[3] = faceExposures[1];

    // Compute radiation levels for side faces; compute fill color; draw rect
    for (const face of [0, 2, 4, 5]) {
        var exposure = 0;
        for (const sun of [0, 1, 2]) {
            const dot =
                vec_suns[sun][0] * normals[face][0] +
                vec_suns[sun][1] * normals[face][1];
            if (dot <= 0) {
                exposure += 0;
            } else {
                const mag_normal = Math.sqrt(
                    normals[face][0] ** 2 + normals[face][1] ** 2
                );
                const mag_vec_sun = Math.sqrt(
                    vec_suns[sun][0] ** 2 + vec_suns[sun][1] ** 2
                );
                const cos = dot / (mag_normal * mag_vec_sun);
                exposure += (BASE_RADIATION * cos) / dist_sqs[sun];
            }
        }
        faceExposures[face] = exposure;
    }

    return [
        faceExposures[0],
        faceExposures[1],
        faceExposures[2],
        faceExposures[3],
        faceExposures[4],
        faceExposures[5],
    ];
}
