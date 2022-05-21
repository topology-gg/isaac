import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

LOGGER = logging.getLogger(__name__)
TEST_NUM_PER_CASE = 200
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_grid ():

    starknet = await Starknet.empty()

    print(f'> Deploying mock_grid.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_grid.cairo',
        constructor_calldata = []
    )

    #####################################################
    # Test `mock_locate_face_and_edge_given_valid_grid()`
    #####################################################
    print('> Testing mock_locate_face_and_edge_given_valid_grid()')
    for i in range(TEST_NUM_PER_CASE):
        i_format = '{:3}'.format(i+1)
        is_on_edge = random.randint (0,1)
        face = random.randint (0,5)
        if is_on_edge == 1:
            grid, edge, idx_on_edge = generate_random_grid_on_edge_given_face (face, PLANET_DIM)
            ret = await contract.mock_locate_face_and_edge_given_valid_grid(
                grid = contract.Vec2 (grid[0], grid[1])
            ).call()
            LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: grid {grid} on face {face} and edge {edge}, output: {ret.result}')
            assert ret.result.face == face
            assert ret.result.is_on_edge == 1
            assert ret.result.edge == edge
            assert ret.result.idx_on_edge == idx_on_edge
        else:
            inner_grid = generate_random_valid_inner_grid_given_face (face, PLANET_DIM)
            ret = await contract.mock_locate_face_and_edge_given_valid_grid(
                grid = contract.Vec2 (inner_grid[0], inner_grid[1])
            ).call()
            LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: inner grid {inner_grid} on face {face}, output: {ret.result}')
            assert ret.result.face == face
            assert ret.result.is_on_edge == 0
            assert ret.result.edge == 0
            assert ret.result.idx_on_edge == 0
    LOGGER.info ('')

    ###################################################################
    # Test `mock_are_contiguous_grids_given_valid_grids_on_same_face()`
    ###################################################################
    print('> Testing mock_are_contiguous_grids_given_valid_grids_on_same_face()')
    # 1. Test with pairs of contiguous grids on same face
    LOGGER.info ('> Contiguous grids:')
    for i in range(TEST_NUM_PER_CASE):
        i_format = '{:3}'.format(i+1)
        face = random.randint (0,5)
        inner_grid = generate_random_valid_inner_grid_given_face (face, PLANET_DIM)
        nudge = random.choice([ (0,1), (1,0), (0,-1), (-1,0) ])
        contiguous_grid = (inner_grid[0] + nudge[0], inner_grid[1] + nudge[1])
        await contract.mock_are_contiguous_grids_given_valid_grids_on_same_face(
            contract.Vec2 (inner_grid[0], inner_grid[1]),
            contract.Vec2 (contiguous_grid[0], contiguous_grid[1])
        ).call()
        LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: {inner_grid} and {contiguous_grid} on face {face}; assertion passed as expected')
    LOGGER.info ('')

    # 2. Test with pairs of incontiguous grids on same face
    LOGGER.info ('> Incontiguous grids:')
    for i in range(TEST_NUM_PER_CASE):
        i_format = '{:3}'.format(i+1)
        face = random.randint (0,5)
        inner_grid = generate_random_valid_inner_grid_given_face (face, PLANET_DIM)
        while True:
            another_grid = generate_random_valid_inner_grid_given_face (face, PLANET_DIM)
            if another_grid == inner_grid:
                continue
            distance = abs(another_grid[0] - inner_grid[0]) + abs(another_grid[1] - inner_grid[1])
            if distance == 1:
                continue
            incontiguous_grid = another_grid
            break
        # expect exception raised
        with pytest.raises(Exception) as e_info:
            await contract.mock_are_contiguous_grids_given_valid_grids_on_same_face(
                contract.Vec2 (inner_grid[0], inner_grid[1]),
                contract.Vec2 (incontiguous_grid[0], incontiguous_grid[1])
            ).call()
        LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | input: {inner_grid} and {incontiguous_grid} on face {face}; assertion failed as expected')
    LOGGER.info ('')

    ######################################################
    # Test `mock_are_contiguous_grids_given_valid_grids()`
    ######################################################
    # Test with pairs of contiguous/incontiguous grids on different faces on same-labeled edge
    print('Testing mock_are_contiguous_grids_given_valid_grids()')
    for i in range(TEST_NUM_PER_CASE):
        i_format = '{:3}'.format(i+1)

        # TODO: balance coverage between contiguous vs incontiguous (now it's overwhelmingly incontiguous)
        while True:
            face_0 = random.randint (0,5)
            grid_0, edge_0, idx_on_edge_0 = generate_random_grid_on_edge_given_face (face=face_0, dim=PLANET_DIM)
            faces = {0,1,2,3,4,5}
            faces.remove(face_0)
            face_1 = random.choice( list(faces) )
            grid_1, edge_1, idx_on_edge_1 = generate_random_grid_on_edge_given_face (face=face_1, dim=PLANET_DIM)
            break

        if (edge_0 == edge_1) & (idx_on_edge_0 == idx_on_edge_1):
            # contiguous
            LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | testing two contiguous grids: {grid_0} and {grid_1}')
            await contract.mock_are_contiguous_grids_given_valid_grids(grid_0, grid_1).call()
        else:
            # incontiguous, assume exception raised
            LOGGER.info (f'> {i_format}/{TEST_NUM_PER_CASE} | testing two incontiguous grids: {grid_0} and {grid_1}')
            with pytest.raises(Exception) as e_info:
                await contract.mock_are_contiguous_grids_given_valid_grids(grid_0, grid_1).call()

    # #############################
    # # Test `mock_is_valid_grid()`
    # #############################
    print('Testing mock_is_valid_grid()')
    # 1. Test with valid grids
    for i in range(TEST_NUM_PER_CASE):
        i_format = '{:3}'.format(i+1)
        valid_grid = generate_random_valid_grid (PLANET_DIM)
        LOGGER.info  (f'> {i_format}/{TEST_NUM_PER_CASE} | valid grid: {valid_grid}')
        await contract.mock_is_valid_grid(valid_grid).call()

    # 2. Test with invalid grids
    for i in range(TEST_NUM_PER_CASE):
        i_format = '{:3}'.format(i+1)
        invalid_grid = generate_random_invalid_grid (PLANET_DIM)
        LOGGER.info  (f'> {i_format}/{TEST_NUM_PER_CASE} | invalid grid: {invalid_grid}')
        with pytest.raises(Exception) as e_info:
            await contract.mock_is_valid_grid(invalid_grid).call()
    LOGGER.info ('')


