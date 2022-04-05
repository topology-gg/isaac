import * as THREE from 'three'
import { extend } from '@react-three/fiber'

export default class ColorMaterial extends THREE.ShaderMaterial {
    constructor() {
        super({
            uniforms: { time: { value: 1.0 }, color: { value: new THREE.Color(0.2, 0.0, 0.1) } },
            vertexShader: `varying vec2 vUv;
      void main() {
        vUv = uv;
        gl_Position = projectionMatrix * modelViewMatrix * vec4(position, 1.0);
      }`,
            fragmentShader: `uniform float time;
      uniform vec3 color;
      varying vec2 vUv;
      void main() {
        gl_FragColor.rgba = vec4(0.2 * sin(vUv.yxy + time * 2.0) + color, 1.0);
      }`
        })
    }
    get color() {
        return this.uniforms.color.value
    }
}

extend({ ColorMaterial })
