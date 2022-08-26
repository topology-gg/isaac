from starkware.cairo.common.registers import get_label_location
from contracts.util.structs import (Vec2)
from starkware.cairo.common.alloc import alloc

#
# Permission control - if needed
#
const GYOZA = 0x02f880133db4F533Bdbc10C3d02FBC9b264Dac2Ff52Eae4e0cEc0Ce794BAd898

#
# Duration control
# TODO: may be desirable to forward macro and micro at different time scale -> towards multi-scale simulation
#
const MIN_L2_BLOCK_NUM_BETWEEN_FORWARD = 1 # this results in 2 blocks between consecutive ticks
const UNIVERSE_MAX_AGE_IN_TICKS = 2520 # ~7 days, given 2 blocks (4 minutes) per tick

#
# Capacity control - size of civilization per universe, and number of universes deployed
#
const CIV_SIZE = 5
const UNIVERSE_COUNT = 1

#
# Constants for numerical precision / stability
#
const RANGE_CHECK_BOUND = 2 ** 120
const SCALE_FP = 10**20
const SCALE_FP_DIV_100 = 10**18
const SCALE_FP_DIV_1000 = 10**17
const SCALE_FP_DIV_10000 = 10**16
const SCALE_FP_DIV_100000 = 10**15
const SCALE_FP_DIV_10_POW_6 = 10**14
const SCALE_FP_DIV_10000_SQ = 10**12
const SCALE_FP_DIV_10_POW_10 = 10**10
const SCALE_FP_SQRT = 10**10

#
# Constants for macro physics simulation
#
## Orbital
const DT = 5 * SCALE_FP_DIV_1000
const G         = 256 * SCALE_FP_DIV_100 # 2.56
const MASS_SUN0 = 256 * SCALE_FP_DIV_100
const MASS_SUN1 = 256 * SCALE_FP_DIV_100
const MASS_SUN2 = 256 * SCALE_FP_DIV_100
const MASS_PLNT = 1 * SCALE_FP_DIV_10000
const G_MASS_SUN0 = 65536 * SCALE_FP_DIV_10000 # 2.56 * 2.56 = 6.5536
const G_MASS_SUN1 = 65536 * SCALE_FP_DIV_10000
const G_MASS_SUN2 = 65536 * SCALE_FP_DIV_10000

# const RADIUS_SUN0 = 1495 * SCALE_FP_DIV_1000 # 1.495
# const RADIUS_SUN1 = 862 * SCALE_FP_DIV_1000 # 0.862
# const RADIUS_SUN2 = 383 * SCALE_FP_DIV_1000 # 0.383
const RADIUS_SUN0 = 89  * SCALE_FP_DIV_100 # 0.89
const RADIUS_SUN1 = 136 * SCALE_FP_DIV_100 # 1.36
const RADIUS_SUN2 = 61  * SCALE_FP_DIV_100 # 0.61
const RADIUS_SUN0_SQ = 89 * 89  * SCALE_FP_DIV_10000 # 0.89**2 = 0.7921
const RADIUS_SUN1_SQ = 136 * 136 * SCALE_FP_DIV_10000 # 1.36**2 = 1.8496
const RADIUS_SUN2_SQ = 61 * 61  * SCALE_FP_DIV_10000 # 0.61**2 = 0.3721

## Rotation
# const OMEGA_DT_PLANET = 624 / 100 * 6 / 100 * SCALE_FP # unit: radiant; takes ~100 DT to complete 2*pi
const TWO_PI = 6283185 * SCALE_FP / 1000000
const PI = TWO_PI / 2
const DELTA_PHI_PLANET = TWO_PI / 100 # 100 ticks per planet revolution

#
# Constants for perturbation applied to planet dynamic macro physics simulation:
# given planet's qd (Vec2),
# the unrotated perturbation vector would be `Vec2 (-qd.x, -qd.y) * MULTIPLIER`;
# the final perturbation vector would be the unrotated perturbation vector rotated by a random radian between a bound
# defined by ROTATION_BOUND.
#
## Determining MULTIPLIER:
##   forwarding 24 * 60 / 4 = 360 times everyday; aiming for 1% degrade everyday
##   => we want `(1-x)^360 = 0.99`
##   => `multiplier = 0.000027917 ~= 279170 * SCALE_FP_DIV_10_POW_10`
## Determining ROTATION_BOUND:
##   we want +- 15 degrees;
##   15 degrees = 0.523599 in radian ~= 5236 * SCALE_FP_DIV_10000 in fp
namespace ns_perturb:
    const MULTIPLIER = 279170 * SCALE_FP_DIV_10_POW_10
    const ROTATION_BOUND = 5236 * SCALE_FP_DIV_10000
end

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
const SCALE_FP_DIV_PLANET_DIM = SCALE_FP / PLANET_DIM

