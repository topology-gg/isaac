# CarseDAO

### Foreword
This document will unabashedly make use of short sentences and paragraphs for maximum readability.

### Introduction
Ludens, from _Homo Ludens (1938)_, means to play: to live inside, to be in a state of creating tension at all times, to rejuvinate and revitalize the way one approaches the subject being played with.

In this sense, being ludens means the opposite of passively consuming content and receiving entertaining experience (or "fun" in common language); it means to tread at the boundaries of rules, to break expectations, to change norms, to break customs, to _create_.

When all of us ludens come together and play with a particular subject, we _co-create_ the subject continuously. We seek _creative_ - the state of creating - expression of ourselves.

LudensDAO strives to become a DAO standard for _P2G_ -- _play-to-govern_ -- that is purely onchain.

### Core concepts

#### LudensDAO schema
![image](https://user-images.githubusercontent.com/59590480/167301300-ff523f07-38e0-4605-947f-c478770762d2.png)
- **LudensDAO**: the Decentralized Autonomous Organization smart contract.
- **Subject**: the smart contract which Ludens play in, and which the DAO endorses and governs e.g. an onchain game / _reality_; Ludens' shares in DAO are derived directly and only from Subject, which forms the foundation of the P2G model.
- **Charter**: the smart contract which specifies the various functions and parameters involved in the governance scheme, and which the DAO honors when enforcing governance processes.
- **Ludens**: those who play in Subject and participate in DAO through submitting _reassignment proposals_ and voting on all proposals.
- **Angel**: the one who submits _development proposals_.

#### Delegated development reflecting code maintenance pattern
Recognizing the fact that development of open source code happens _offchain_ anyways, and that there is always a core maintainer of open source code repositories, LudensDAO recognizes one *Angel* at any given moment, who has the exclusive right to propose *development proposals*. Development proposals entail only two different flavors:
1. to replace the address to Charter contract which the DAO honors;
2. to replace the address to Subject contract which the DAO endorses and derives governance shares from.

This model assumes that Angel is the maintainer of code repositories for both Charter contract and Subject contract.

Note that all _Ludens_ are welcome to participate in code review and pull requests of these repositories.

#### Angel reassignment
(note: find a better word than reassignment) Ludens at all times have the right to submit a special kind of proposal called *reassignment proposal*, which entails the address to a new Angel.

#### Permissionless exit
Given the fact that there is no financial token involved in the governance model (no capital lock-in), and the fact that the entire LudensDAO contract and subject contract are fully and transparently onchain (such as on a ZK Rollup), anyone can exit by forking the entire system. The only moat any LudensDAO has would be the culture, relationship, and capability of the angel and ludens to govern and evolve its Subject.

#### P2G schema
1. The P2G schema can be succinctly summarized as: `{onchain participation} => {{shares}} => {votes}`
2. The set operator denotes a key-value map from ludens' addresses to the values of the variable i.e. `mapping address -> a'`
3. The outer set operator around `{shares}` denotes a key-value map from the "time" dimension to the address-variable map i.e. `mapping time -> (mapping address -> a')`. Including the time dimension allows one to involve time in the calculation of votes. For example, it may be desirable to implement a discounting scheme for the morphism `{{shares}} => {votes}`:
```
vote = 1 * share_{n} + γ * share_{n-1} + γ^n * share_0 ∀participant
```
where `share_{i}` denotes the number of shares at epoch `i` of the subject being governed, with `i=0` denoting the genesis epoch. Here, epoch represents the discrete unit of time; each time the LudensDAO migrates from a Subject contract to another Subject contract, the value of epoch is incremented. Reasonably, shares accumulated by each Luden in individual epoch are treated differently.


### Contract interfaces (in Cairo syntax)
#### LudensDAO
1. `@external angel_submit_development_proposal ()`
2. `@external ludens_submit_reassignment_proposal ()`
3. `@external ludens_vote_development_proposal ()`
4. `@external ludens_vote_reassignment_proposal ()`
5. `@view view_active_development_proposal ()`
6. `@view view_active_reassignment_proposal ()`
7. `@view view_subject_contract_address ()`
8. `@view view_charter_contract_address ()`
9. `@view view_angel_contract_address ()`
10. TODO: interface between LudensDAO <=> Subject

#### Subject
1. TODO: interface between Subject <=> LudensDAO

#### Charter
1. TODO: interface between Charter <=> LudensDAO
