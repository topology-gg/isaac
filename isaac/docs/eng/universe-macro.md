# Macro simulation

### Initial condition
For the three suns, Isaac currently uses a remarkable figure-8 stable solution for three body problem of identical masses, as discovered in 2000 by Alain Chenciner, Richard Montgomery in [this paper](https://arxiv.org/abs/math/0011268).

For the planet, Isaac initialize its starting position and velocity differently across different universes (see [Parallel universe](eng/lobby-universes.md)), making each universe a unique challenge in itself.

### Numerical integrator
Isaac currently uses Runge-Kutta 4th order integrator for forwarding the dynamics of the suns and planet. Further, the gravitational pull by the planet on each of the suns is ignored. Not using symplectic method means that the three body system could maintain relatively stable trajectory in the short term and lose stability over the long term due to energy drift.

### Perturbation injection
fiar-shamir

### Impulse cache
net (aggregated) impulse vector in macro coordinate system, to be applied at the next forwarding tick.

### Macro world forwarding