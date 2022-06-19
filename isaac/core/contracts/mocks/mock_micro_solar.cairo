%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from contracts.micro.micro_solar import (
    ns_micro_solar,
    MacroStatesForTransform
)
from contracts.util.structs import (
    Vec2, Dynamics
)
from contracts.util.numerics import (sine_7th)

@view
func mock_get_solar_exposure_fp {range_check_ptr} (
        grid : Vec2,
        macro_states : MacroStatesForTransform,
    ) -> (
        exposure_fp : felt
    ):

    let (exposure_fp) = ns_micro_solar.get_solar_exposure_fp (
        grid,
        macro_states
    )

    return (exposure_fp)
end

@view
func mock_get_macro_states_for_transform {range_check_ptr} (
        macro_state : Dynamics,
        phi : felt
    ) -> (
        macro_states_for_transform : MacroStatesForTransform
    ):

    let (macro_states_for_transform) = ns_micro_solar.get_macro_states_for_transform (
        macro_state, phi
    )

    return (macro_states_for_transform)
end

@view
func mock_sine_7th {range_check_ptr} (
    theta : felt) -> (value : felt):

    let (value) = sine_7th (theta)

    return (value)
end
