
#
# Constants for numerical precision / stability
#
const RANGE_CHECK_BOUND = 2 ** 64
const SCALE_FP = 10**20
const SCALE_FP_SQRT = 10**10

#
# Constants for macro physics simulation
#
const DT = 6 / 100 * SCALE_FP  # 0.06 * 10**20
const OMEGA_DT_PLANET = 624 / 100 * 6 / 100 * SCALE_FP # unit: radiant; takes ~100 DT to complete 2*pi
const TWO_PI = 6283185 / 1000000 * SCALE_FP
const G  = 4 * SCALE_FP
const MASS_SUN0 = 4 * SCALE_FP
const MASS_SUN1 = 4 * SCALE_FP
const MASS_SUN2 = 4 * SCALE_FP

#
# Constants for planet configuration
#
const PLANET_DIM = 100
# TODO: params to control resource distribution via e.g. perlin noise

#
# Constants for cube coordinate system;
# edge 7-10 are the corner grids connected to multiple normal edges (0-6).
# note: I hope we have enums in Cairo ..
#
const FACE_0 = 0
const FACE_1 = 1
const FACE_2 = 2
const FACE_3 = 3
const FACE_4 = 4
const FACE_5 = 5
const EDGE_0 = 0
const EDGE_1 = 1
const EDGE_2 = 2
const EDGE_3 = 3
const EDGE_4 = 4
const EDGE_5 = 5
const EDGE_6 = 6
const EDGE_7 = 7
const EDGE_8 = 8
const EDGE_9 = 9
const EDGE_10 = 10


#
# Constants for element type
#
const ELEMENT_FE = 0 # iron
const ELEMENT_AL = 1 # aluminum
const ELEMENT_CU = 2 # copper
const ELEMENT_SI = 3 # silicon
const ELEMENT_PU = 4 # plutonium-241

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