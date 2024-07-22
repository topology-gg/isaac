import pytest
import os
import random
from starkware.starknet.testing.starknet import Starknet
from lib import *
from visualizer import *
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
    contract = await starknet.deploy('contracts/mocks/mock_scene_forwarder_array.cairo')
    print()

    #
    # Preparing array of objects at start in the scene
    #
    array_states_start = [
        {'x':75,  'y':180, 'vx':0, 'vy':0, 'ax':0, 'ay':0},
        {'x':225, 'y':180, 'vx':0, 'vy':0, 'ax':0, 'ay':0},
        {'x':150, 'y':180, 'vx':0, 'vy':0, 'ax':0, 'ay':0},
        {'x':50, 'y':50, 'vx':150, 'vy':150, 'ax':0, 'ay':0}
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
        'x_max' : 250,
        'y_min' : 0,
        'y_max' : 250,
        'a_friction' : 40
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
    N = 4
    names = ['s0', 's1', 'fb', 'pl']
    # pairwise_labels = []
    # pairwise_indices = []
    # for i in range(N):
    #     for k in range(i+1,N):
    #         pairwise_labels.append(names[i] + '-' + names[k])
    #         pairwise_indices.append(f'{i}-{k}')

    arr_obj = arr_obj_start
    array_states = array_states_start
    dt = 0.15
    arr_obj_s = []
    collision_records = []

    while True:
        cap = 40

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
        # print(f'arr_obj_final: {ret.result.arr_obj_final}')
        print(f'arr_collision_record: {ret.result.arr_collision_record}')
        collision_records += ret.result.arr_collision_record
        print(f'n_steps: {ret.call_info.cairo_usage.n_steps}')

        events = ret.main_call_events
        if len(events)>0:
            for event in events:

                for obj in event.arr_obj:
                    print(f'{obj.vel.x}, {obj.vel.y} / ', end='')
                print()
                arr_obj_s.append(event.arr_obj)


        #
        # Perform simulation
        #
        all_collision_counts_match = True
        array_states_nxt, dict_collision_pairwise_count_nxt = forward_scene_by_cap_steps (dt, array_states, cap, params_dict)
        #for index, label, count in zip(pairwise_indices, pairwise_labels, ret.result.arr_collision_pairwise_count):
        #    sim_count = dict_collision_pairwise_count_nxt[index]
            # print(f'  {label} / contract={count} / simulation={sim_count} / matched={sim_count==count}')
            #all_collision_counts_match *= (sim_count==count)
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
        for obj in ret.result.arr_obj_final:
            rest *= (obj.vel.x==0) * (obj.vel.y==0)

        if rest:
            print('> All objects have come to rest')
            break

        #
        # Prepare for next iteration
        #
        arr_obj = ret.result.arr_obj_final
        array_states = array_states_nxt

    collision_records = '-'.join( [str(e) for e in collision_records] )
    visualize_game (arr_obj_s, collision_records, '')


def print_scene (scene_array, names):
    for i,obj in enumerate(scene_array):
        print(f'    {names[i]}: pos=({adjust(obj.pos.x)}, {adjust(obj.pos.y)}), vel=({adjust(obj.vel.x)}, {adjust(obj.vel.y)}), acc=({adjust(obj.acc.x)}, {adjust(obj.acc.y)})')
