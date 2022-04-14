from starkware.cairo.common.registers import get_label_location
from contracts.util.structs import (Vec2)

const GYOZA = 0x077d04506374b4920d6c35ecaded1ed7d26dd283ee64f284481e2574e77852c6

#
# Constants for numerical precision / stability
#
const RANGE_CHECK_BOUND = 2 ** 120
const SCALE_FP = 10**20
const SCALE_FP_DIV_100 = 10**18
const SCALE_FP_SQRT = 10**10

#
# Constants for macro physics simulation
#
# orbital
const DT = 6 / 100 * SCALE_FP
const G  = 1 * SCALE_FP
const MASS_SUN0 = 1 * SCALE_FP
const MASS_SUN1 = 1 * SCALE_FP
const MASS_SUN2 = 1 * SCALE_FP
# rotation
const OMEGA_DT_PLANET = 624 / 100 * 6 / 100 * SCALE_FP # unit: radiant; takes ~100 DT to complete 2*pi
const TWO_PI = 6283185 / 1000000 * SCALE_FP

#
# Constants for planet configuration
#
const PLANET_DIM = 100
# TODO: params to control resource distribution via e.g. perlin noise

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

    const DEVICE_HARVESTER_MIN = 2
    const DEVICE_HARVESTER_MAX = 6
    const DEVICE_TRANSFORMER_MIN = 7
    const DEVICE_TRANSFORMER_MAX = 11
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
