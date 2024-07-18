import math
import numpy as np
import matplotlib.pyplot as plt


def print_state (state):
    print(f'x1={state[0]}, x1d={state[1]}, y1={state[2]}, y1d={state[3]},\
            x2={state[4]}, x2d={state[5]}, y2={state[6]}, y2d={state[7]}')
    print()


def distance_from_state (state):
    x1 = state[0]
    y1 = state[2]
    x2 = state[4]
    y2 = state[6]

    return math.sqrt( (x2-x1)**2 + (y2-y1)**2 )


def evaluate_3plus1body (t, state, constants):

    G  = constants['G']
    M1 = constants['M1']
    M2 = constants['M2']
    M3 = constants['M3']
    m = constants['m']

    [x1, x1d, y1, y1d, x2, x2d, y2, y2d, x3, x3d, y3, y3d, x4, x4d, y4, y4d] = state # unpack state

    x1_diff = x1d
    y1_diff = y1d
    x2_diff = x2d
    y2_diff = y2d
    x3_diff = x3d
    y3_diff = y3d
    x4_diff = x4d
    y4_diff = y4d

    R12 = math.sqrt( (x2-x1)**2 + (y2-y1)**2 )
    R13 = math.sqrt( (x3-x1)**2 + (y3-y1)**2 )
    R23 = math.sqrt( (x2-x3)**2 + (y2-y3)**2 )

    R14 = math.sqrt( (x4-x1)**2 + (y4-y1)**2 )
    R24 = math.sqrt( (x4-x2)**2 + (y4-y2)**2 )
    R34 = math.sqrt( (x4-x3)**2 + (y4-y3)**2 )

    G_R12_3 = G / (R12**3)
    G_R13_3 = G / (R13**3)
    G_R23_3 = G / (R23**3)

    G_R14_3 = G / (R14**3)
    G_R24_3 = G / (R24**3)
    G_R34_3 = G / (R34**3)

    x1d_diff = G_R12_3 * M2 * (x2-x1) + G_R13_3 * M3 * (x3-x1)
    y1d_diff = G_R12_3 * M2 * (y2-y1) + G_R13_3 * M3 * (y3-y1)
    x2d_diff = G_R12_3 * M1 * (x1-x2) + G_R23_3 * M3 * (x3-x2)
    y2d_diff = G_R12_3 * M1 * (y1-y2) + G_R23_3 * M3 * (y3-y2)
    x3d_diff = G_R13_3 * M1 * (x1-x3) + G_R23_3 * M2 * (x2-x3)
    y3d_diff = G_R13_3 * M1 * (y1-y3) + G_R23_3 * M2 * (y2-y3)

    x4d_diff = G_R14_3 * M1 * (x1-x4) + G_R24_3 * M2 * (x2-x4) + G_R34_3 * M3 * (x3-x4)
    y4d_diff = G_R14_3 * M1 * (y1-y4) + G_R24_3 * M2 * (y2-y4) + G_R34_3 * M3 * (y3-y4)

    return np.array( [x1_diff, x1d_diff, y1_diff, y1d_diff,
                      x2_diff, x2d_diff, y2_diff, y2d_diff,
                      x3_diff, x3d_diff, y3_diff, y3d_diff,
                      x4_diff, x4d_diff, y4_diff, y4d_diff])


# reference: https://prappleizer.github.io/Tutorials/RK4/RK4_Tutorial.html
def rk4(t,dt,state,evaluate,constants):
    '''
    Given a vector state at t, calculate state at t+dt
    using rk4 method
    '''
    k1 = dt * evaluate(t, state, constants)
    k2 = dt * evaluate(t + 0.5*dt, state + 0.5*k1, constants)
    k3 = dt * evaluate(t + 0.5*dt, state + 0.5*k2, constants)
    k4 = dt * evaluate(t + dt, state + k3, constants)

    state_delta = (1/6.)*(k1+ 2*k2 + 2*k3 + k4)
    state_t_dt = state + state_delta

    #print_state(state_t_dt)

    return state_t_dt, state_delta

#
# Running a small integration
#
Q1_unit = (0.97000436, -0.24308753)
V3_unit = (-0.93240737, -0.86473146)
def run(Q4_unit, V4_unit, SCALE_V=1, SCALE_Q=1, SCALE_CONST=1, N=105, dt=0.02):
    T = N*dt

    #(SCALE_V, SCALE_Q, SCALE_CONST) = (1. , 1., 1.)
    #(SCALE_V, SCALE_Q, SCALE_CONST) = (10. , 10., 10.)
    Q1 = (Q1_unit[0]*SCALE_Q, Q1_unit[1]*SCALE_Q)
    Q4 = (Q4_unit[0]*SCALE_Q, Q4_unit[1]*SCALE_Q)
    V3 = (V3_unit[0]*SCALE_V, V3_unit[1]*SCALE_V)
    V4 = (V4_unit[0]*SCALE_V, V4_unit[1]*SCALE_V)
    constants = {
        'G'  : 1. * SCALE_CONST,
        'M1' : 1. * SCALE_CONST,
        'M2' : 1. * SCALE_CONST,
        'M3' : 1. * SCALE_CONST,
        'm' : 0.00001 * SCALE_CONST
    }

    state_0 = np.array( [Q1[0], -V3[0]/2, Q1[1], -V3[1]/2,
                         -Q1[0], -V3[0]/2, -Q1[1], -V3[1]/2,
                         0, V3[0], 0, V3[1],
                         Q4[0], V4[0], Q4[1], V4[1]] )
    history = [state_0]
    history_delta = []
    ts = [0]
    nsteps = int(T/dt)
    for i in range(nsteps):
        t = ts[-1]
        state_new, state_delta = rk4 (t, dt, history[-1], evaluate_3plus1body, constants)
        history.append(state_new)
        t += dt
        ts.append(t)
    history = np.array(history)
    ts = np.array(ts)

    print(f'x1_history = {list(history[:,0])}')
    print(f'y1_history = {list(history[:,2])}')
    print(f'x2_history = {list(history[:,4])}')
    print(f'y2_history = {list(history[:,6])}')
    print(f'x3_history = {list(history[:,8])}')
    print(f'y3_history = {list(history[:,10])}')
    print(f'x4_history = {list(history[:,12])}')
    print(f'y4_history = {list(history[:,14])}')

    fig, ax = plt.subplots(1,1,figsize=(14,8))
    ax.scatter(history[:,0], history[:,2],  color='C0', s=3)
    ax.scatter(history[:,4], history[:,6],  color='C1', s=3)
    ax.scatter(history[:,8], history[:,10], color='C2', s=3)
    ax.scatter(history[:,12], history[:,14], color='C4', s=2)
    plt.xticks(np.arange(-Q1[0], Q1[0], 2*Q1[0]/20. ));
    plt.yticks(np.arange(-Q1[1]*10, Q1[1]*5, 2*15*Q1[1]/20. ));
    plt.grid()

run (
    Q4_unit = (Q1_unit[0]/2, Q1_unit[1]/2),
    V4_unit = (V3_unit[0]/2.6, V3_unit[1]/2.6),
    SCALE_V=1.414, SCALE_Q=8, SCALE_CONST=4, N=900, dt=0.06
)
# Note: when SCALE_CONST is C^2, SCALE_Q must be C^3, and SCALE_V must be sqrt(),
#       to scale quantities correctly