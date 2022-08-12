export default function animateGlow(canvi, shape) {
    function animate(opacity) {
        shape.animate('opacity', opacity, {
            duration: 500,
            onChange: canvi.renderAll.bind(canvi),
            onComplete: () => opacity === 0.5 ? animate(0.1) : animate(0.5),
        })
    }
    animate(0.7);
}
