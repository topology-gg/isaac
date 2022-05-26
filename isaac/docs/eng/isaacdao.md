# IsaacDAO

### Philosophy
- Follow the CarseDAO Standard.
- Strive for simplicity and completeness.
- Explore quadratic voting dynamic.
- Embrace full forkability.

### Quantifying meaningful play
The essence of IsaacDAO is the way it quantifies meaningful play in the Isaac reality. The following rules are enforced in the current IsaacDAO design:
- when a civilization escapes before the universe max age is reached:
    - players who have launched at least once NDPE are given grade-1, and
    - players who have never launched NDPE are given grade-0;
- when a civilization survives to the universe max age, all players are given grade-0.
- if a civilization is destructed before the universe max age is reached, all players are given null grade.

According to the current Charter contract, grade-0 is mapped to 5 voices, while grade-1 is mapped to 82 voices. Null grade is mapped to 0 voices. This mechanic is regulated by the function `lookup_voices_given_play_grade()` in Charter contract `protocol/contracts/charter.cairo`.

### Quadratic voting
The current Charter contract exercises quadratic voting, which means in order to cast `X` votes, a player needs to own at least `X^2` voices. This mechanic is regulated by the function `lookup_voices_required_given_intended_votes()` in Charter contract.

### Finite state machine
The mechanics that handle the voting process are built with a minimal finite state machine with 2 states (FSM; see `protocol/contracts/fsm.cairo`): `S_IDLE` and `S_VOTE`. Each proposal type (Subject / Charter / Angel) corresponds to a dedicated FSM. When a proposal is created, FSM transitions from `S_IDLE` to `S_VOTE`; when proposal period is up, FSM transitions back from `S_VOTE` to `S_IDLE` and report voting result (how many votes for and how many votes against) back to the IsaacDAO contract. IsaacDAO implements the proposal instantly if:
1. number of votes for > number of votes against, or
2. no player voted -- to avoid the deadlock where Subject is being impossible in granting voices and needed to evolve by Angel.

Current proposal period is set to 720 testnet blocks. Given ~2min blocktime, 720 blocks correspond to ~24 hours.
