from re import S
import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
import numpy as np
import json

#################################################
# Input parameters
#
# Number of points to plot
num_pts = 20

# Launch angle in degrees: -179 <= theta_0_deg <= +180
theta_0_deg = 105

# Launch velocity magnitude: v_0 >=1
# note that v_0 = ~100 is enough to reach top of plot area on vertical shot if y_max = ~500
v_0 = 100


#################################################
# Equivalent to constants.cairo contract
#
# Fixed point math constants
SCALE_FP = 10**20
SCALE_FP_SQRT = 10**10
RANGE_CHECK_BOUND = 2**120

# Constants for felts
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
HALF_PRIME = (
    1809251394333065606848661391547535052811553607665798349986546028067936010240
)

#
# Math constants
#
# Number of terms in cosine Taylor series approximation
n = 5
# Fixed point values
PI_fp = 3141592654 * SCALE_FP / 1000000000
HALF_PI_fp = 1570796327 * SCALE_FP / 1000000000
# Non fixed point values
PI = PI_fp / SCALE_FP
HALF_PI = HALF_PI_fp / SCALE_FP

#
# Physical parameters
#
# Gravitational acceleration in m/s^2
g = 9.8
# Initial position
x_0 = 0
y_0 = 0

#
# Plot parameters
#
# Min and max values for axes
x_max = 1000
x_min = -x_max
y_max = 500
y_min = -y_max


#################################################
# Math functions
# Equivalent to part of math.cairo contract
#

# Cosine from Taylor series approximation
#   Assume -pi <= theta <= +pi, so no need to shift theta
#   Accuracy is improved if instead -pi/2 <= theta <= +pi/2
def cosine_n_terms(theta, n):
    # n = number of terms (not order)
    # 2(n-1) = order
    # cosine(theta) ~= ((-1)^n)*(theta^(2n))/(2n)!
    #               ~= 1 - theta^2/2! + theta^4/4! - theta^6/6! + ...
    cos_nth = 0

    for i in range(n):
        power_neg_one = (-1) ** i
        power_theta = theta ** (2 * i)
        fact = np.math.factorial(2 * i)
        cos_nth += power_neg_one * power_theta / fact
    return cos_nth


# Cosine approximation:
#   Taylor series approximation is more accurate if -pi/2 <= theta_0 <= +pi/2. So:
#   If theta_0 is in 2nd/3rd quadrant:
#     (1) move angle to 1st/4th quadrant for cosine approximation
#     (2) force negative sign for cosine(theta_0)
#   (Use theta_0_deg for comparisons because calculated theta_0 in radians is slightly rounded)
#   Then call cosine_n_terms
def cosine_approx(theta_0, theta_0_deg, PI, n):
    if theta_0_deg >= 90:
        if theta_0_deg == 90:
            # If 90 degrees, use exact value of cos_theta_0
            cos_theta_0 = 0
        else:
            # If in 2nd quadrant, move to 1st, but force cos_theta_0 to be negative:
            theta_0 = PI - theta_0
            cos_theta_0 = -cosine_n_terms(theta_0, n)
    else:
        if theta_0_deg <= -90:
            if theta_0_deg == -90:
                # If -90 degrees, use exact value of cos_theta_0
                cos_theta_0 = 0
            else:
                # If in 3rd quadrant, move to 4th, but force cos_theta_0 to be negative:
                theta_0 = -PI - theta_0
                cos_theta_0 = -cosine_n_terms(theta_0, n)

        else:
            # If in 1st or 4th quadrant, all is good
            cos_theta_0 = cosine_n_terms(theta_0, n)

    return cos_theta_0


# Sine approximation: need to force correct signs
def sine_approx(theta_0, cos_theta_0):
    if theta_0 >= 0:
        # If theta_0 >= 0, then sin_theta_0 >= 0
        sin_theta_0 = (1 - cos_theta_0**2) ** 0.5
    else:
        # If theta_0 < 0, then sin_theta_0 < 0
        sin_theta_0 = -((1 - cos_theta_0**2) ** 0.5)

    return sin_theta_0


#################################################
# Physics functions
# Equivalent to physics.cairo contract
#

