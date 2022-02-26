import math

FP = 10**12
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2

def adjust (felt):
    if felt > PRIME_HALF:
        return (felt - PRIME)/FP
    else:
        return felt/FP


def check_against_err_tol (x_hat, x, err_tol):
    assert abs(x_hat-x) <= err_tol, f"abs({x_hat} - {x}) is greater than error tolerance {err_tol}"


def euler_single_step (dt, state, params):
    #
    # Unpack params
    #
    x_min = params['x_min'] + params['r']
    x_max = params['x_max'] - params['r']
    y_min = params['y_min'] + params['r']
    y_max = params['y_max'] - params['r']

    #
    # Calculate candidate x,y by euler forwarding
    #
    x_cand = state['x'] + state['vx']*dt
    y_cand = state['y'] + state['vy']*dt

    #
    # Determine collision with boundary; finalize x,y;
    # calculate candidate vx, vy
    #
    collided = False
    if x_cand < x_min:
        x_nxt = x_min
        vx_cand = -state['vx']
        collided = True
    elif x_cand > x_max:
        x_nxt = x_max
        vx_cand = -state['vx']
        collided = True
    else:
        x_nxt = x_cand
        vx_cand = state['vx']

    if y_cand < y_min:
        y_nxt = y_min
        vy_cand = -state['vy']
        collided = True
    elif y_cand > y_max:
        y_nxt = y_max
        vy_cand = -state['vy']
        collided = True
    else:
        y_nxt = y_cand
        vy_cand = state['vy']

    #
    # Determine if stopping; finalizing vx, vy
    #
    x_stopped = abs(vx_cand) < abs(state['ax']*dt)
    y_stopped = abs(vy_cand) < abs(state['ay']*dt)

    vx_nxt = 0 if x_stopped else vx_cand + state['ax']*dt
    vy_nxt = 0 if y_stopped else vy_cand + state['ay']*dt

    state_nxt = {
        'x' : x_nxt,
        'y' : y_nxt,
        'vx' : vx_nxt,
        'vy' : vy_nxt,
        'ax' : state['ax'],
        'ay' : state['ay']
    }

    return state_nxt, collided


def collision_pair_circles (state1, state2, state1_cand, state2_cand, r1, r2):

    d_cand_sq = (state1_cand['x']-state2_cand['x'])**2 + (state1_cand['y']-state2_cand['y'])**2
    collided = d_cand_sq <= (r1+r2)**2 # is less than or equal to

    if not collided:
        state1_nxt = state1_cand
        state2_nxt = state2_cand
    else:
        # print('colliding:')
        # print(f'state1_cand = {state1_cand}')
        # print(f'state2_cand = {state2_cand}')
        # print()

        d_cand = math.sqrt(d_cand_sq)
        d = math.sqrt( (state1['x']-state2['x'])**2 + (state1['y']-state2['y'])**2 )
        nom = r1 + r2 - d_cand
        denom = d - d_cand

        x1_subtract = nom*(state1_cand['x']-state1['x'])/denom
        x1_nxt = state1_cand['x'] - x1_subtract

        y1_subtract = nom*(state1_cand['y']-state1['y'])/denom
        y1_nxt = state1_cand['y'] - y1_subtract

        x2_subtract = nom*(state2_cand['x']-state2['x'])/denom
        x2_nxt = state2_cand['x'] - x2_subtract

        y2_subtract = nom*(state2_cand['y']-state2['y'])/denom
        y2_nxt = state2_cand['y'] - y2_subtract

        # Vector form (source: https://en.wikipedia.org/wiki/Elastic_collision):
        #   alpha = ( (vx2-vx1, vy2-vy1) dot (x2_nxt-x1_nxt, y2_nxt-y1_nxt) ) / (r2_nxt-r1_nxt)^2
        #   (vx1_nxt, vy1_nxt) = (vx1, vy1) - alpha*(x1_nxt-x2_nxt, y1_nxt-y2_nxt)
        #   (vx2_nxt, vy2_nxt) = (vx2, vy2) - alpha*(x2_nxt-x1_nxt, y2_nxt-y1_nxt)
        vx1 = state1['vx']
        vy1 = state1['vy']
        vx2 = state2['vx']
        vy2 = state2['vy']
        alpha = ( (vx2-vx1)*(x2_nxt-x1_nxt) + (vy2-vy1)*(y2_nxt-y1_nxt) ) / ( (x2_nxt-x1_nxt)**2 + (y2_nxt-y1_nxt)**2 )
        vx1_nxt = vx1 - alpha*(x1_nxt-x2_nxt)
        vy1_nxt = vy1 - alpha*(y1_nxt-y2_nxt)
        vx2_nxt = vx2 - alpha*(x2_nxt-x1_nxt)
        vy2_nxt = vy2 - alpha*(y2_nxt-y1_nxt)

        state1_nxt = {'x':x1_nxt, 'y':y1_nxt, 'vx':vx1_nxt, 'vy':vy1_nxt, 'ax':state1['ax'], 'ay':state1['ay']}
        state2_nxt = {'x':x2_nxt, 'y':y2_nxt, 'vx':vx2_nxt, 'vy':vy2_nxt, 'ax':state2['ax'], 'ay':state2['ay']}

    return state1_nxt, state2_nxt, collided