#
# Constants for solar power generation parametrization
#
namespace ns_solar_power:
    const BASE_RADIATION = 375 * SCALE_FP
    const OBLIQUE_RADIATION = 75 * SCALE_FP
    const MULT = 2
    const BOUND = 1
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

    const ELEMENT_COUNT = 10
end


#
# Constant for parametrizing perlin generation
#
namespace ns_perlin:

    func random_vector_lookup {range_check_ptr} (
            element_type : felt, idx : felt
        ) -> (
            rv : Vec2
        ):
        alloc_locals

        let (fe_rvs : Vec2*) = alloc ()
        assert fe_rvs[0] = Vec2 (0, -5)
        assert fe_rvs[1] = Vec2 (-14, -22)
        assert fe_rvs[2] = Vec2 (-2, 28)
        assert fe_rvs[3] = Vec2 (9, 12)

        let (al_rvs : Vec2*) = alloc ()
        assert al_rvs[0] = Vec2 (15, -5)
        assert al_rvs[1] = Vec2 (-15, 8)
        assert al_rvs[2] = Vec2 (-25, -12)
        assert al_rvs[3] = Vec2 (2, 8)

        let (cu_rvs : Vec2*) = alloc ()
        assert cu_rvs[0] = Vec2 (4, 6)
        assert cu_rvs[1] = Vec2 (-10, 10)
        assert cu_rvs[2] = Vec2 (-15, -30)
        assert cu_rvs[3] = Vec2 (20, -10)

        let (si_rvs : Vec2*) = alloc ()
        assert si_rvs[0] = Vec2 (15, 25)
        assert si_rvs[1] = Vec2 (-15, 8)
        assert si_rvs[2] = Vec2 (-25, -12)
        assert si_rvs[3] = Vec2 (-12, 8)

        let (pu_rvs : Vec2*) = alloc ()
        assert pu_rvs[0] = Vec2 (-15, -15)
        assert pu_rvs[1] = Vec2 (-15, 8)
        assert pu_rvs[2] = Vec2 (20, 12)
        assert pu_rvs[3] = Vec2 (2, 8)

        if element_type == ns_element_types.ELEMENT_FE_RAW:
            return (fe_rvs [idx])
        end

        if element_type == ns_element_types.ELEMENT_AL_RAW:
            return (al_rvs [idx])
        end

        if element_type == ns_element_types.ELEMENT_CU_RAW:
            return (cu_rvs [idx])
        end

        if element_type == ns_element_types.ELEMENT_SI_RAW:
            return (si_rvs [idx])
        end

        if element_type == ns_element_types.ELEMENT_PU_RAW:
            return (pu_rvs [idx])
        end

        with_attr error_message ("Invalid element type."):
            assert 1 = 0
        end
        return (Vec2(0,0))

    end

    func get_offset {range_check_ptr} (
            element_type : felt
        ) -> (
            offset : felt
        ):

        if element_type == ns_element_types.ELEMENT_FE_RAW:
            return (9)
        end

        if element_type == ns_element_types.ELEMENT_AL_RAW:
            return (5)
        end

        if element_type == ns_element_types.ELEMENT_CU_RAW:
            return (4)
        end

        if element_type == ns_element_types.ELEMENT_SI_RAW:
            return (3)
        end

        if element_type == ns_element_types.ELEMENT_PU_RAW:
            return (2)
        end

        with_attr error_message ("Invalid element type."):
            assert 1 = 0
        end
        return (0)
    end

    const BOUND = 50
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
# Constants for maximum energy carry quantity for each pg type
#
namespace ns_pg_max_carry:
    const DEVICE_SPG = 1000
    const DEVICE_NPG = 20000
end

#
# Constants for maximum carry quantity for each harvester type
#
namespace ns_harvester_max_carry:
    const ELEMENT_FE_RAW = 1000 # iron raw
    const ELEMENT_AL_RAW = 1000 # aluminum raw
    const ELEMENT_CU_RAW = 500 # copper raw
    const ELEMENT_SI_RAW = 500 # silicon raw
    const ELEMENT_PU_RAW = 200 # plutonium-241 raw
end

namespace ns_transformer_max_carry:
    const ELEMENT_FE_RAW = 1000 # iron raw
    const ELEMENT_AL_RAW = 1000 # aluminum raw
    const ELEMENT_CU_RAW = 500 # copper raw
    const ELEMENT_SI_RAW = 500 # silicon raw
    const ELEMENT_PU_RAW = 200 # plutonium-241 raw
end

namespace ns_ndpe_max_carry:
    const ENERGY = 2500
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
    const DEVICE_UPSF = 14 # universal production and storage facility
    const DEVICE_NDPE = 15 # nuclear driller & propulsion engine

    const DEVICE_TYPE_COUNT = 16
    const DEVICE_PG_MAX = 1
    const DEVICE_HARVESTER_MIN = 2
    const DEVICE_HARVESTER_MAX = 6
    const DEVICE_TRANSFORMER_MIN = 7
    const DEVICE_TRANSFORMER_MAX = 11
