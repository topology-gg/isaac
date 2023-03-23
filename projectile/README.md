# TODO - Edit all after update to Cairo 1

# Projectile plot generator

Simulated here is a projectile path under gravity, assuming g = 9.8 m/s^2.

- A "side-view" 2-D plot of the path is created.
- The origin is at center of the plot, the +x-axis is to the right, and the +y-axis is up. Min and max values of x and y are hard coded.

## User Inputs

_Integer_ inputs:

- `num_pts` = number of points to plot along the path >=2
- `theta_0_deg` = launch angle in degrees measured from the +x-axis:
  -179 <= `theta_0_deg` <= +180 degrees
- `v_0 = launch velocity magnitude: 1 <= `v_0` (in units of m/s)

After input, `theta_0_deg` and `v_0` are scaled up to be FP (fixed point) values, and `theta_0_deg` is also converted to radians, resulting in `theta_0_fp` and `v_0_fp`. The FP scale is `SCALE_FP` = 10\*\*20.

## Cairo files

**projectile_plot.cairo** contains:

- `projectile_path`- The view function which accepts user inputs and initiates all calculations
- `position_fp_s_filler` - The function which fills an array of x-coordinates and an array of y-coordinates

**physics.cairo** contains functions for physics calculations:

- `time_in_plot_fp` - Calculates the time that the projectile is in the plot area
- `x_value_fp` - Calculates the x-coordinate of the projectile at a given time
- `y_value_fp` - Calculates the y-coordinate of the projectile at a given time

**math.cairo** contains several math functions to use with fixed point quantities:

- Square root, multiplication, division
- Distance between two points
- `cosine_6th_fp` or `cosine_8th_fp` - Taylor series approximation of cosine (to 6th order, or to 8th order), requires -pi <= angle <= pi
- `cosine_approx`
  - Increases accuracy of Taylor series approximation of cosine (above) for angles in 2nd (`theta_0_deg` > 90) or 3rd (`theta_0_deg` < -90) quadrant, by (1) moving the angle to 1st or 4th quadrant (i.e. finding the mirror image of the angle, flipped across the y-axis), then (2) calling `cosine_6th_fp` or `cosine_8th_fp`, and then (3) forcing the cosine value to be negative (as it would be back in the 2nd or 3rd quadrant).
  - If `theta_0_deg` = 90 or -90, then it assigns the exact value, 0, to the cosine (rather than approximating).
- `sine_approx` - Finds the sine of an angle, using a trig identity and the cosine of the angle.

**constants.cairo** contains:

- FP math constants
- Other math constants
- Physical parameters (except those that are user inputs)
- Plot parameters (except those that are user inputs)

## Tests

**test_projectile_plot.py**

- Contains input parameters which are fed into both Cairo and Python calculations
- Contains other constants and parameters (that should match those in **constants.cairo**) for Python calculations
- Contains Python calculations of projectile path coordinates, to compare to same Cairo calculations done by calling `projectile_path` function from **projectile_plot.cairo**, using same input parameters
- Dumps calculated values to .json files (one each for cairo and python calculations) to be used by Jupyter notebook, **test_projectile_plot.ipynb**
- Prints for comparison the values (as FP) from the coordinate arrays found with Cairo and Python
- To run: `pytest -s tests/test_projectile_plot.py`

**test_projectile_plot.ipynb**

- Jupyter notebook which plots two projectile paths:
  - Array calculated in Cairo by **projectile_plot.cairo**
  - Array calculated in Python by **test_projectile_plot.py**
- Gets data from .json files created in **test_projectile_plot.py**
- To run:
  - Install [Jupyter Notebook](https://jupyter.org/install)
  - `jupyter notebook`, follow instructions to open notebook in browser
  - Open file **test_projectile_plot.ipynb**

(An additional Jupyter notebook, **prototype_projectile_plot.ipynb**, was used to first prototype all calculations that were done in the Cairo files. The Python calculations here were then duplicated in **test_projectile_plot.ipynb**.)

## Thanks to

[Built with **`auditless/cairo-template`**](https://github.com/auditless/cairo-template)

## License

This repository is licensed under the MIT license.

## Working with the project

The Cairo template currently supports building and testing contracts.

### Build

Build the contracts.

```bash
$ make build
```

### Test

Run the tests in `src/test`:

```bash
$ make test
```

### Format

Format the Cairo source code (using Scarb):

```bash
$ make fmt
```

### Sierra (advanced)

View the compiled Sierra output of your Cairo code:

```bash
$ make sierra
```
