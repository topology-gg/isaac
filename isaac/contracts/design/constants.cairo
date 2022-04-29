from starkware.cairo.common.registers import get_label_location
from contracts.util.structs import (Vec2)

#
# Permission control - if needed
#
const GYOZA = 0x077d04506374b4920d6c35ecaded1ed7d26dd283ee64f284481e2574e77852c6

#
# Duration control
# TODO: may be desirable to forward macro and micro at different time scale
# --> towards multi-scale simulation
#
const MIN_L2_BLOCK_NUM_BETWEEN_FORWARD = 2

#
# Constants for numerical precision / stability
#
const RANGE_CHECK_BOUND = 2 ** 120
const SCALE_FP = 10**20
const SCALE_FP_DIV_100 = 10**18
const SCALE_FP_SQRT = 10**10

#
# Constant for parametrizing perlin generation
#
namespace ns_perlin:
    const SCALER = 666
    const BOUND = 1000
end

#
# Constants for macro physics simulation
#
# orbital
const DT = 5 / 1000 * SCALE_FP
const G         = 1 * SCALE_FP
const MASS_SUN0 = 1 * SCALE_FP
const MASS_SUN1 = 1 * SCALE_FP
const MASS_SUN2 = 1 * SCALE_FP
# rotation
const OMEGA_DT_PLANET = 624 / 100 * 6 / 100 * SCALE_FP # unit: radiant; takes ~100 DT to complete 2*pi
const TWO_PI = 6283185 / 1000000 * SCALE_FP

#
# macro dynamics initialization
#
namespace ns_macro_init:
    const sun0_qx = 397313785856000065536
    const sun0_px = 58970619926547038208
    const sun0_qy = 3618502788666131213697322783095070105623107215331596699873523403847871987713
    const sun0_py = 54690419560055734272
    const sun1_qx = 3618502788666131213697322783095070105623107215331596699575778270279871954945
    const sun1_px = 58970619926547038208
    const sun1_qy = 99568652288000032768
    const sun1_py = 54690419560055734272
    const sun2_qx = 0
    const sun2_px = 3618502788666131213697322783095070105623107215331596699855150816282777944065
    const sun2_qy = 0
    const sun2_py = 3618502788666131213697322783095070105623107215331596699863711217015760551937
    const plnt_qx = 198656892928000032768
    const plnt_px = 3618502788666131213697322783095070105623107215331596699927730040807758913537
    const plnt_qy = 3618502788666131213697322783095070105623107215331596699923307729991872004097
    const plnt_py = 3618502788666131213697322783095070105623107215331596699931022502628136845313

    const phi = 0
end

#
# Constants for planet configuration
#
const PLANET_DIM = 100
# TODO: params to control resource distribution via e.g. perlin noise

#
# Constants for solar power generation parametrization
#
namespace ns_solar_power:
    const MULT = 10
    const BOUND = 100
end

#
# Constants for nuclear power generation parametrization
#
namespace ns_nuclear_power:
    const BASE_ENERGY = 50
    const BOOST_DIVIDER = 20
end

#
# Constants for decay function parametrization
#
namespace ns_decay_function:
    const UTB_DECAY_BASE   = 20
    const UTB_DECAY_LAMBDA = 15
    const UTB_DECAY_SCALE  = 1000

    const UTL_DECAY_BASE   = 20
    const UTL_DECAY_LAMBDA = 18
    const UTL_DECAY_SCALE  = 1000
end

#
# Constants for element type
#
namespace ns_element_types:
    const ELEMENT_FE_RAW = 0 # iron raw
    const ELEMENT_FE_REF = 1 # iron refined
    const ELEMENT_AL_RAW = 2 # aluminum raw
    const ELEMENT_AL_REF = 3 # aluminum refined
    const ELEMENT_CU_RAW = 4 # copper raw
    const ELEMENT_CU_REF = 5 # copper refined
    const ELEMENT_SI_RAW = 6 # silicon raw
    const ELEMENT_SI_REF = 7 # silicon refined
    const ELEMENT_PU_RAW = 8 # plutonium-241 raw
    const ELEMENT_PU_ENR = 9 # plutonium-241 enriched
end

#
# Constants for base multipler_per_tick for harvester per element type
#
namespace ns_base_harvester_multiplier:
    const ELEMENT_FE_RAW = 10 # iron raw
    const ELEMENT_AL_RAW = 8 # aluminum raw
    const ELEMENT_CU_RAW = 6 # copper raw
    const ELEMENT_SI_RAW = 4 # silicon raw
    const ELEMENT_PU_RAW = 2 # plutonium-241 raw
end

#
# Constants for boost factor for harvester per element type
#
namespace ns_harvester_boost_factor:
    const ELEMENT_FE_RAW = 15 # iron raw
    const ELEMENT_AL_RAW = 15 # aluminum raw
    const ELEMENT_CU_RAW = 15 # copper raw
    const ELEMENT_SI_RAW = 15 # silicon raw
    const ELEMENT_PU_RAW = 15 # plutonium-241 raw
    const BOUND = 100
end

#
# Constants for base quantity_per_tick for harvester per element type
#
namespace ns_base_transformer_quantity:
    const ELEMENT_FE_RAW = 5 # iron raw
    const ELEMENT_AL_RAW = 4 # aluminum raw
    const ELEMENT_CU_RAW = 3 # copper raw
    const ELEMENT_SI_RAW = 2 # silicon raw
    const ELEMENT_PU_RAW = 1 # plutonium-241 raw
