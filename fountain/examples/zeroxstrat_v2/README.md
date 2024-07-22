## 0xstrat v2

### What is this?
0xstrat v2 is a proof of concept **Class A solve2mint** system based on the Fountain physics engine.

### What is solve2mint and its classification?
See [README](https://github.com/topology-gg/fountain/blob/v0.1/examples/zeroxstrat_v1/README.md#what-is-solve2mint) of 0xstrat_v1.

### What is 0xstrat v2 precisely
- 0xstrat v2 is a Class A solve2mint system that presents random physics puzzles to puzzle-solving Cairo contracts submitted by NFT minters.
- The definition of physics puzzle is same as that in 0xstrat v1.
- Call the solve2mint public-facing contract **game**, and call the puzzle-solving contract submitted by the eager minter **solver**. The interaction pattern between **game** and **solver** is as follows:
  1. **game**'s `submit_for_trial()` is called, where the input args contain the contract address of the deployed **solver**.
  2. **game** calls **solver**'s `trial()` and passes a random puzzle as input args; `trial()` returns a solution.
  3. **game** verifies the solution, and marks internally that the particular **solver** has passed the 1st trial.
  4. **game**'s `continue_trial()` is called (by the minter account, or by some keep3r mechanism such as Yagi (https://yagi.fi/), where the input args contain the address of **solver**.
  5. **game** calls **solver**'s `trial()` again, passing another random puzzle.
  6. The above process repeats until `N` trials have passed. **game** then accepts **solver** as a valid solver and mints an NFT towards an address designated by `solver`.


### Issues
1. Without a step meter, **game** can not measure the resource usage of **solver**, which is considered an important metric for evaluating **solver**'s efficiency for ranking purposes.
2. Without accessing the **solver**'s contract content, **game** cannot prevent "reentrancy attack" - the same **solver** contract can be resubmitted for scoring. This may be a hard problem, because merely having a hash value to **solver**'s compiled contract is not enough - malicious actor can mutate the contract trivially and qualify for an unique submission with essentially the exact same solver.
