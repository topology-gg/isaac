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
    contract = await starknet.deploy("contracts/util/sun_svg.cairo")
    return starknet, contract

@pytest.mark.asyncio
async def test_contract(contract_factory):
    starknet, contract = contract_factory

    test_sun = contract.Dynamic (q = contract.Vec2(fp_to_felt(0), fp_to_felt(2)), qd = contract.Vec2(fp_to_felt(1), fp_to_felt(2)))

    # Read from contract
    response = await contract.get_sun_svg(test_sun).call()
    assert response.result.arr == [18689282203996290424440896802, 48, 37522503187746, 50, 146573245730, 3157553, 2459077999520922914, 7497060, 572534590]

def fp_to_felt (val):
    val_scaled = int (val * SCALE_FP)
    if val_scaled < 0:
        val_fp = val_scaled + PRIME
    else:
        val_fp = val_scaled
    return val_fp


