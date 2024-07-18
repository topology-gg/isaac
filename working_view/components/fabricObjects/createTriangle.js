//
// Helper function for creating the triangles at the tips of axes
//
const createTriangle = (x, y, rotation) => {
    var width  = TRIANGLE_W;
    var height = TRIANGLE_H;
    var pos = fabric.util.rotatePoint(
        new fabric.Point(x, y),
        new fabric.Point(x + width / 2, y + height / 3 * 2),
        fabric.util.degreesToRadians(rotation)
    );
    return new fabric.Triangle(
    {
        width: width,
        height: height,
        selectable: false,
        fill: STROKE,
        stroke: STROKE,
        strokeWidth: 1,
        left: pos.x,
        top: pos.y,
        angle: rotation,
        hoverCursor: 'default'
    });
}

export default createTriangle;