def friction_single_circle (dt, state, should_recalc, a_friction):

    if not should_recalc:
        if state['vx'] == 0:
            ax_nxt = 0
        else:
            ax_nxt = state['ax']

        if state['vy'] == 0:
            ay_nxt = 0
        else:
            ay_nxt = state['ay']

        # ax_dt = state['ax']*dt
        # ax_dt_abs = abs(ax_dt)
        # vx_abs = abs(state['vx'])
        # bool_x_stopped = vx_abs < ax_dt_abs
        # if bool_x_stopped:
        #     ax_nxt = 0
        # else:
        #     ax_nxt = state['ax']

        # ay_dt = state['ay']*dt
        # ay_dt_abs = abs(ay_dt)
        # vy_abs = abs(state['vy'])
        # bool_y_stopped = vy_abs < ay_dt_abs
        # if bool_y_stopped:
        #     ay_nxt = 0
        # else:
        #     ay_nxt = state['ay']

    else: # recalc
        v = math.sqrt( state['vx']**2 + state['vy']**2 )
        if v==0:
            ax_nxt = 0
            ay_nxt = 0
        else:
            ax_nxt = -a_friction * state['vx'] / v
            ay_nxt = -a_friction * state['vy'] / v

    state_nxt = {'x':state['x'], 'y':state['y'], 'vx':state['vx'], 'vy':state['vy'], 'ax':ax_nxt, 'ay':ay_nxt}

    return state_nxt


def forward_scene_by_cap_steps (dt, array_states_start, cap, params):
    #
    # Initialization
    #
    array_states = array_states_start
    dict_collision_pairwise_count = {}
    for i in range(len(array_states)):
        for k in range(i+1, len(array_states)):
            dict_collision_pairwise_count[f'{i}-{k}'] = 0

    #
    # Loop
    #
    for iteration in range(cap):
        #
        # Prepare dictionaries
        #
        dict_collision_pairwise_flag = {}
        for i in range(len(array_states)):
            for k in range(i+1, len(array_states)):
                dict_collision_pairwise_flag[f'{i}-{k}'] = 0
        dict_collision_count = {}
        for i in range(len(array_states)):
            dict_collision_count[i] = 0

        #
        # Forward each object with euler_single_step()
        #
        euler_single_step_returns = [euler_single_step(dt, state, params) for state in array_states]
        array_states_cand = [e[0] for e in euler_single_step_returns]
        bool_collision_boundary_s = [e[1] for e in euler_single_step_returns]

        #
        # Handle pairwise collision with collision_pair_circles()
        #
        for i in range(len(array_states)):
            for k in range(i+1, len(array_states)):
                state_i_nxt, state_k_nxt, bool_i_k_collided = collision_pair_circles (array_states[i], array_states[k], array_states_cand[i], array_states_cand[k], params['r'], params['r'])
                array_states_cand[i] = state_i_nxt
                array_states_cand[k] = state_k_nxt
                dict_collision_pairwise_flag[f'{i}-{k}'] = bool_i_k_collided
                dict_collision_count[i] += bool_i_k_collided
                dict_collision_count[k] += bool_i_k_collided

        #
        # Apply friction with friction_single_circle()
        #
        should_recalc_s = [
            int(iteration==0) + bool_boundary + dict_collision_count[i]
            for i,bool_boundary in enumerate(bool_collision_boundary_s)
        ]
        array_states_final = [
            friction_single_circle (dt, state, should_recalc, params['a_friction'])
            for state,should_recalc  in zip(array_states_cand, should_recalc_s)
        ]
        array_states = array_states_final

        #
        # Update dict_collision_pairwise_count
        #
        for i in range(len(array_states)):
            for k in range(i+1, len(array_states)):
                dict_collision_pairwise_count[f'{i}-{k}'] += dict_collision_pairwise_flag[f'{i}-{k}']

    return array_states, dict_collision_pairwise_count

#