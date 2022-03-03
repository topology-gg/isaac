## 0xstrat v1

### Contract addresses on alpha-goerli
- game: 0x0084c3b988a53d659ce824540c718f3dbdc195f87862bb169f53db47e254940e
- SNS: 0x02ef8e28b8d7fc96349c76a0607def71c678975dbd60508b9c343458c4758fac

### Frontend urls
- game: https://determined-lewin-dfb66b.netlify.app/
- SNS: https://sharp-babbage-4f6e05.netlify.app/

### What is this?
0xstrat v1 is the version 1 proof of concept for a **solve2mint** system based on the Fountain physics engine.

### What is solve2mint?
**solve2mint** is a framework for NFT emission where each NFT constitutes a unique solution to an equation. This framework has the following properties:
1. The scarcity of the NFT is confined by the number of solutions to the equation, which may not be known by the NFT contract creator itself when the equation is sufficiently complex or the solution space is sufficiently large.
2. Any account that submits a solution that is not yet recorded in the solve2mint contract would "own" that solution by receiving an NFT that uniquely represents that solution.
3. Structurally, solutions may be categorized into families. For any given family, once a solution is found, the rest of the solutions may be easy to map out by perturbing the first solution. Thus, it is ideal to differentiate the first solution found within a family from the rest of the solutions found subsequently in the same family.

### Classifying solve2mint systems?
- Class C. The equation can be one or a set of mathematical equations that can be solved analytically. To mint NFTs, one would simply eyeball the smart contract to extract the equation(s), solve the equation(s) using Wolfram Alpha for instance, and submit all the found solutions to the smart contract to claim all NFTs. The apparent weakness is that analytic solutions can be easily found with off the shelf solvers, which makes the solve2mint system first-come first-served and prone to  sniping. 
- Class B. The equation can be one that can not be solved analytically, only numerically. This makes the equation harder to solve, but one could still run numerical simulations exhaustively over the entire solution space, and only submit solutions to the solve2mint contract.
- Class A. The equation consists of **a random variable mapped to a family of equations**, and **the solve2mint system takes a smart contract as input which gets tested by equations supplied by the system randomly .** One submits a smart contract that gets tested by the solve2mint contract. The submitter earns an NFT iff the submitted contract pass all tests fed by the solve2mint contract. For instance, we can create a solve2mint system that can generate random polynomial equations of degree `1 <= n <= N`, where `n` is random but `N` is known, and each equation has at least one solution. The submitted contract will be fed with `M` such random polynomial equations and, to each equation, the submitted contract needs to return any valid solution, which is verified by the solve2mint contract. The construction of Class A solve2mint system thus asks an NFT minter to write smart contract that implements an algorithm that solves the family of equations defined by the solve2mint contract, which raises the bar significantly higher than constructions of Class B & C.

### What is 0xstrat v1 precisely
- 0xstrat v1 is a Class B solve2mint system that presents physics puzzles to NFT minters.
- A physics puzzle is characterized by an axis-aligned 4-wall boundary confining 1 player-controlled circle and N objective circles, viewed from top-down. There is no global acceleration at work other than dynamic friction with a constant friction coefficient. All circles are perfectly elastic, so both energy and momentum conserves in collision.
- A solution to the puzzle is defined by a 2d initial momentum vector supplied to the player-controlled circle that, after all cirlces have come to rest, has collided with at least one of N objective circles. The magnitude of the initial momentum vector `m` is limited within a defined range `R` such that `0 <= |m| <= R`.
- Given the fixed point nature of the numerical system in Fountain engine, there are finite solutions to any physics puzzle.
- To make the proof of concept minimal, `R` will be chosen such that the entire physics simulation for any legal initial momentum submitted can be completed within one transaction on StarkNet testnet, which currently imposes a 250k step limit on any single transaction.

### Will there be v2?
- Yes - 0xstrat v2 will be a Class A solve2mint system. We encourage forking and mutation of this project to explore the potential of the solve2mint concept.