# Time of projectile in plot area
def time_in_plot(theta_0_deg, x_0, y_0, x_min, x_max, y_min, v_0x, v_0y, g):

    # Max time needed for y-direction
    t_max_y = (v_0y + (v_0y**2 - 2 * g * (y_min - y_0)) ** 0.5) / g

    #
    # Find max time needed for x_direction, t_max_x
    # Then t_max is minimum of t_max_x and t_max_y
    #
    # Check if abs(theta_0_deg) <, =, or > 90 degrees
    #   (Use theta_0_deg because calculated theta_0 in radians is slightly rounded)
    # Then find t_max_x, and then t_max
    if abs(theta_0_deg) <= 90:
        if abs(theta_0_deg) == 90:
            # abs(theta_0_deg) = 90, so v_0x = 0, so t_max_x = infinite, so
            t_max = t_max_y

        else:
            # abs(theta_0_deg) < 90, so v_0x > 0, so projectile moves toward x_max
            t_max_x = (x_max - x_0) / v_0x
            t_max = min(t_max_x, t_max_y)

    else:
        # abs(theta_0_deg) > 90, so v_0x < 0, so projectile moves toward x_min
        t_max_x = (x_min - x_0) / v_0x
        t_max = min(t_max_x, t_max_y)

    return t_max


# Horizontal position
def x_value(x_0, v_0x, t):
    x = x_0 + v_0x * t
    return x


# Vertical position
def y_value(y_0, v_0y, g, t):
    y = y_0 + v_0y * t - 0.5 * g * t**2
    return y


#################################################
# Projectile calculations
# Equivalent to projectile_plot.cairo contract
#
def projectile_path(num_pts, theta_0_deg, v_0):

    # Convert launch angle to radians
    theta_0 = theta_0_deg * PI / 180

    # Trig function approximations
    #   Don't use cos_theta_0 = cosine_n_terms(theta_0, n),
    #   because results are bad near PI radians
    cos_theta_0 = cosine_approx(theta_0, theta_0_deg, PI, n)
    sin_theta_0 = sine_approx(theta_0, cos_theta_0)

    # Initial velocity vector components
    v_0x = v_0 * cos_theta_0
    v_0y = v_0 * sin_theta_0

    # Total time projectile remains in plot area
    t_max = time_in_plot(theta_0_deg, x_0, y_0, x_min, x_max, y_min, v_0x, v_0y, g)

    # Time values array, evenly spaced
    t_s = np.linspace(0, t_max, num_pts)

    # Horizontal positions array
    x_s = x_value(x_0, v_0x, t_s)

    # Vertical positions array
    y_s = y_value(y_0, v_0y, g, t_s)

    return (x_s, y_s)


#################################################
# Pytest
#

# The path to the contract source code.
CONTRACT_FILE = os.path.join("contracts", "projectile_plot.cairo")


@pytest.mark.asyncio
async def test():

    starknet = await Starknet.empty()
    contract = await starknet.deploy(
        source=CONTRACT_FILE,
    )
    print()  # print blank line

    # Cairo: position coordinate arrays
    ret = await contract.projectile_path(num_pts, theta_0_deg, v_0).call()
    # dump to json file
    with open("tests/test_projectile_plot_cairo.json", "w") as outfile:
        json.dump(ret.result, outfile)

    # Python: position coordinate arrays as a tuple
    coordinate_s = projectile_path(num_pts, theta_0_deg, v_0)
    coordinate_s_as_list = [coordinate_s[0].tolist(), coordinate_s[1].tolist()]
    # dump to a different json file
    with open("tests/test_projectile_plot_python.json", "w") as outfile:
        json.dump(coordinate_s_as_list, outfile)

    print(
        f"> path for (num_pts={num_pts}, theta_0_deg={theta_0_deg}, v_0={v_0}) returns:"
    )
    print()
    print(f"> array      coordinates")
    print(
        f"> member     cairo x            python x*SCALE_FP            cairo y            python y*SCALE_FP"
    )

    # Print array members one line at a time:
    for p in range(0, num_pts):

        if ret.result[0][p] <= HALF_PRIME:
            x_coordinate_ca = ret.result[0][p]
        else:
            x_coordinate_ca = ret.result[0][p] - PRIME

        if ret.result[1][p] <= HALF_PRIME:
            y_coordinate_ca = ret.result[1][p]
        else:
            y_coordinate_ca = ret.result[1][p] - PRIME

        x_coordinate_py = int(SCALE_FP * coordinate_s[0][p])
        y_coordinate_py = int(SCALE_FP * coordinate_s[1][p])

        print(
            f"> {p} {x_coordinate_ca} {x_coordinate_py} {y_coordinate_ca} {y_coordinate_py}"
        )

    # print ret.call_info.execution_resources to get n_steps
    print()
    print(ret.call_info.execution_resources)
