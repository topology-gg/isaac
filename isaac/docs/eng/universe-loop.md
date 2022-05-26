# Core reality loop

##### Universe termination condition
At each tick, the universe is terminable if any of following condition is satisfied:
1. The universe's **max age** is reached. Max age is specified by `UNIVERSE_MAX_AGE_IN_L2_BLOCK_NUM` in `core/contracts/design/constants.cairo`.
2. The planet is **destructed** by colliding with any of the three suns. The collision checks if the planet's coordinate lies in the radius of any sun.
3. The planet's dynamic meets the **escape condition**, which is two-fold: (1) **velocity condition** - the planet's velocity must reach or exceed escape velocity, and (2) **range condition** - denoting the center of mass of the three suns as `C`, the distance from `C` to each sun's center as `d_Ci, i=0..2`, and the distance from `C` to the planet's coordinate as `d_Cp`, `d_Cp^2` must reach or exceed `2 * max(d_Ci)^2`.

The collision condition is computed at the function `is_world_macro_destructed()` in contract `core/contracts/macro/macro_simulation.cairo`; the escape condition is computed at the function `is_world_macro_escape_condition_met()` in the same contract.

##### Forwarding procedure
The Isaac reality, consisting of the macro world and the micro world, is forwarded at every tick as follows:
1. The macro world is forwarded.
2. The micro world is forwarded.
3. The universe termination condition is checked. If terminable, the universe notifies lobby of its termination and passes ermination condition + play record, then terminates itself.