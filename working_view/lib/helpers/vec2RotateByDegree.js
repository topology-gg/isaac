//
// Helper function to rotate 2d vector
//
export default function vec2_rotate_by_degree (vec, ang) {
    ang = -ang * (Math.PI/180);
    var cos = Math.cos(ang);
    var sin = Math.sin(ang);
    return [
        Math.round(10000*(vec[0] * cos - vec[1] * sin))/10000,
        Math.round(10000*(vec[0] * sin + vec[1] * cos))/10000
    ]
}
