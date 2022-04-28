%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem, unsigned_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.alloc import alloc

from contracts.design.constants import (
    ns_device_types, ns_element_types,
    ns_base_harvester_multiplier, ns_harvester_boost_factor,
    ns_base_transformer_quantity, ns_transformer_boost_factor,
    ns_solar_power, ns_nuclear_power,
    ns_decay_function,
    ns_perlin
)
from contracts.util.structs import (Vec2)

#
# Functions involved in logistics simulation:
# for each harvester device type, we have `f : concentration -> quantity`, `g : energy -> boost factor`, and `h = f * g // (perlin bound * energy bound)`
# for each transformer device type, we have `f : _ -> quantity to`, `g : energy -> boost factor`, and `h = f * g // (transform bound * energy bound)`
# for solar power generator, we have `f : solar exposure -> energy`
# for nuclear power generator, we have `f : supplied energy -> energy`
# for utb, we have `f : quantity source -> quantity should send`, `g : utb-set length -> decay factor`, and `h = f * g // (decay bound)`
# for utl, we have `f : energy source -> energy should send`, `g : utl-set length -> decay factor`, and `h = f * g // (decay bound)`
#

#####################
# harvester functions
#####################

namespace ns_logistics_harvester:
    func harvester_resource_concentration_to_quantity_per_tick {} (
            resource_type : felt,
            concentration : felt
        ) -> (
            base_quantity : felt
        ):

        if resource_type == ns_element_types.ELEMENT_FE_RAW:
            return (concentration * ns_base_harvester_multiplier.ELEMENT_FE_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_AL_RAW:
            return (concentration * ns_base_harvester_multiplier.ELEMENT_AL_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_CU_RAW:
            return (concentration * ns_base_harvester_multiplier.ELEMENT_CU_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_SI_RAW:
            return (concentration * ns_base_harvester_multiplier.ELEMENT_SI_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_PU_RAW:
            return (concentration * ns_base_harvester_multiplier.ELEMENT_PU_RAW)
        end

        with_attr error_message ("non-harvestable element type"):
            assert 0 = 1
        end
        return (0)
    end

    func harvester_energy_to_boost_factor {} (
            resource_type : felt,
            energy : felt
        ) -> (boost_factor : felt):

        let unity = ns_harvester_boost_factor.BOUND

        if resource_type == ns_element_types.ELEMENT_FE_RAW:
            return (unity + energy * ns_harvester_boost_factor.ELEMENT_FE_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_AL_RAW:
            return (unity + energy * ns_harvester_boost_factor.ELEMENT_AL_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_CU_RAW:
            return (unity + energy * ns_harvester_boost_factor.ELEMENT_CU_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_SI_RAW:
            return (unity + energy * ns_harvester_boost_factor.ELEMENT_SI_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_PU_RAW:
            return (unity + energy * ns_harvester_boost_factor.ELEMENT_PU_RAW)
        end

        with_attr error_message ("non-harvestable element type"):
            assert 0 = 1
        end
        return (0)
    end

    func harvester_quantity_per_tick {range_check_ptr} (
            resource_type : felt,
            concentration : felt,
            energy : felt
        ) -> (
            quantity : felt
        ):
        alloc_locals

        let (f) = harvester_resource_concentration_to_quantity_per_tick (resource_type, concentration)
        let (g) = harvester_energy_to_boost_factor (resource_type, energy)
        let denominator = ns_perlin.BOUND * ns_harvester_boost_factor.BOUND
        let (quantity, _) = unsigned_div_rem (f*g, denominator)

        return (quantity)
    end
end

#######################
# transformer functions
#######################

namespace ns_logistics_transformer:
    func transformer_resource_type_to_base_quantity_per_tick {} (
            resource_type_from : felt
        ) -> (
            base_quantity_to : felt
        ):

        if resource_type_from == ns_element_types.ELEMENT_FE_RAW:
            return (ns_base_transformer_quantity.ELEMENT_FE_RAW)
        end

        if resource_type_from == ns_element_types.ELEMENT_AL_RAW:
            return (ns_base_transformer_quantity.ELEMENT_AL_RAW)
        end

        if resource_type_from == ns_element_types.ELEMENT_CU_RAW:
            return (ns_base_transformer_quantity.ELEMENT_CU_RAW)
        end

        if resource_type_from == ns_element_types.ELEMENT_SI_RAW:
            return (ns_base_transformer_quantity.ELEMENT_SI_RAW)
        end

        if resource_type_from == ns_element_types.ELEMENT_PU_RAW:
            return (ns_base_transformer_quantity.ELEMENT_PU_RAW)
        end

        with_attr error_message ("non-transformable element type"):
            assert 0 = 1
        end
        return (0)
    end

    func transformer_energy_to_boost_factor {} (
            resource_type : felt,
            energy : felt
        ) -> (boost_factor : felt):

        let unity = ns_transformer_boost_factor.BOUND

        if resource_type == ns_element_types.ELEMENT_FE_RAW:
            return (unity + energy * ns_transformer_boost_factor.ELEMENT_FE_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_AL_RAW:
            return (unity + energy * ns_transformer_boost_factor.ELEMENT_AL_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_CU_RAW:
            return (unity + energy * ns_transformer_boost_factor.ELEMENT_CU_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_SI_RAW:
            return (unity + energy * ns_transformer_boost_factor.ELEMENT_SI_RAW)
        end

        if resource_type == ns_element_types.ELEMENT_PU_RAW:
            return (unity + energy * ns_transformer_boost_factor.ELEMENT_PU_RAW)
        end

        with_attr error_message ("non-transformable element type"):
            assert 0 = 1
        end
        return (0)
    end

    func transformer_quantity_per_tick {range_check_ptr} (
            resource_type : felt,
            energy : felt
        ) -> (
            quantity_to : felt
        ):
        alloc_locals

        let (f) = transformer_resource_type_to_base_quantity_per_tick (resource_type)
        let (g) = transformer_energy_to_boost_factor (resource_type, energy)
        let denominator = ns_transformer_boost_factor.BOUND
        let (quantity_to, _) = unsigned_div_rem (f*g, denominator)

        return (quantity_to)
    end
end

###########################
# power generator functions
###########################

namespace ns_logistics_xpg:
    func spg_solar_exposure_to_energy_generated_per_tick {range_check_ptr} (
        solar_exposure : felt) -> (energy_generated : felt):

        let (energy_generated, _) = unsigned_div_rem (solar_exposure * ns_solar_power.MULT, ns_solar_power.BOUND)

        return (energy_generated)
    end

    func npg_energy_supplied_to_energy_generated_per_tick {range_check_ptr} (
        energy_supplied : felt) -> (energy_generated : felt):

        # energy generated = base energy * (divider + energy supplied) / divider

        let (energy_generated, _) = unsigned_div_rem (
            ns_nuclear_power.BASE_ENERGY * (ns_nuclear_power.BOOST_DIVIDER + energy_supplied),
            ns_nuclear_power.BOOST_DIVIDER
        )

        return (energy_generated)
    end
end

###############
# utx functions
###############

namespace ns_logistics_utb:
    func utb_quantity_should_send_per_tick {range_check_ptr} (
        quantity_source) -> (quantity_should_send):
        alloc_locals

        let (bool) = is_le (quantity_source, ns_decay_function.UTB_DECAY_BASE)

        if bool == 1:
            return (quantity_source)
        else:
            return (ns_decay_function.UTB_DECAY_BASE)
        end
    end

    func utb_set_length_to_decay_factor {range_check_ptr} (
        length : felt) -> (decay_factor):

        #
        # e^(-x), where x = lambda * length
        # via taylor expansion to the third degree:
        # e^(-x) ~= 1 - x + x^2/2 - x^3/6
        #
        let unity = ns_decay_function.UTB_DECAY_SCALE

        let x = length * ns_decay_function.UTB_DECAY_LAMBDA
        let (x_pow2, _) = unsigned_div_rem (x * x, ns_decay_function.UTB_DECAY_SCALE)
        let (x_pow3, _) = unsigned_div_rem (x_pow2 * x, ns_decay_function.UTB_DECAY_SCALE)

        let (term2, _) = unsigned_div_rem (x_pow2, 2)
        let (term3, _) = unsigned_div_rem (x_pow3, 6)

        let decay_factor = unity - x + term2 - term3

        return (decay_factor)
    end

    func utb_quantity_should_receive_per_tick {range_check_ptr} (
            quantity_source : felt,
            length : felt
        ) -> (
            quantity_should_receive : felt
        ):
        alloc_locals

        let (local f) = utb_quantity_should_send_per_tick (quantity_source)
        let (local g) = utb_set_length_to_decay_factor (length)
        local denominator = ns_decay_function.UTB_DECAY_SCALE

        let (quantity_should_receive, _) = unsigned_div_rem (f*g, denominator)

        return (quantity_should_receive)
    end
end

namespace ns_logistics_utl:
    func utl_energy_should_send_per_tick {range_check_ptr} (
        energy_source : felt) -> (energy_should_send : felt):
        alloc_locals

        let (bool) = is_le (energy_source, ns_decay_function.UTL_DECAY_BASE)

        if bool == 1:
            return (energy_source)
        else:
            return (ns_decay_function.UTL_DECAY_BASE)
        end
    end

    func utl_set_length_to_decay_factor {range_check_ptr} (
        length : felt) -> (decay_factor : felt):

        #
        # e^(-x), where x = lambda * length
        # via taylor expansion to the third degree:
        # e^(-x) ~= 1 - x + x^2/2 - x^3/6
        #
        let unity = ns_decay_function.UTL_DECAY_SCALE

        let x = length * ns_decay_function.UTL_DECAY_LAMBDA
        let (x_pow2, _) = unsigned_div_rem (x * x, ns_decay_function.UTL_DECAY_SCALE)
        let (x_pow3, _) = unsigned_div_rem (x_pow2 * x, ns_decay_function.UTL_DECAY_SCALE)

        let (term2, _) = unsigned_div_rem (x_pow2, 2)
        let (term3, _) = unsigned_div_rem (x_pow3, 6)

        let decay_factor = unity - x + term2 - term3

        return (decay_factor)
    end

    func utl_energy_should_receive_per_tick {range_check_ptr} (
            energy_source : felt,
            length : felt
        ) -> (
            energy_should_receive : felt
        ):
        alloc_locals

        let (local f) = utl_energy_should_send_per_tick (energy_source)
        let (local g) = utl_set_length_to_decay_factor (length)
        local denominator = ns_decay_function.UTL_DECAY_SCALE

        let (energy_should_receive, _) = unsigned_div_rem (f*g, denominator)

        return (energy_should_receive)
    end
end
