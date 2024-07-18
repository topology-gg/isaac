export default function animatePulse(canvi, shape, scaleFactor = 0.75) {
    const originalLeft = shape.left;
    const originalTop = shape.top;
    const originalWidth = shape.width;
    const originalHeight = shape.height;
    function animate(scale) {
        shape.animate({
            scaleX: scale, scaleY: scale,
            left: originalLeft + originalWidth * 0.5 * (1 - scale),
            top: originalTop + originalHeight * 0.5 * (1 - scale),
        }, {
            duration: 500,
            onChange: canvi.requestRenderAll.bind(canvi),
            onComplete: () => scale === 1 ? animate(scaleFactor) : animate(1),
        })
    }
    animate(scaleFactor);
}
