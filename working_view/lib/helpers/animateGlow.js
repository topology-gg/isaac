export default function animateGlow(canvi, shape) {
    function animate(opacity) {
        shape.animate('opacity', opacity, {
            duration: 1000,
            onChange: canvi.renderAll.bind(canvi),
            onComplete: () => opacity === 0.7 ? animate(0.5) : animate(0.7),
        })
    }
    animate(0.7);
}
