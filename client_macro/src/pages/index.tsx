import { useStarknetCall } from '@starknet-react/core'
import type { NextPage } from 'next'
import { useMemo } from 'react'
import { toBN } from 'starknet/dist/utils/number'
import { BigNumber } from 'bignumber.js'
import { ConnectWallet } from '~/components/ConnectWallet'
import { IncrementCounter } from '~/components/IncrementCounter'
import { TransactionList } from '~/components/TransactionList'
import { useCounterContract } from '~/hooks/counter'
import {useServerContract} from '~/hooks/server'
import { useRef, useState, useEffect } from 'react'

const STARK_PRIME =      new BigNumber ('3618502788666131213697322783095070105623107215331596699973092056135872020481')
const STARK_PRIME_HALF = new BigNumber ('1809251394333065606848661391547535052811553607665798349986546028067936010240')

function fp_felt_to_string (felt : BigNumber){
  BigNumber.config({ EXPONENTIAL_AT: 76 })

  const felt_bn = new BigNumber (felt) // for weird reasons, the input `felt` may not be BigNumber, so this casting is required
  const felt_minus_half_prime = felt_bn.minus(STARK_PRIME_HALF)

  const felt_signed = felt_minus_half_prime.isPositive() ? felt_bn.minus(STARK_PRIME) : felt_bn;
  const felt_descaled = felt_signed.dividedBy(10**20)

  return felt_descaled.toString(10)
}

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
      const value = toBN(phiResult[0]) / 10**20 * (180/Math.PI);
      return value.toString(10) + ' degree'
    }
  }, [phiResult])

  const macroValues = useMemo(() => {
    if (macroResult && macroResult.length > 0) {

      console.log ('got macroResult: ', macroResult[0])

      console.log ("planet x: ", toBN(macroResult[0].plnt.q.x) / 10**20 )

      const plnt_x = fp_felt_to_string ( toBN(macroResult[0].plnt.q.x) )
      const plnt_y = fp_felt_to_string ( toBN(macroResult[0].plnt.q.y) )
      const sun0_x = fp_felt_to_string ( toBN(macroResult[0].sun0.q.x) )
      const sun0_y = fp_felt_to_string ( toBN(macroResult[0].sun0.q.y) )
      const sun1_x = fp_felt_to_string ( toBN(macroResult[0].sun1.q.x) )
      const sun1_y = fp_felt_to_string ( toBN(macroResult[0].sun1.q.y) )
      const sun2_x = fp_felt_to_string ( toBN(macroResult[0].sun2.q.x) )
      const sun2_y = fp_felt_to_string ( toBN(macroResult[0].sun2.q.y) )

      return [
        '(' + plnt_x + ', ' + plnt_y + ')',
        '(' + sun0_x + ', ' + sun0_y + ')',
        '(' + sun1_x + ', ' + sun1_y + ')',
        '(' + sun2_x + ', ' + sun2_y + ')'
      ]
    }
  }, [macroResult])

  return (
    <div>

      <h2>Isaac's trisolar system</h2>
      <p>Address: {serverContract?.address}</p>
      <p>Planet rotation: {phiValue}</p>
      <p>Planet coordinate: {macroValues?.at(0)}</p>
      <p>Sun0 coordinate:   {macroValues?.at(1)}</p>
      <p>Sun1 coordinate:   {macroValues?.at(2)}</p>
      <p>Sun2 coordinate:   {macroValues?.at(3)}</p>

    </div>
  )
}

export default Home