end

#
# Constants for energy requirement for device construction per device type
# Note: resource requirement is coded in `manufacturing.cairo`
#
namespace ns_energy_requirements:
    const DEVICE_SPG     = 200  # solar power generator
    const DEVICE_NPG     = 5000 # nuclear power generator
    const DEVICE_FE_HARV = 100  # iron harvester
    const DEVICE_AL_HARV = 100  # aluminum harvester
    const DEVICE_CU_HARV = 100  # copper harvester
    const DEVICE_SI_HARV = 100  # silicon harvester
    const DEVICE_PU_HARV = 100 # plutoniium harvester
    const DEVICE_FE_REFN = 500  # iron refinery
    const DEVICE_AL_REFN = 500  # aluminum refinery
    const DEVICE_CU_REFN = 500  # copper refinery
    const DEVICE_SI_REFN = 500  # silicon refinery
    const DEVICE_PEF     = 1000 # plutonium enrichment facility
    const DEVICE_UTB     = 25  # universal transportation belt
    const DEVICE_UTL     = 25  # universal transmission line
    const DEVICE_UPSF    = 5000 # universal production and storage facility
    const DEVICE_NDPE    = 5000 # nuclear driller & propulsion engine
end

#
# Constants to describe the shape of piecewise linear function
# for computing impulse generated by NDPE
#
namespace ns_ndpe_impulse_function:
    const Y_OFFSET_1 = 10**12
    const SLOPE_1 = 10**9
    const X_THRESH_1_2 = 500

    const Y_OFFSET_2 = 10**13
    const SLOPE_2 = 10**10
    const X_THRESH_2_3 = 2000

    const Y_OFFSET_3 = 10**14
    const SLOPE_3 = 2 * (10**11)
end

func assert_device_type_is_nonfungible {} (device_type : felt) -> ():
    alloc_locals

    if device_type == ns_device_types.DEVICE_UTB:
        with_attr error_message ("device_type is 12 (UTB), which is fungible"):
            assert 0 = 1
        end
    end

    if device_type == ns_device_types.DEVICE_UTL:
        with_attr error_message ("device_type is 13 (UTL), which is fungible"):
            assert 0 = 1
        end
    end

    return ()
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
    with_attr error_message ("device_type ({x}) is neither 12 (UTB) or 13 (UTL)."):
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
    dw 5 # ndpe
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

func pg_device_type_to_max_carry {} (device_type : felt) -> (max_carry : felt):
    alloc_locals

    if device_type == ns_device_types.DEVICE_SPG:
        return (ns_pg_max_carry.DEVICE_SPG)
    end

    if device_type == ns_device_types.DEVICE_NPG:
        return (ns_pg_max_carry.DEVICE_NPG)
    end

    local type = device_type
    with_attr error_message ("not a pg device type; device_type = {type}"):
        assert 1 = 0
    end
    return (0)
end

func harvester_element_type_to_max_carry {} (element_type : felt) -> (max_carry : felt):
    alloc_locals

    if element_type == ns_element_types.ELEMENT_FE_RAW:
        return (ns_harvester_max_carry.ELEMENT_FE_RAW)
    end

    if element_type == ns_element_types.ELEMENT_AL_RAW:
        return (ns_harvester_max_carry.ELEMENT_AL_RAW)
    end

    if element_type == ns_element_types.ELEMENT_CU_RAW:
        return (ns_harvester_max_carry.ELEMENT_CU_RAW)
    end

    if element_type == ns_element_types.ELEMENT_SI_RAW:
        return (ns_harvester_max_carry.ELEMENT_SI_RAW)
    end

    if element_type == ns_element_types.ELEMENT_PU_RAW:
        return (ns_harvester_max_carry.ELEMENT_PU_RAW)
    end

    local type = element_type

    with_attr error_message ("not a harvestable element type; element_type = {type}"):
        assert 1 = 0
    end
    return (0)
end


func transformer_element_type_to_max_carry {} (element_type : felt) -> (max_carry : felt):
    alloc_locals

    if element_type == ns_element_types.ELEMENT_FE_RAW:
        return (ns_transformer_max_carry.ELEMENT_FE_RAW)
    end

    if element_type == ns_element_types.ELEMENT_AL_RAW:
        return (ns_transformer_max_carry.ELEMENT_AL_RAW)
    end

    if element_type == ns_element_types.ELEMENT_CU_RAW:
        return (ns_transformer_max_carry.ELEMENT_CU_RAW)
    end

    if element_type == ns_element_types.ELEMENT_SI_RAW:
        return (ns_transformer_max_carry.ELEMENT_SI_RAW)
    end

    if element_type == ns_element_types.ELEMENT_PU_RAW:
        return (ns_transformer_max_carry.ELEMENT_PU_RAW)
    end

    local type = element_type

    with_attr error_message ("not a transformable element type; element_type = {type}"):
        assert 1 = 0
    end
    return (0)
end