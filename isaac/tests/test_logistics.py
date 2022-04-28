import pytest
import os
from starkware.starknet.testing.starknet import Starknet
import asyncio
from Signer import Signer
import random
from enum import Enum
import logging

import math
import random
import matplotlib.pyplot as plt
import numpy as np

LOGGER = logging.getLogger(__name__)
TEST_NUM_PER_CASE = 200
PRIME = 3618502788666131213697322783095070105623107215331596699973092056135872020481
PRIME_HALF = PRIME//2
PLANET_DIM = 100
SCALE_FP = 10**20

## Note to test logging:
## `--log-cli-level=INFO` to show logs

@pytest.mark.asyncio
async def test_logistics ():

    starknet = await Starknet.empty()

    LOGGER.info (f'> Deploying mock_logistics.cairo ..')
    contract = await starknet.deploy (
        source = 'contracts/mocks/mock_logistics.cairo',
        constructor_calldata = [])

    #
    # Test harvester functions
    #
    # raw_resource_types = [0,2,4,6,8]
    # perlin_bound = 1000 # ns_perlin.BOUND
    # harvester_boost_bound = 100 # ns_harvester_boost_factor.BOUND
    # concentration = 300
    # for resource_type in raw_resource_types: # raw elements only
    #     for energy in [0,10,20,30,40]:

    #         ret = await contract.mock_harvester_resource_concentration_to_quantity_per_tick(
    #             resource_type, concentration
    #         ).call()
    #         base_quantity = ret.result.base_quantity
    #         # LOGGER.info (f"> base quantity: {base_quantity}; perlin bound = {perlin_bound}")

    #         ret = await contract.mock_harvester_energy_to_boost_factor (
    #             resource_type, energy
    #         ).call()
    #         boost = ret.result.boost_factor
    #         # LOGGER.info (f"> boost factor: {boost}; boost bound = {boost_bound}")

    #         ret = await contract.mock_harvester_quantity_per_tick(
    #             resource_type, concentration, energy
    #         ).call()
    #         quantity = ret.result.quantity
    #         LOGGER.info (f"> resource type {resource_type}; concentration {concentration}; energy supplied {energy}; harvest quantity per tick = {quantity}")

    #         assert quantity == base_quantity * boost // (perlin_bound * harvester_boost_bound)

    #     LOGGER.info ("")

    #
    # Test transformer functions
    #
    # transformer_boost_bound = 100 # ns_transformer_boost_factor.BOUND
    # for resource_type_from in raw_resource_types:
    #     for energy in [0,10,20,30,40]:
    #         ret = await contract.mock_transformer_resource_type_to_base_quantity_per_tick(
    #             resource_type_from
    #         ).call()
    #         base_quantity_to = ret.result.base_quantity_to

    #         ret = await contract.mock_transformer_energy_to_boost_factor(
    #             resource_type_from, energy
    #         ).call()
    #         boost_factor = ret.result.boost_factor

    #         ret = await contract.mock_transformer_quantity_per_tick(
    #             resource_type_from, energy
    #         ).call()
    #         quantity_to = ret.result.quantity_to
    #         LOGGER.info (f"> resource type {resource_type}; energy supplied {energy}; transform-to quantity per tick = {quantity_to}")

    #         assert quantity_to == base_quantity_to * boost_factor // transformer_boost_bound

    #     LOGGER.info ("")

    #
    # Test power generator functions
    #
    # solar_bound = 100 # ns_solar_power.BOUND
    # solar_mult = 10 # ns_solar_power.MULT
    # nuclear_base_energy = 50 # ns_nuclear_power.BASE_ENERGY
    # nuclear_boost_divider = 20 # ns_nuclear_power.BOOST_DIVIDER
    # for solar_exposure in [0, 30, 50, 120, 180]:
    #     ret = await contract.mock_spg_solar_exposure_to_energy_generated_per_tick(
    #         solar_exposure
    #     ).call()
    #     energy_generated = ret.result.energy_generated
    #     LOGGER.info (f"> solar exposure {solar_exposure}; SPG energy generated per tick = {energy_generated}")

    #     assert energy_generated == solar_exposure * solar_mult // solar_bound
    # LOGGER.info ("")

    # for energy_supplied in [0, 10, 20, 30, 40]:
    #     ret = await contract.mock_npg_energy_supplied_to_energy_generated_per_tick(
    #         energy_supplied
    #     ).call()
    #     energy_generated = ret.result.energy_generated
    #     LOGGER.info (f"> energy supplied {energy_supplied}; NPG energy generated per tick = {energy_generated}")

    #     assert energy_generated == nuclear_base_energy * (nuclear_boost_divider + energy_supplied) // nuclear_boost_divider
    # LOGGER.info ("")

    #
    # Test utb functions
    #
    utb_decay_base = 20
    utb_decay_lambda = 10
    utb_decay_scale = 1000
    for quantity_source in [0,1,2,3,5,10,20,50,100]:
        for length in [1,3,5,8,15,30,50]:
            LOGGER.info (f"> quantity source {quantity_source}; utb-set length {length}:")
            ret = await contract.mock_utb_quantity_should_send_per_tick(
                quantity_source
            ).call()
            quantity_should_send = ret.result.quantity_should_send
            LOGGER.info (f">   quantity should send = {quantity_should_send}")

            if quantity_source < utb_decay_base:
                should_send = quantity_source
            else:
                should_send = utb_decay_base

            assert quantity_should_send == should_send

            ret = await contract.mock_utb_set_length_to_decay_factor(
                length
            ).call()
            decay_factor = ret.result.decay_factor

            ret = await contract.mock_utb_quantity_should_receive_per_tick(
                quantity_source,
                length
            ).call()
            quantity_should_receive = ret.result.quantity_should_receive
            LOGGER.info (f">   quantity should recv = {quantity_should_receive}")

            assert quantity_should_receive == quantity_should_send * decay_factor // utb_decay_scale
        LOGGER.info ("")

    #
    # Test utl functions
    #
    utl_decay_base = 20
    utl_decay_lambda = 10
    utl_decay_scale = 1000
    for energy_source in [0,1,2,3,5,10,20,50,100]:
        for length in [1,3,5,8,15,30,50]:
            LOGGER.info (f"> energy source {energy_source}; utl-set length {length}:")
            ret = await contract.mock_utl_energy_should_send_per_tick(
                energy_source
            ).call()
            energy_should_send = ret.result.energy_should_send
            LOGGER.info (f">   energy should send = {energy_should_send}")

            if energy_source < utl_decay_base:
                should_send = energy_source
            else:
                should_send = utl_decay_base

            assert energy_should_send == should_send

            ret = await contract.mock_utl_set_length_to_decay_factor(
                length
            ).call()
            decay_factor = ret.result.decay_factor

            ret = await contract.mock_utl_energy_should_receive_per_tick(
                energy_source,
                length
            ).call()
            energy_should_receive = ret.result.energy_should_receive
            LOGGER.info (f">   energy should recv = {energy_should_receive}")

            assert energy_should_receive == energy_should_send * decay_factor // utl_decay_scale
        LOGGER.info ("")
