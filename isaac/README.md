
## ##################
## Principle
## ##################
# no upgradeability - all children contract addresses are hardcoded in public server contract
# to upgrade is to redploy the entire contract set at different addresses
# such that deployed worlds are guaranteed immutable from everyone

## #############
## Contract list
## #############
## EFC_physics.cairo (stateless)
## EFC_elements.cairo (?)
##


## physics functions - ideally symplectic
func _rk4 ()
func _eval_gravitational ()
func _forward_world_dt ()

## ########################
## Elements erc-1155 (lite)
## ########################
# Iron (Fe)
# Aluminum (Al)
# Copper (Cu)
# Silicon (Si)
# Plutonium (Pu)
## Purity is simplified into having n different grades for each element,
## n can be different across elements.


## #######################
## Devices erc-1155 (lite)
## #######################
# Solar Power Generator (SPG)
# Nuclear Power Generator (NPG)
# Metal Harvester (MH)
# Semiconductor Harvester (SH)
# Metal Refinery (MR)
# Semiconductor Refinery (SR)

## ######################################################
## UTB/UTL
## need a standard to add label
## so that one contiguous belt/line shares a unique label
## representing dynamic sets
## ######################################################
# Universal Transport Belt (UTB) - for any resource
# Universal Transmission Line (UTL) - for power output from any power generator
# Plutonium Enrichment Facility (PEF)
# Nuclear Driller & Propulsion Engine (NDPE)
# - use nuclear fission to create an upward vortex, sucking high-density planet core matter from beneath the ground
# - and push it upward perpendicular to earth surface
# - reducing earth mass at the same time.
# - TODO: think penalty if going below minimum safe earth mass -- reduce earth cube dimension? end the game immediately?

## ########################################
## Production erc-721 (lite)
## can add variability for production rates
## encouraging players to collaborate by
## global optimize strategic OPSF placement
## ########################################
# Omnipotent Production and Storage Facility and Storage (OPSF)
# - can store unlimited amount of resources (coming from harvester / transport belt) and completed devices

## #####################
## Game server functions
## #####################
@external
func forward_world ()
# - forward at macro scale: trisolar system physics
# - forward at micro scale: production stats on the planet; iterate over harvestors, refinery, transmission/transport, PEF / OPSF
# open question - if asking the "unfortunate user" at the beginning of each block to call this, would tx step resource depletes?
# what are the alternatives: yagi; our own node calling it? not to mention if fee kicks in.

# every player starts with one solar panel, one metal harvester, and one OPSF.
@external
func device_deploy (at, type)

@external
func device_pickup (at, type)

@external
func device_transfer (to, type, amount)

@external
func utb_deploy (locs_len, locs)

@external
func utb_pickup (locs_len, locs)

@external
func utl_deploy (locs_len, locs)

@external
func utl_pickup (locs_len, locs)

@external
func opsf_collect_device ()

@external
func opsf_unqueue_for_device ()

@external
func opsf_clear_queue_for_device ()