def generate_random_valid_grid_given_face (face, dim):
    x_ori, y_ori = get_face_origin (face, dim)
    x_rand = random.randint (0, dim-1) # randint is inclusive on [start,end]
    y_rand = random.randint (0, dim-1)
    return (x_ori + x_rand, y_ori + y_rand)


def generate_random_valid_inner_grid_given_face (face, dim):
    # inner_grid === grid that is not on edge
    x_ori, y_ori = get_face_origin (face, dim)
    x_rand = random.randint (1, dim-2) # randint is inclusive on [start,end]
    y_rand = random.randint (1, dim-2)
    return (x_ori + x_rand, y_ori + y_rand)


def get_face_origin (face, dim):
    if face == 0:
        return (0, dim)
    elif face == 1:
        return (dim, 0)
    elif face == 2:
        return (dim, dim)
    elif face == 3:
        return (dim, dim*2)
    elif face == 4:
        return (dim*2, dim)
    elif face == 5:
        return (dim*3, dim)
    else:
        raise


def generate_random_valid_grid (dim):
    face = random.randint (0,5)
    return generate_random_valid_grid_given_face (face, dim)


def generate_random_invalid_grid (dim):
    # invalid ranges:
    # 1. (0 ~ D-1, 0 ~ D-1)
    # 2. (0 ~ D-1, 2D ~ )
    # 3. (2D ~ , 0 ~ D-1)
    # 4. (2D ~ , 2D ~ )

    invalid_case = random.randint (1,4)
    if invalid_case == 1:
        x = random.randint (0, dim-1)
        y = random.randint (0, dim-1)
    elif invalid_case == 2:
        x = random.randint (0, dim-1)
        y = random.randint (2*dim, 4*dim)
    elif invalid_case == 3:
        x = random.randint (2*dim, 4*dim)
        y = random.randint (0, dim-1)
    elif invalid_case == 4:
        x = random.randint (2*dim, 4*dim)
        y = random.randint (2*dim, 4*dim)
    else:
        raise
    return (x,y)


# return: grid, edge, idx_on_edge
def generate_random_grid_on_edge_given_face (face, dim):

    if face == 0:
        edge = random.choice([0, 1, 6, 7, 14, 15, 16, 17])
    elif face == 1:
        edge = random.choice([0, 3, 5, 8, 13, 15, 16, 19])
    elif face == 2:
        edge = random.choice([7, 8, 9, 10, 16, 17, 18, 19])
    elif face == 3:
        edge = random.choice([1, 2, 4, 10, 12, 14, 17, 18])
    elif face == 4:
        edge = random.choice([2, 3, 9, 11, 12, 13, 18, 19])
    elif face == 5:
        edge = random.choice([4, 5, 6, 11, 12, 13, 14, 15])
    else:
        raise Exception ("only face 0-5 are valid!")

    grid, idx_on_edge = generate_random_grid_on_edge_given_edge_and_face (edge, face, dim)
    return grid, edge, idx_on_edge


