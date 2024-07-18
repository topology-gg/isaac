# The CarseDAO Standard

### Philosophy
We love James P. Carse's *Finite and Infinite Games*. Infinite games are played for the purpose of continuing play rather than to win and terminate play. Excluding any monetary incentive in the standard, the governance model centers around one idea: **give those who contribute meaningful play the corresponding governance right to decide how the game could evolve.** Play more, vote more, play better, vote better - this model completely banishes coin voting.

CarseDAO strives to be the standard for play-to-vote (P2V), which Topology believes will redefine open game development.


### Diagram and description
<img src="/assets/images/carsedao.png"/>

##### CarseDAO
The Decentralized Autonomous Organization contract.

##### Subject
The **immutable** contract that Players play in, and which the DAO endorses and governs e.g. an onchain game / reality; Players' votes in CarseDAO are derived directly and only from Subject's report of meaningful play, such that to vote, one has to play meaningfully. **Notice the immutability of Subject - Subject contract should never be upgradeable e.g. via proxy pattern. CarseDAO should never endorse a Subject contract that is upgradeable.**

##### Charter
The **immutable** contract that specifies the various functions (such as mapping meaningful play into new `voices`, which are then mapped to `votes` at the moment of vote casting) and parameters ((such as proposal period in terms of number of L2 blocks)) involved in the governance scheme, and which CarseDAO honors when executing governance processes. By mapping play into `voice` first before mapping to `vote` allows Charter to implement plural (e.g. quadratic; see https://www.radicalxchange.org/concepts/plural-voting/) voting schemes, whereby to cast `X` votes a Player needs `X^2` voices. **Again, notice the immutability of Charter. CarseDAO should never endorse a Charter contract that is upgradeable.**

##### Players
The accounts that play in Subject and participate in CarseDAO through spending votes on proposals, either for or against them.

##### Angel
The one account that is exclusively allowed to create proposals.


### Core features

##### Delegated development

Recognizing the fact that development of open source code happens off-chain anyways, and that there is always a core maintainer of open source code repositories, CarseDAO recognizes one Angel at any given moment, who has the exclusive right to create proposals to change Subject, Charter, or Angel itself.

This model assumes that Angel is the maintainer of offchain code repositories for both Charter contract and Subject contract. Note that:
1. All Players are welcome to participate in code review and pull requests of these repositories.
2. *Angel abstraction* is possible: with account abstraction, Angel could represent entire developer DAOs.
3. *Subject abstraction* is possible: it may be desirable for a CarseDAO to govern multiple subjects at once - for example, multiple play modes and creator modes all encompassed by a single "game title". It is possible to construct one wrapper subject contract that bundle all reporting of meaningful play into acceptable form before passing to CarseDAO.

##### Proposal minimization

There are only 3 kinds of proposals in CarseDAO:

- proposal to replace the address of Subject contract which the DAO endorses and accepts the reporting of meaningful play, which converts to `voices`;
- proposal to replace the address of Charter contract which the DAO honors;
- proposal to replace the address of Angel account.

Thus, the *payload* of any proposal is an address value, and the execution of any proposal is simply changing an address CarseDAO points to for Subject/Charter/Angel.

##### Permissionless exit

Given the fact that there is no financial incentive involved in the governance model (no capital at stake), and the fact that the entire CarseDAO contract and Subject contract are fully and transparently onchain (such as on a ZK Rollup), anyone can exit by forking the entire system. The only reliable moat any CarseDAO has would be the culture, relationship, and capability of the angel and players to govern and evolve its Subject and Charter together.

### Improvement items

##### Vote discount across Subject epochs
As the subject evolves, CarseDAO points to differernt Subjects; it may be desirable to discount votes earned in past Subject. For example, it may be advantageous to add a time dimension to `voices` to differentiate between voices earned in different epochs:

```
total effective voices = 1 * voices_{n} + γ * voices_{n-1} + γ^n * voices_0  ∀ participant
```
where `n` denotes Subject epoch, `n=0` denotes the genesis Subject for a given CarseDAO, and `0 < γ < 1`.
