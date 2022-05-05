# Isaac Protocol

### Introduction
Isaac Protocol represents an experiment for both governance minimization and Open Game Development directly on the blockchain. Following the spirit of Solve2Mint (S2M; https://www.guiltygyoza.xyz/2022/02/solve2mint; https://solve2mint.netlify.app/), Isaac Protocol experiments with the concept of Play2Govern (P2G). P2G is a governance framework that distributes governance right to those who contribute the most in playing an onchain game. P2G is one of the implications of running a game, or a *reality*, fully onchain, such that quantitative metrics can be derived directly from onchain participation activity; the derivation (or more formally, `function : onchain-activity -> governance right`) is encoded transparently in smart contract and enforced autonomously with the security guarantees of the host blockchain and rollup, strengthening the credible neutrality of the governance protocol.

Decentralized Autonomous Organization is a fascinating concept, yet we recognize that most DAOs to date are not quite autonomous. The design of Isaac Protocol will strive for governance minimization in order to enable robust autonomy of the Isaac DAO.

Open Game Development has proven extremely difficult. Recognizing the strength of the blockchain as a coordination engine, it is intriguing to design robust processes and modular primitives that could coordinate such intense and multi-faceted activity as game creation on the blockchain, leveraging the fact that the game itself is fully onchain.


### Tenets
1. Minimize governance
2. Simplicity leads to robustness, accessibility and inclusivity
3. Modularity, which eases evolution of individual components of the protocol


### Evolution of the governance schema
#### Core schema
The core schema of P2G is as follows:
```
{onchain participation} => {governance right in collective decision making} .. schema 1
```
where the set operator (`{}`) denotes the set of unique participant involved (i.e. `mapping address -> a'`), identified only by address - until we have decentralized identity systems at our disposal. Notice that financial contribution is *not* involved in the schema, for better or worse. Given the utter lack of governance models that does not use coin-voting, and for the sake of blazing the trail, let us keep financial contribution completely irrelevant in this experimental protocol.

#### Voting methods
Recognizing the opportunity of experimenting with various voting methods e.g. quadratic voting, let us decouple governance share representation from vote representation:
```
{onchain participation} => {share} => {vote} .. schema 2
```
where we have a morphism that transforms onchain participation (quantified, based on a particular _measure_) into numbers of shares, and a separate morphism that transforms numbers of shares into numbers of votes.

#### Time dimensionality
Recognizing the value of *discounting past participation* to prevent dead equity, as well as the discontinuity in the subject being governed going through upgrades, let us add the dimensionality of time into `share`:
```
{onchain participation} => {{share}} => {vote} .. schema 3
```
where an outer set operator is added to `{share}` to denote the unique timestamp / epoch assocated with each `{share}` (i.e. `mapping timestamp/epoch -> (mapping address -> a'))`. With this additional dimension, the morphism that transforms numbers of shares into numbers of votes can treat shares earned in different "epoch" of the subject being governed differentially. One example is to implement some discount factor `0 < γ < 1` such that
```
vote = 1 * share_{n} + γ * share_{n-1} + γ^n * share_0 ∀participant
```
where `share_{i}` denotes the number of shares at epoch `i` of the subject being governed, with `i=0` denoting the genesis epoch.


#### Benevolent dictator - special share
Recognizing the benefit for giving the creator dominant share in the infancy stage of the subject being governed, let us add a special kind of share exclusive to the creator:
```
{onchain participation} => {{share}} => {vote} .. schema 4
                      |                  ∧
                      --> creator share  |
```
Notice the difference between thick arrow (`=>`) and thin arrow (`->`). Thick arrows denote morphisms that are mutable via governance, while thin arrows denote morphisms that are immutable with the protocol. This design is in the spirit of governance minimization: minimizing the number of moving parts in the system while maintaining its degrees of freedom. Schema 4 is the schema employed by Isaac Protocol and implemented as part of Isaac DAO.

#### Minimally enforceable decision reached through voting
To retain autonomy of the governance model, let us constrain the decision to be enforceable by the protocol contract alone: decision to point towards a particular contract address endorsed by the DAO to fulfill certain functionality for the protocol.

In particular, Isaac DAO has *three* votable decisions, each corresponding to a contract address:
1. contract address of the current Isaac Epoch contract.
2. contract address of the contract that exposes a *pure* function that implements the morphism `{onchain participation} => {{share}}`
3. contract address of the contract that exposes a *pure* function that implements the morphism `{{share}} => {vote}`


### Protocol system diagram
![image](https://user-images.githubusercontent.com/59590480/166982252-494fbe4e-648f-491d-a2a8-2bc4653c30af.png)


### Adversarial considerations
#### Server clone attack
given a group of experienced players who have high probability of winning an Isaac instance, if Isaac Protocol allows permissionless and dynamic instance deployment, the group may prompt the Protocol to deploy N instances at the same time, and copy all actions performed on one instance to the other N-1 instances (i.e. copy-trade), therefore amplifying their governance right distribution when the instance is won, assuming determinism for each instance (same actions => same outcome). Pontential solutions:

(1) Setting upper limit of instance count recognized by the Protocol;

(2) Allowing permissionless instance deployment, but extendeing Fiat-Shamir to Protocol level i.e. randomness injected to the forwarding of each instance is derived from *all* player actions associated with the Protocol. This solution needs to consider (2-1) *gas limit attack* i.e. maliciously launching many instances to increase the complexity of deriving randomness, making other instances unplayable. (2-2) randomness needs to be non-negligible to make copy-actions invalid, which ties the design of numerical system directly with protocol security. Not ideal. (2-3) this requires CREATE2 for starknet-cairo, which is not available yet by May 2022.

(3) Variation in initial condition across Isaac instances, which seems to be robust, but not implemented at origin due to potential unfairness in difficulty variance across instances; we need a quantitative measure for difficulty to constraint the procedure of generating initial condition. Note that this feature is orthogonal to whether or not instance can be dynamically and permissionlessly deployed.

Taking all above into consideration, Isaac Protocol adopts solution (1) at its origin, with static initial condition setup.

#### Denial of participation attack
without proper mitigation strategy employed by the matchmaking component, a malicious player could queue with a large amount of sybil addresses, boosting its probability of getting assigned into servers, which are assumed to be of limited quantity. The malicious player then stays idle throughout the entire game until it terminates (based on timer or some condition such as civilization destruction). By doing this the malicious player denies other players from participating in the game.

