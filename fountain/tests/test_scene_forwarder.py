import pytest
import os
import random
from starkware.starknet.testing.starknet import Starknet
from lib import *
import asyncio

ERR_TOL = 1e-5

#
# Testing methodology:
# loop:
#   forward the scene by a random step count
#   check contract return against python simulation return.
#   stop if all objects in the scene have come to rest.
#
@pytest.mark.asyncio
async def test_game_state_forwarder ():

    starknet = await Starknet.empty()
    contract = await starknet.deploy('contracts/mocks/mock_scene_forwarder.cairo')
    print()

    #
    # Preparing array of objects at start in the scene
    #
    array_states_start = [
        {'x':300, 'y':250, 'vx':0, 'vy':0, 'ax':0, 'ay':0},
        {'x':200, 'y':250, 'vx':0, 'vy':0, 'ax':0, 'ay':0},
        {'x':200, 'y':350, 'vx':0, 'vy':0, 'ax':0, 'ay':0},
        {'x':50, 'y':40, 'vx':150, 'vy':200, 'ax':0, 'ay':0},
        {'x':91, 'y':40, 'vx':200, 'vy':150, 'ax':0, 'ay':0},
        {'x':180, 'y':60, 'vx':200, 'vy':200, 'ax':0, 'ay':0},
    ]
    arr_obj_start = []
    for state in array_states_start:
        arr_obj_start.append(
            contract.ObjectState (
                pos = contract.Vec2(state['x']*FP, state['y']*FP),
                vel = contract.Vec2(state['vx']*FP, state['vy']*FP),
                acc = contract.Vec2(state['ax']*FP, state['ay']*FP),
            )
        )

    #
    # Prepare params array
    #
    params_dict = {
        'r' : 20,
        'x_min' : 0,
        'x_max' : 400,
        'y_min' : 0,
        'y_max' : 400,
        'a_friction' : 30
    }
    params = [
        params_dict['r']*FP,
        (params_dict['r']+params_dict['r'])**2*FP,
        params_dict['x_min']*FP,
        params_dict['x_max']*FP,
        params_dict['y_min']*FP,
        params_dict['y_max']*FP,
        params_dict['a_friction']*FP,
    ]

    #
    # Prepare pairwise labels
    #
    names = ['s0', 's1', 'fb', 'p1', 'p2', 'p3']
    pairwise_labels = []
    pairwise_indices = []
    for i in range(6):
        for k in range(i+1,6):
            pairwise_labels.append(names[i] + '-' + names[k])
            pairwise_indices.append(f'{i}-{k}')

    arr_obj = arr_obj_start
    array_states = array_states_start
    dt = 0.3
    while True:
        cap = random.randint(1,30)

        #
        # Call contract function
        #
        print(f'> Calling forward_scene_capped_counting_collision() with cap={cap} ...')
        ret = await contract.mock_forward_scene_capped_counting_collision(
            arr_obj = arr_obj,
            cap = cap,
            dt = int(dt * FP),
            params = params
        ).call()

        events = ret.main_call_events
        if len(events)>0:
            for event in events:
                print(event)


        #
        # Perform simulation
        #
        all_collision_counts_match = True
        array_states_nxt, dict_collision_pairwise_count_nxt = forward_scene_by_cap_steps (dt, array_states, cap, params_dict)
        for index, label, count in zip(pairwise_indices, pairwise_labels, ret.result.arr_collision_pairwise_count):
            sim_count = dict_collision_pairwise_count_nxt[index]
            # print(f'  {label} / contract={count} / simulation={sim_count} / matched={sim_count==count}')
            all_collision_counts_match *= (sim_count==count)
        # print()


        #
        # Perform checks
        #
        assert all_collision_counts_match == True
        for obj, state in zip(ret.result.arr_obj_final, array_states_nxt):
            check_against_err_tol (adjust(obj.pos.x), state['x'], ERR_TOL)
            check_against_err_tol (adjust(obj.pos.y), state['y'], ERR_TOL)
            check_against_err_tol (adjust(obj.vel.x), state['vx'], ERR_TOL)
            check_against_err_tol (adjust(obj.vel.y), state['vy'], ERR_TOL)
            check_against_err_tol (adjust(obj.acc.x), state['ax'], ERR_TOL)
            check_against_err_tol (adjust(obj.acc.y), state['ay'], ERR_TOL)
        print('> All checks have passed.')
        print()


        #
        # Terminate if all objects have come to rest
        #
        rest = True
        for state in array_states_nxt:
            rest *= (state['vx']==0) * (state['vy']==0)

        if rest:
            print('> All objects have come to rest')
            break

        #
        # Prepare for next iteration
        #
        arr_obj = ret.result.arr_obj_final
        array_states = array_states_nxt


def print_scene (scene_array, names):
    for i,obj in enumerate(scene_array):
        print(f'    {names[i]}: pos=({adjust(obj.pos.x)}, {adjust(obj.pos.y)}), vel=({adjust(obj.vel.x)}, {adjust(obj.vel.y)}), acc=({adjust(obj.acc.x)}, {adjust(obj.acc.y)})')
