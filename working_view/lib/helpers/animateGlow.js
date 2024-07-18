export default function animateGlow(canvi, shape) {
    function animate(opacity) {
        shape.animate('opacity', opacity, {
            duration: 500,
            onChange: canvi.requestRenderAll.bind(canvi),
            onComplete: () => opacity === 0.8 ? animate(0.05) : animate(0.8),
        })
    }
    animate(0.8);
}
