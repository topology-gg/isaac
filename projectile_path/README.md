# Projectile path plot generator

Simulated here is a projectile path under gravity, assuming g = 9.8 m/s^2. 
- A "side-view" 2-D plot is created. 
- The origin is at the lower left corner of the plot, the +x-axis is to the right, and the +y-axis is up. 


## User Inputs

Only these *integer* inputs for now:
- `num_pts` = number of points to plot along the path
- `theta_0_deg` = launch angle in degrees measured from the +x-axis: -180 <= `theta_0_deg` <= +180 degrees
- `v_0 = launch velocity magnitude: 0 <= `v_0` <= 100 (in units of m/s)

After input, `theta_0_deg` and `v_0` are scaled up to be FP (fixed point) values, and `theta_0_deg` is also converted to radians, resulting in `theta_0_fp` and `v_0_fp`. The FP scale is `SCALE_FP` = 10**20.


## Cairo files

**projectile_plot.cairo** contains:
- `projectile_plot_arr`- The view function which accepts user inputs and initiates all calculations
- ???????????????????- Other functions to calculate x coordinates, y coordinates, intensities at each position (x, y), and fill arrays for each of these

**physics.cairo** contains functions for physics calculations of: 
- ??????????????????

**math.cairo** contains math functions to use with fixed point quantities: 
- ????????????????????
- Square root, multiplication, division
- Distance between two points
- Shift any angle `theta` to equivalent angle `theta_shifted` within range -pi to pi
- Cosine approximation using Taylor series, requires -pi <= angle <= pi

**structs.cairo** contains struct definitions for: 
- ??????????????????????????

**constants.cairo** contains: 
- FP math constants
- Other math constants
- Physical parameters (except those that are user inputs)
- Plot parameters (except those that are user inputs)


## Tests

**test_projectile_plot.py**
- ????????????????????Contains input parameters which are fed into both Cairo and Python calculations
- Contains other constants and parameters (that should match those in **constants.cairo**) for Python calculations 
- Contains Python calculations of intensity array, to compare to Cairo calculations done by calling `intensity_plot_arr` function from **intensity_plot.cairo** using same input parameters
- Dumps `intensity_plot_arr` return to **test_intensity_plot.json** to be used by Jupyter notebook
- Prints for comparison the values (as FP) from the intensity arrays found with Cairo and Python
- To run: `pytest -s tests/test_intensity_plot.py`


**test_projectile_plot.ipynb**
- ?????????????????????????Jupyter notebook which plots two intensity arrays:
    - Array calculated in Cairo by **projectile_plot.cairo**
    - Array calculated in Python by **test_projectile_plot.py**
- Gets data from .json files created in **test_projectile_plot.py**
- To run:
    - Install [Jupyter Notebook](https://jupyter.org/install)
    - `jupyter notebook`, follow instructions to open notebook in browser
    - Open file **test_projectile_plot.ipynb**


## License

This repository is licensed under the MIT license.