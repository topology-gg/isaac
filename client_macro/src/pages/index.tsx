import { useStarknetCall } from '@starknet-react/core'
import type { NextPage } from 'next'
import { useMemo } from 'react'
import { toBN } from 'starknet/dist/utils/number'
import { BigNumber } from 'bignumber.js'
import { useServerContract } from '~/hooks/server'
import { useRef, useState, useEffect, FC } from 'react'
import { RectAreaLight } from 'three'

const STARK_PRIME = new BigNumber('3618502788666131213697322783095070105623107215331596699973092056135872020481')
const STARK_PRIME_HALF = new BigNumber('1809251394333065606848661391547535052811553607665798349986546028067936010240')
const SVG_HALF_WIDTH = 100


function getWindowDimensions() {
  if (typeof window !== 'undefined') {
    const { innerWidth: width, innerHeight: height } = window;
    console.log("window is defined!")
    return {
      width,
      height
    };
  } else {
    console.log('You are on the server')
    return {
      width:700,
      height:700
    }
  }

}

function useWindowDimensions() {
  const [windowDimensions, setWindowDimensions] = useState(getWindowDimensions());

  useEffect(() => {
    function handleResize() {
      setWindowDimensions(getWindowDimensions());
    }

    window.addEventListener('resize', handleResize);
    return () => window.removeEventListener('resize', handleResize);
  }, []);

  return windowDimensions;
}

function fp_felt_to_string(felt: BigNumber) {

  const felt_descaled = fp_felt_to_num (felt)

  return felt_descaled.toString(10)
}

function fp_felt_to_num(felt: BigNumber) {
  BigNumber.config({ EXPONENTIAL_AT: 76 })

  const felt_bn = new BigNumber(felt) // for weird reasons, the input `felt` may not be BigNumber, so this casting is required
  const felt_minus_half_prime = felt_bn.minus(STARK_PRIME_HALF)

  const felt_signed = felt_minus_half_prime.isPositive() ? felt_bn.minus(STARK_PRIME) : felt_bn;
  const felt_descaled = felt_signed.dividedBy(10 ** 20)

  return felt_descaled
}

const Sun: FC<any> = ({ x, y, colour, opacity}) => (
  <circle cx={x} cy={y} r={8} fill={colour} fillOpacity={opacity} stroke="black" strokeWidth="0.6"/>
);

const Planet: FC<any> = ({ x, y, side, colour, opacity}) => (
  <rect x={x-side/2} y={y-side/2} width={side} height={side} fill={colour} fillOpacity={opacity} stroke="black" strokeWidth="0.4"/>
);

const VerticalGridLineMajor: FC<any> = ({ x }) => (
  <line x1={x} y1={-1*SVG_HALF_WIDTH} x2={x} y2={SVG_HALF_WIDTH} stroke="white" strokeWidth="0.1" />
);
const VerticalGridLineMinor: FC<any> = ({ x }) => (
  <line x1={x} y1={-1*SVG_HALF_WIDTH} x2={x} y2={SVG_HALF_WIDTH} stroke="white" strokeWidth="0.03" />
);

const HorizontalGridLineMajor: FC<any> = ({ y }) => (
  <line x1={-2*SVG_HALF_WIDTH} y1={y} x2={2*SVG_HALF_WIDTH} y2={y} stroke="white" strokeWidth="0.1" />
);

const HorizontalGridLineMinor: FC<any> = ({ y }) => (
  <line x1={-2*SVG_HALF_WIDTH} y1={y} x2={2*SVG_HALF_WIDTH} y2={y} stroke="white" strokeWidth="0.03" />
);

const VelocityArrow: FC<any> = ({ arr }) => (
  <line x1={arr[0]} y1={arr[1]} x2={arr[2]} y2={arr[3]} stroke="#999999" strokeWidth="0.5" strokeOpacity="0.8" markerEnd="url(#arrow)"/>
);