end

#
# Constants for boost factor for transformer per element type
#
namespace ns_transformer_boost_factor:
    const ELEMENT_FE_RAW = 15 # iron raw
    const ELEMENT_AL_RAW = 15 # aluminum raw
    const ELEMENT_CU_RAW = 15 # copper raw
    const ELEMENT_SI_RAW = 15 # silicon raw
    const ELEMENT_PU_RAW = 15 # plutonium-241 raw
    const BOUND = 100
end

#
# Constants for device type
#
namespace ns_device_types:
    const DEVICE_SPG = 0 # solar power generator
    const DEVICE_NPG = 1 # nuclear power generator
    const DEVICE_FE_HARV = 2 # iron harvester
    const DEVICE_AL_HARV = 3 # aluminum harvester
    const DEVICE_CU_HARV = 4 # copper harvester
    const DEVICE_SI_HARV = 5 # silicon harvester
    const DEVICE_PU_HARV = 6 # plutoniium harvester
    const DEVICE_FE_REFN = 7 # iron refinery
    const DEVICE_AL_REFN = 8 # aluminum refinery
    const DEVICE_CU_REFN = 9 # copper refinery
    const DEVICE_SI_REFN = 10 # silicon refinery
    const DEVICE_PEF = 11 # plutonium enrichment facility
    const DEVICE_UTB = 12 # universal transportation belt
    const DEVICE_UTL = 13 # universal transmission line
    const DEVICE_OPSF = 14 # omnipotent production and storage facility

    const DEVICE_PG_MAX = 1
    const DEVICE_HARVESTER_MIN = 2
    const DEVICE_HARVESTER_MAX = 6
    const DEVICE_TRANSFORMER_MIN = 7
    const DEVICE_TRANSFORMER_MAX = 11
end

func assert_device_type_is_utx {} (device_type : felt) -> ():
    alloc_locals

    if device_type == ns_device_types.DEVICE_UTB:
        return ()
    end

    if device_type == ns_device_types.DEVICE_UTL:
        return ()
    end

    local x = device_type
    with_attr error_message ("device_type ({x}) is neither UTB (12) or UTL (13)."):
        assert 0 = 1
    end
    return ()
end

#
# Every device is a square i.e. xdim == ydim
# possible dimensions: 1x1, 2x2, 3x3, 5x5
# micro.cairo's `assert_device_footprint_populable` deal with these dimensions specifically
# i.e. if adding new dimension, `assert_device_footprint_populable` requires update
#
func get_device_dimension_ptr () -> (ptr : felt*):
    let (data_array) = get_label_location (data)
    return (ptr=cast(data_array, felt*))

    data:
    dw 1 # spg
    dw 3 # npg
    dw 1 # fe harv
    dw 1 # al harv
    dw 1 # cu harv
    dw 1 # si harv
    dw 1 # pu harv
    dw 2 # fe refn
    dw 2 # al refn
    dw 2 # cu refn
    dw 2 # si refn
    dw 2 # pef
    dw 0
    dw 0
    dw 5 # opsf
end


func transformer_device_type_to_element_types {} (device_type : felt) -> (
        element_type_before_transform : felt,
        element_type_after_transform : felt
    ):
    alloc_locals

    if device_type == ns_device_types.DEVICE_FE_REFN:
        return (
            ns_element_types.ELEMENT_FE_RAW,
            ns_element_types.ELEMENT_FE_REF
        )
    end

    if device_type == ns_device_types.DEVICE_AL_REFN:
        return (
            ns_element_types.ELEMENT_AL_RAW,
            ns_element_types.ELEMENT_AL_REF
        )
    end

    if device_type == ns_device_types.DEVICE_CU_REFN:
        return (
            ns_element_types.ELEMENT_CU_RAW,
            ns_element_types.ELEMENT_CU_REF
        )
    end

    if device_type == ns_device_types.DEVICE_SI_REFN:
        return (
            ns_element_types.ELEMENT_SI_RAW,
            ns_element_types.ELEMENT_SI_REF
        )
    end

    if device_type == ns_device_types.DEVICE_PEF:
        return (
            ns_element_types.ELEMENT_PU_RAW,
            ns_element_types.ELEMENT_PU_ENR
        )
    end

    local typ = device_type
    with_attr error_message ("type {typ} is not a transformer device"):
        assert 1 = 0
    end
    return (0, 0)

end

func harvester_device_type_to_element_type {} (device_type : felt) -> (element_type : felt):
    alloc_locals

    local type = device_type

    if device_type == ns_device_types.DEVICE_FE_HARV:
        return (ns_element_types.ELEMENT_FE_RAW)
    end

    if device_type == ns_device_types.DEVICE_AL_HARV:
        return (ns_element_types.ELEMENT_AL_RAW)
    end

    if device_type == ns_device_types.DEVICE_CU_HARV:
        return (ns_element_types.ELEMENT_CU_RAW)
    end

    if device_type == ns_device_types.DEVICE_SI_HARV:
        return (ns_element_types.ELEMENT_SI_RAW)
    end

    if device_type == ns_device_types.DEVICE_PU_HARV:
        return (ns_element_types.ELEMENT_PU_RAW)
    end

    with_attr error_message ("not a harvester device; device_type = {type}"):
        assert 1 = 0
    end
    return (0)

end
