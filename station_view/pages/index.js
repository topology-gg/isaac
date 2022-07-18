import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"
import { StarknetProvider } from '@starknet-react/core'

import View from "../components/View"

function Home() {

    return (
        <StarknetProvider>
            <div className="mother-container">
                <div className="top-child-container">
                    <h1 style={{fontFamily:'Anoxic',fontSize:'4em',marginTop:'0.2em',marginBottom:'0.2em'}}>ISAAC</h1>
                    {/* <h1>ISAAC</h1> */}

                    <span>.</span>
                    <ConnectWallet />
                    <View />
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;