# return grid(x,y), idx_on_edge
def generate_random_grid_on_edge_given_edge_and_face (edge, face, dim):
    if (edge, face) == (0,0):
        x = random.randint (1, dim-2)
        y = dim
        index = x - 1
    elif (edge, face) == (0,1):
        x = dim
        y = random.randint (1, dim-2)
        index = y - 1

    elif (edge, face) == (1,0):
        x = random.randint (1, dim-2)
        y = 2*dim-1
        index = x - 1
    elif (edge, face) == (1,3):
        x = dim
        y = random.randint (2*dim+1, 3*dim-2)
        index = 3*dim-2 - y

    elif (edge, face) == (2,4):
        x = random.randint (2*dim+1, 3*dim-2)
        y = 2*dim-1
        index = 3*dim-2 - x
    elif (edge, face) == (2,3):
        x = 2*dim-1
        y = random.randint (2*dim+1, 3*dim-2)
        index = 3*dim-2 - y

    elif (edge, face) == (3,4):
        x = random.randint (2*dim+1, 3*dim-2)
        y = dim
        index = 3*dim-2 - x
    elif (edge, face) == (3,1):
        x = 2*dim-1
        y = random.randint (1, dim-2)
        index = y - 1

    elif (edge, face) == (4,3):
        x = random.randint (dim+1, 2*dim-2)
        y = 3*dim-1
        index = 2*dim-2 - x
    elif (edge, face) == (4,5):
        x = random.randint (3*dim+1, 4*dim-2)
        y = 2*dim-1
        index = x - (3*dim+1)

    elif (edge, face) == (5,1):
        x = random.randint (dim+1, 2*dim-2)
        y = 0
        index = 2*dim-2 - x
    elif (edge, face) == (5,5):
        x = random.randint (3*dim+1, 4*dim-2)
        y = dim
        index = x - (3*dim+1)

    elif (edge, face) == (6,0):
        x = 0
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)
    elif (edge, face) == (6,5):
        x = 4*dim-1
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)

    elif (edge, face) == (7,0):
        x = dim-1
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)
    elif (edge, face) == (7,2):
        x = dim
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)

    elif (edge, face) == (8,1):
        x = random.randint (dim+1, 2*dim-2)
        y = dim-1
        index = x - (dim+1)
    elif (edge, face) == (8,2):
        x = random.randint (dim+1, 2*dim-2)
        y = dim
        index = x - (dim+1)

    elif (edge, face) == (9,2):
        x = 2*dim-1
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)
    elif (edge, face) == (9,4):
        x = 2*dim
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)

    elif (edge, face) == (10,2):
        x = random.randint (dim+1, 2*dim-2)
        y = 2*dim-1
        index = x - (dim+1)
    elif (edge, face) == (10,3):
        x = random.randint (dim+1, 2*dim-2)
        y = 2*dim
        index = x - (dim+1)

    elif (edge, face) == (11,4):
        x = 3*dim-1
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)
    elif (edge, face) == (11,5):
        x = 3*dim
        y = random.randint (dim+1, 2*dim-2)
        index = y - (dim+1)

    elif (edge, face) == (12,3):
        x = 2*dim-1
        y = 3*dim-1
        index = 0
    elif (edge, face) == (12,4):
        x = 3*dim-1
        y = 2*dim-1
        index = 0
    elif (edge, face) == (12,5):
        x = 3*dim
        y = 2*dim-1
        index = 0

    elif (edge, face) == (13,1):
        x = 2*dim-1
        y = 0
        index = 0
    elif (edge, face) == (13,4):
        x = 3*dim-1
        y = dim
        index = 0
    elif (edge, face) == (13,5):
        x = 3*dim
        y = dim
        index = 0

    elif (edge, face) == (14,0):
        x = 0
        y = 2*dim-1
        index = 0
    elif (edge, face) == (14,3):
        x = dim
        y = 3*dim-1
        index = 0
    elif (edge, face) == (14,5):
        x = 4*dim-1
        y = 2*dim-1
        index = 0

    elif (edge, face) == (15,0):
        x = 0
        y = dim
        index = 0
    elif (edge, face) == (15,1):
        x = dim
        y = 0
        index = 0
    elif (edge, face) == (15,5):
        x = 4*dim-1
        y = dim
        index = 0

    elif (edge, face) == (16,0):
        x = dim-1
        y = dim
        index = 0
    elif (edge, face) == (16,1):
        x = dim
        y = dim-1
        index = 0
    elif (edge, face) == (16,2):
        x = dim
        y = dim
        index = 0

    elif (edge, face) == (17,0):
        x = dim-1
        y = 2*dim-1
        index = 0
    elif (edge, face) == (17,2):
        x = dim
        y = 2*dim-1
        index = 0
    elif (edge, face) == (17,3):
        x = dim
        y = 2*dim
        index = 0

    elif (edge, face) == (18,2):
        x = 2*dim-1
        y = 2*dim-1
        index = 0
    elif (edge, face) == (18,3):
        x = 2*dim-1
        y = 2*dim
        index = 0
    elif (edge, face) == (18,4):
        x = 2*dim
        y = 2*dim-1
        index = 0

    elif (edge, face) == (19,1):
        x = 2*dim-1
        y = dim-1
        index = 0
    elif (edge, face) == (19,2):
        x = 2*dim-1
        y = dim
        index = 0
    elif (edge, face) == (19,4):
        x = 2*dim
        y = dim
        index = 0

    else:
        raise

    return (x,y), index

# return: grid, idx_on_edge
# def generate_random_grid_on_edge_given_edge (edge, dim):
#     side = random.randint (0,1)
#     return generate_random_grid_on_edge_given_edge_and_side (edge, side, dim)