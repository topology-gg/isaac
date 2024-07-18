%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.util.structs import (Vec2)
from contracts.util.logistics import (
    ns_logistics_harvester,
    ns_logistics_transformer,
    ns_logistics_xpg,
    ns_logistics_utb, ns_logistics_utl
)

@view
func mock_harvester_resource_concentration_to_quantity_per_tick {} (
        resource_type : felt,
        concentration : felt
    ) -> (
        base_quantity : felt
    ):

    let (base_quantity) = ns_logistics_harvester.harvester_resource_concentration_to_quantity_per_tick (
        resource_type,
        concentration
    )

    return (base_quantity)
end

@view
func mock_harvester_energy_to_boost_factor {} (
        resource_type : felt,
        energy : felt
    ) -> (boost_factor : felt):

    let (boost_factor) = ns_logistics_harvester.harvester_energy_to_boost_factor (
        resource_type,
        energy
    )

    return (boost_factor)
end

@view
func mock_harvester_quantity_per_tick {range_check_ptr} (
        resource_type : felt,
        concentration : felt,
        energy : felt
    ) -> (
        quantity : felt
    ):

    let (quantity) = ns_logistics_harvester.harvester_quantity_per_tick (
        resource_type,
        concentration,
        energy
    )

    return (quantity)
end

################

@view
func mock_transformer_resource_type_to_base_quantity_per_tick {} (
        resource_type_from : felt
    ) -> (
        base_quantity_to : felt
    ):

    let (base_quantity_to) = ns_logistics_transformer.transformer_resource_type_to_base_quantity_per_tick (
        resource_type_from
    )

    return (base_quantity_to)
end

@view
func mock_transformer_energy_to_boost_factor {} (
        resource_type : felt,
        energy : felt
    ) -> (boost_factor : felt):

    let (boost_factor) = ns_logistics_transformer.transformer_energy_to_boost_factor (
        resource_type,
        energy
    )

    return (boost_factor)
end

@view
func mock_transformer_quantity_per_tick {range_check_ptr} (
        resource_type : felt,
        energy : felt
    ) -> (
        quantity_to : felt
    ):

    let (quantity_to) = ns_logistics_transformer.transformer_quantity_per_tick (
        resource_type,
        energy
    )

    return (quantity_to)
end

################

@view
func mock_spg_solar_exposure_to_energy_generated_per_tick {range_check_ptr} (
    solar_exposure : felt) -> (energy_generated : felt):

    let (energy_generated) = ns_logistics_xpg.spg_solar_exposure_to_energy_generated_per_tick (
        solar_exposure
    )

    return (energy_generated)
end

@view
func mock_npg_energy_supplied_to_energy_generated_per_tick {range_check_ptr} (
    energy_supplied : felt) -> (energy_generated : felt):

    let (energy_generated) = ns_logistics_xpg.npg_energy_supplied_to_energy_generated_per_tick (
        energy_supplied
    )

    return (energy_generated)
end

################

@view
func mock_utb_quantity_should_send_per_tick {range_check_ptr} (
    quantity_source) -> (quantity_should_send):

    let (quantity_should_send) = ns_logistics_utb.utb_quantity_should_send_per_tick (
        quantity_source
    )

    return (quantity_should_send)
end

@view
func mock_utb_set_length_to_decay_factor {range_check_ptr} (
    length : felt) -> (decay_factor):

    let (decay_factor) = ns_logistics_utb.utb_set_length_to_decay_factor (
        length
    )

    return (decay_factor)
end

@view
func mock_utb_quantity_should_receive_per_tick {range_check_ptr} (
        quantity_source : felt,
        length : felt
    ) -> (
        quantity_should_receive : felt
    ):

    let (quantity_should_receive) = ns_logistics_utb.utb_quantity_should_receive_per_tick (
        quantity_source,
        length
    )

    return (quantity_should_receive)
end

################

@view
func mock_utl_energy_should_send_per_tick {range_check_ptr} (
    energy_source : felt) -> (energy_should_send : felt):

    let (energy_should_send) = ns_logistics_utl.utl_energy_should_send_per_tick (
        energy_source
    )

    return (energy_should_send)
end

@view
func mock_utl_set_length_to_decay_factor {range_check_ptr} (
    length : felt) -> (decay_factor : felt):

    let (decay_factor) = ns_logistics_utl.utl_set_length_to_decay_factor (
        length
    )

    return (decay_factor)
end

@view
func mock_utl_energy_should_receive_per_tick {range_check_ptr} (
        energy_source : felt,
        length : felt
    ) -> (
        energy_should_receive : felt
    ):

    let (energy_should_receive) = ns_logistics_utl.utl_energy_should_receive_per_tick (
        energy_source,
        length
    )

    return (energy_should_receive)
end