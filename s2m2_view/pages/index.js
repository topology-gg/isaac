import styles from '../styles/Home.module.css'
import { ConnectWallet } from "../components/ConnectWallet.js"
import { StarknetProvider } from '@starknet-react/core'

import View from "../components/View"

import {
    usePuzzles
} from '../lib/api'

function Home() {

    const { data: db_puzzles } = usePuzzles ()
    var solved_count = 'loading ..'
    if (db_puzzles) {
        if (db_puzzles.puzzles) {
            var solved_count = 0
            for (const puzzle of db_puzzles.puzzles) {
                solved_count += puzzle.solved
            }
        }
    }

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
                        |
                        <a href="https://goerli.voyager.online/contract/0x039d38747fb62279cb5266261b01dce9bf369b53fe422e89fcb8153891e301f9" style={{color:'#DDDDDD',marginLeft:'0.5em',marginRight:'0.5em'}} target="_blank" rel="noopener noreferrer">
                            Link to the deployed contract
                        </a>
                        | {solved_count}/50 puzzles solved.
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