const Home: NextPage = () => {
  // const { contract: counter } = useCounterContract()
  const { contract: serverContract } = useServerContract()

  const { data: phiResult } = useStarknetCall({
    contract: serverContract,
    method: 'view_phi_curr',
    args: [],
  })

  const { data: macroResult } = useStarknetCall({
    contract: serverContract,
    method: 'view_macro_state_curr',
    args: [],
  })

  const phiValue = useMemo(() => {
    if (phiResult && phiResult.length > 0) {
      const value = new BigNumber(phiResult[0]).dividedBy(10 ** 20 * (180 / Math.PI)).plus(15); // remove plus(15)
      return value.toString(10)
    }
  }, [phiResult])

  const macroValues = useMemo(() => {
    if (macroResult && macroResult.length > 0) {

      // console.log('got macroResult: ', macroResult[0])

      // console.log("planet x: ", new BigNumber(macroResult[0].plnt.q.x).dividedBy(10 ** 20).toString(10))

      const plnt_x = fp_felt_to_num(new BigNumber(macroResult[0].plnt.q.x))
      const plnt_y = fp_felt_to_num(new BigNumber(macroResult[0].plnt.q.y))
      const sun0_x = fp_felt_to_num(new BigNumber(macroResult[0].sun0.q.x))
      const sun0_y = fp_felt_to_num(new BigNumber(macroResult[0].sun0.q.y))
      const sun1_x = fp_felt_to_num(new BigNumber(macroResult[0].sun1.q.x))
      const sun1_y = fp_felt_to_num(new BigNumber(macroResult[0].sun1.q.y))
      const sun2_x = fp_felt_to_num(new BigNumber(macroResult[0].sun2.q.x))
      const sun2_y = fp_felt_to_num(new BigNumber(macroResult[0].sun2.q.y))

      console.log("sun0_x", sun0_x.toString(10))
      console.log("sun0_y", sun0_y.toString(10))

      const VEL_MULT = 10
      const plnt_vx_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].plnt.qd.x)).multipliedBy(VEL_MULT)
      const plnt_vy_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].plnt.qd.y)).multipliedBy(VEL_MULT)
      const sun0_vx_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].sun0.qd.x)).multipliedBy(VEL_MULT)
      const sun0_vy_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].sun0.qd.y)).multipliedBy(VEL_MULT)
      const sun1_vx_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].sun1.qd.x)).multipliedBy(VEL_MULT)
      const sun1_vy_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].sun1.qd.y)).multipliedBy(VEL_MULT)
      const sun2_vx_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].sun2.qd.x)).multipliedBy(VEL_MULT)
      const sun2_vy_raw_scaled = fp_felt_to_num(new BigNumber (macroResult[0].sun2.qd.y)).multipliedBy(VEL_MULT)

      console.log("sun0_vx_raw_scaled", sun0_vx_raw_scaled.toString(10))
      console.log("sun0_vy_raw_scaled", sun0_vy_raw_scaled.toString(10))
      // console.log("sun1_vx_raw_scaled", sun1_vx_raw_scaled.toString(10))
      // console.log("sun1_vy_raw_scaled", sun1_vy_raw_scaled.toString(10))
      // console.log("sun2_vx_raw_scaled", sun2_vx_raw_scaled.toString(10))
      // console.log("sun2_vy_raw_scaled", sun2_vy_raw_scaled.toString(10))

      const plnt_x_plus_vx_str = plnt_vx_raw_scaled?.plus(plnt_x).toString(10)
      const plnt_y_plus_vy_str = plnt_vy_raw_scaled?.plus(plnt_y).toString(10)
      const sun0_x_plus_vx_str = sun0_vx_raw_scaled?.plus(sun0_x).toString(10)
      const sun0_y_plus_vy_str = sun0_vy_raw_scaled?.plus(sun0_y).toString(10)
      const sun1_x_plus_vx_str = sun1_vx_raw_scaled?.plus(sun1_x).toString(10)
      const sun1_y_plus_vy_str = sun1_vy_raw_scaled?.plus(sun1_y).toString(10)
      const sun2_x_plus_vx_str = sun2_vx_raw_scaled?.plus(sun2_x).toString(10)
      const sun2_y_plus_vy_str = sun2_vy_raw_scaled?.plus(sun2_y).toString(10)

      const ret = [
        [ plnt_x.toString(10), plnt_y.toString(10), sun0_x.toString(10), sun0_y.toString(10), sun1_x.toString(10), sun1_y.toString(10), sun2_x.toString(10), sun2_y.toString(10) ],
        [ plnt_x_plus_vx_str, plnt_y_plus_vy_str, sun0_x_plus_vx_str, sun0_y_plus_vy_str, sun1_x_plus_vx_str, sun1_y_plus_vy_str, sun2_x_plus_vx_str, sun2_y_plus_vy_str ]
      ]
      console.log("macroValues:", ret)

      return ret
    }
  }, [macroResult])

  const plnt_vel = [
    macroValues?.[0][0],
    macroValues?.[0][1],
    macroValues?.[1][0],
    macroValues?.[1][1]
  ]

  const sun0_vel = [
    macroValues?.[0][2],
    macroValues?.[0][3],
    macroValues?.[1][2],
    macroValues?.[1][3]
  ]

  const sun1_vel = [
    macroValues?.[0][4],
    macroValues?.[0][5],
    macroValues?.[1][4],
    macroValues?.[1][5]
  ]

  const sun2_vel = [
    macroValues?.[0][6],
    macroValues?.[0][7],
    macroValues?.[1][6],
    macroValues?.[1][7]
  ]

  const planet_transform_str = `rotate(${phiValue} ${macroValues?.[0][0]} ${macroValues?.[0][1]})`

  const sun1_color = "rgba(244,168,129,255)"
  const sun2_color = "rgba(243,131,128,255)"
  const sun3_color = "rgba(242,64,99,255)"
  const plnt_color = "rgba(248,216,218,255)"

  const {height : window_height, width : window_width} = useWindowDimensions ()

  let svg_style = {
    width : "100%",
    height : window_height - 15,
    backgroundColor: "rgba(62,52,90,255)"
  }

  return (
    <svg viewBox="-100 -100 200 200" style={svg_style}>
      <defs>
        <marker id="arrow" viewBox="0 0 10 10" refX="5" refY="5"
            markerWidth="5" markerHeight="5"
            orient="auto-start-reverse" fill="#999999">
          <path d="M 0 0 L 10 5 L 0 10 z" />
        </marker>
      </defs>

      <VerticalGridLineMajor x={0} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*0.25} />
      <VerticalGridLineMajor x={SVG_HALF_WIDTH*0.5} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*0.75} />
      <VerticalGridLineMajor x={SVG_HALF_WIDTH} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*1.25} />
      <VerticalGridLineMajor x={SVG_HALF_WIDTH*1.5} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*1.75} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*-0.25} />
      <VerticalGridLineMajor x={SVG_HALF_WIDTH*-0.5} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*-0.75} />
      <VerticalGridLineMajor x={SVG_HALF_WIDTH*-1} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*-1.25} />
      <VerticalGridLineMajor x={SVG_HALF_WIDTH*-1.5} />
      <VerticalGridLineMinor x={SVG_HALF_WIDTH*-1.75} />

      <HorizontalGridLineMajor y={0} />
      <HorizontalGridLineMinor y={SVG_HALF_WIDTH*0.25} />
      <HorizontalGridLineMajor y={SVG_HALF_WIDTH*0.5} />
      <HorizontalGridLineMinor y={SVG_HALF_WIDTH*0.75} />
      <HorizontalGridLineMajor y={SVG_HALF_WIDTH} />

      <HorizontalGridLineMinor y={SVG_HALF_WIDTH*-0.25} />
      <HorizontalGridLineMajor y={SVG_HALF_WIDTH*-0.5} />
      <HorizontalGridLineMinor y={SVG_HALF_WIDTH*-0.75} />
      <HorizontalGridLineMajor y={SVG_HALF_WIDTH*-1} />


      {/* velocity vectors */}
      <VelocityArrow arr={plnt_vel}/>
      <VelocityArrow arr={sun0_vel}/>
      <VelocityArrow arr={sun1_vel}/>
      <VelocityArrow arr={sun2_vel}/>

      {/* positions */}
      <g transform = {planet_transform_str}>
        <Planet x={macroValues?.[0][0]} y={macroValues?.[0][1]} side={2} colour={plnt_color} opacity={0.8}/>
      </g>
      <Sun x={macroValues?.[0][2]} y={macroValues?.[0][3]} colour={sun1_color} opacity={0.8}/>
      <Sun x={macroValues?.[0][4]} y={macroValues?.[0][5]} colour={sun2_color} opacity={0.8}/>
      <Sun x={macroValues?.[0][6]} y={macroValues?.[0][7]} colour={sun3_color} opacity={0.8}/>

    </svg>
  )
}

export default Home
