import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"
import { getInstalledInjectedConnectors, StarknetProvider } from '@starknet-react/core'

import { RegisterName } from "../components/RegisterName"
import { SnsPoll } from "../components/SnsPoll"

function Home() {

    const connectors = getInstalledInjectedConnectors()

    return (
        <StarknetProvider connectors={connectors}>
            <div className="mother-container">
                <div className="top-child-container">
                    <h1 style={{marginBottom:'1px', fontFamily:'RockSalt', fontSize:'45px'}}>StarDisc</h1>
                    <h4 style={{marginTop:'0', marginBottom:'40px'}}>Register dat Discord handle on Starknet</h4>

                    <ConnectWallet />

                    <SnsPoll />

                    <RegisterName />
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;