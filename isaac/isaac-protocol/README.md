# Isaac Protocol

### Introduction
Isaac Protocol represents an experiment for both governance minimization and Open Game Development directly on the blockchain. Following the spirit of Solve2Mint (S2M; https://www.guiltygyoza.xyz/2022/02/solve2mint; https://solve2mint.netlify.app/), Isaac Protocol experiments with the concept of Play2Govern (P2G). P2G is a governance framework that distributes governance right to those who contribute the most in playing an onchain game. P2G is one of the implications of running a game, or a *reality*, fully onchain, such that quantitative metrics can be derived directly from onchain participation activity; the derivation (or more formally, `function : onchain-activity -> governance right`) is encoded transparently in smart contract and enforced autonomously with the security guarantees of the host blockchain and rollup, strengthening the credible neutrality of the governance protocol.

Decentralized Autonomous Organization is a fascinating concept, yet we recognize that most DAOs are not quite autonomous. The design of Isaac Protocol will strive for governance minimization in order to maximize the autonomy of itself.

Open Game Development has proven extremely difficult. Recognizing the strength of the blockchain as a coordination engine, it is intriguing to design robust processes and modular primitives that could coordinate such intense and multi-faceted activity as game creation on the blockchain, leveraging the fact that the game itself is fully onchain.

### Tenets
1. Minimize governance
2. Simplicity leads to robustness, accessibility and inclusivity
3. Modularity, which eases evolution of individual components of the protocol

### Core Functions
The core schema of P2G is as follows:
```
onchain participation => governance right
```

### Adversarial considerations
*Server clone attack*:
given a group of experienced players who have high probability of winning an Isaac instance, if Isaac Protocol allows permissionless and dynamic instance deployment, the group may prompt the Protocol to deploy N instances at the same time, and copy all actions performed on one instance to the other N-1 instances (i.e. copy-trade), therefore amplifying their governance right distribution when the instance is won, assuming determinism for each instance (same actions => same outcome). Pontential solutions:

(1) Setting upper limit of instance count recognized by the Protocol;

(2) Allowing permissionless instance deployment, but extendeing Fiat-Shamir to Protocol level i.e. randomness injected to the forwarding of each instance is derived from *all* player actions associated with the Protocol. This solution needs to consider (2-1) *gas limit attack* i.e. maliciously launching many instances to increase the complexity of deriving randomness, making other instances unplayable. (2-2) randomness needs to be non-negligible to make copy-actions invalid, which ties the design of numerical system directly with protocol security. Not ideal. (2-3) this requires CREATE2 for starknet-cairo, which is not available yet by May 2022.

(3) Variation in initial condition across Isaac instances, which seems to be robust, but not implemented at origin due to potential unfairness in difficulty variance across instances; we need a quantitative measure for difficulty to constraint the procedure of generating initial condition. Note that this feature is orthogonal to whether or not instance can be dynamically and permissionlessly deployed.

Taking all above into consideration, Isaac Protocol adopts solution (1) at its origin, with static initial condition setup.
