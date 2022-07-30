import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"
import { StarknetProvider } from '@starknet-react/core'

import View from "../components/View"

function Home() {

    return (
        <StarknetProvider>
            <div className="mother-container">
                <div className="top-child-container">
                    <h2>Solve2Mint 2.0</h2>
                    <p style={{marginBottom:'0'}}>Earn your ticket to Isaac alpha.</p>
                    <p style={{marginTop:'0',marginBottom:'0'}}>Control: mouse down and drag to select path; ESC to reset</p>
                    <p style={{marginTop:'0',marginBottom:'0'}}>
                        <a href="https://github.com/topology-gg/s2m2/tree/main/contracts" style={{color:'#DDDDDD',marginRight:'0.5em'}} target="_blank" rel="noopener noreferrer">
                            Link to the source
                        </a>
                        /
                        <a href="https://goerli.voyager.online/contract/0x039d38747fb62279cb5266261b01dce9bf369b53fe422e89fcb8153891e301f9" style={{color:'#DDDDDD',marginLeft:'0.5em'}} target="_blank" rel="noopener noreferrer">
                            Link to the deployed contract
                        </a>
                    </p>

                    <span>.</span>
                    <ConnectWallet />
                    <View />
                </div>
            </div>
        </StarknetProvider>
    )
}

export default Home;