# Lobby contract architecture

### Connection with universes
<img src="/assets/images/lobby.png"/>

### Dispatch system
The lobby maintains a player queue. Any account can join the queue. At each tick, dispatch procedure is activated if both of the conditions below are met:
1. The queue contains at least `CIV_SIZE` number of players, where `CIV_SIZE` denotes the size of a civilization.
2. There is at least one idle universe available.

The dispatch procedure entails popping `CIV_SIZE` worth of players (account addresses) consecutively from the queue into an array, and sending the array to an idle universe.

### Universe reporting meaningful play
As an universe is terminated, it notifies the lobby and sends over an array of player addresses and grades. See the [IsaacDAO](eng/isaacdao.md) chapter for how grades are converted into voices in the DAO.

### Ticking
https://yagi.fi/
