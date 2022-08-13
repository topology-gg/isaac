import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"
import { StarknetProvider } from '@starknet-react/core'

import { RegisterName } from "../components/RegisterName"
import { SnsPoll } from "../components/SnsPoll"

function Home() {

    return (
        <StarknetProvider>
            <div className="mother-container">
                <div className="top-child-container">
                    <h1 style={{marginBottom:'1px'}}>StarDisc</h1>
                    <h4>Register dat Discord handle on Starknet</h4>
                    {/* <p style={{marginBottom:'0'}}>Register your Discord handle to coordinate better with your Isaac peers</p> */}
                    {/* <p style={{marginTop:'0',marginBottom:'0'}}>Control: mouse down and drag to select path; ESC to reset</p> */}

                    <span>.</span>
                    <span>.</span>
                    <span>.</span>

                    <ConnectWallet />

                    <SnsPoll />

                    <RegisterName />
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;