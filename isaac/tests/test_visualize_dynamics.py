import pytest
import asyncio
from starkware.starknet.testing.starknet import Starknet

PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
SCALE_FP = 10**20

# Enables modules.
@pytest.fixture(scope='module')
def event_loop():
    return asyncio.new_event_loop()

# Reusable to save testing time.
@pytest.fixture(scope='module')
async def contract_factory():
    starknet = await Starknet.empty()
    contract = await starknet.deploy("contracts/util/visualize_dynamics.cairo")
    return starknet, contract

@pytest.mark.asyncio
async def test_contract(contract_factory):
    starknet, contract = contract_factory

    test_dynamics = contract.Dynamics (
            sun0 = contract.Dynamic (q = contract.Vec2(fp_to_felt(0), fp_to_felt(2)), qd = contract.Vec2(fp_to_felt(1), fp_to_felt(2))),
            sun1 = contract.Dynamic (q = contract.Vec2(fp_to_felt(1), fp_to_felt(2)), qd = contract.Vec2(fp_to_felt(1), fp_to_felt(1))),
            sun2 = contract.Dynamic (q = contract.Vec2(fp_to_felt(0), fp_to_felt(0.5)), qd = contract.Vec2(fp_to_felt(1), fp_to_felt(2))),
            plnt = contract.Dynamic (q = contract.Vec2(fp_to_felt(0), fp_to_felt(1)), qd = contract.Vec2(fp_to_felt(1), fp_to_felt(2))),
    )
    
    # Read from contract
    response = await contract.get_dynamics_viz(test_dynamics).call()

    res_sun0 = get_res_str(response.result.sun0)
    res_sun1 = get_res_str(response.result.sun1)
    res_sun2 = get_res_str(response.result.sun2)
    res_plnt = get_res_str(response.result.plnt)

    assert res_sun0 == '<circle cx="0" cy="2" r="0.1" fill="red" />'
    assert res_sun1 == '<circle cx="1" cy="2" r="0.1" fill="red" />'
    assert res_sun2 == '<circle cx="0" cy="0" r="0.1" fill="red" />'
    assert res_plnt == '<circle cx="0" cy="1" r="0.1" fill="red" />'


def get_res_str(hex_string):
    res_str = ''
    for val in hex_string:
        res_str = res_str + hex_to_ascii(dec_to_hex(val))

    return res_str
   
def dec_to_hex(num):
    return hex(num)

def hex_to_ascii(hex_str):
    asc = bytearray.fromhex(hex_str[2:]).decode()
    return asc

def fp_to_felt (val):
    val_scaled = int (val * SCALE_FP)
    if val_scaled < 0:
        val_fp = val_scaled + PRIME
    else:
        val_fp = val_scaled
    return val_fp


