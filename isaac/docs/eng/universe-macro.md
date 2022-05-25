# Macro simulation

### Initial condition
For the three suns, Isaac currently uses a remarkable figure-8 stable solution for three body problem of identical masses, as discovered in 2000 by Alain Chenciner and Richard Montgomery in [this paper](https://arxiv.org/abs/math/0011268).

For the planet, Isaac initialize its starting position and velocity differently across different universes (see [Parallel universe](eng/lobby-universes.md)), making each universe a unique challenge in itself.

### Numerical integrator
Isaac currently uses Runge-Kutta 4th order integrator for forwarding the dynamics of the suns and planet. Further, the gravitational pull by the planet on each of the suns is ignored. Not using symplectic method means that the three body system could maintain relatively stable trajectory in the short term and lose stability over the long term due to energy drift.

### Perturbation injection
At every tick, Isaac perturbs the planet's dynamic by adding a vector to its velocity that has a random rotation within +-15 degrees in the opposite direction of the velocity, and has a magnitude of ______ of the velocity vector. The magnitude is calculated so that with 360 ticks a day (given testnet blocktime of ~2 minutes, and 2 blocks per tick, `24 * 60 / (2*2) = 360`), the magnitude of the velocity will be discounted by ~1% per day.

These parameters are defined in the namespace `ns_perturb` in `core/design/constants.cairo`.

Note that the planet's velocity components are hashed into an entropy value used to reseed the pseudorandom number generator, which is used to determine the random rotation of the perturbation vector. Since the planet's velocity is subject to the civilization's collective actions of launching NDPEs, the long-term pseudorandomness is dependent on player activity (in the spirit of Fiat-Shamir transform), while the short-term pseudorandomness (between consecutive NDPE launches) remains perfectly and transparently deterministic.

The aim of perturbation injection discounting planet's velocity is two-fold:
1. **Breaking determinism**: by injecting perturbation vector of a random rotation that depends on player activity, long-term determinism of the reality is broken, making the constrained three-body system somewhat chaotic. Players can choose to either game the randomness (by influencing planet velocity precisely such that desirable pseudorandom numbers are produced) or optimize the NDPE launches strategically.
2. **Dramatization**: by slowing down planet's velocity, the planet falls to the sun quicker, making it impossible for idle civilization to survive.

### Impulse cache
net (aggregated) impulse vector in macro coordinate system, to be applied at the next forwarding tick.

### Macro world forwarding