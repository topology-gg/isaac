# Isaac
The naming reflects the Newtonian mechanics involved in this game, and also borrows the sense of world genesis from its connotation with the Bible figure.

### Web client urls (view only)
- Macro view (trisolar system): https://isaac-macro-view.netlify.app/
- Micro view (planet surface): https://isaac-micro-view.netlify.app/

### Narrative
A hypothetical cuboid planet is trapped in a trisolar system where the three suns of identical mass follow roughly a figure-8 trajectory (https://arxiv.org/pdf/math/0011268.pdf)* with perturbation and drifts, making the system chaotic. All players reside on the cuboid planet, forming a interdependent civilization. Every time the planet is crashed into a sun, the civilization is destroyed and reborn, and the planet is reset to full-resource initial state and randomly placed in the trisolar system for the next civilization run. The objective of the game is for players to collectively build sufficient "Nuclear Driller & Propulsion Engines" from harvesting and crafting with natural resources abundant on the planet, place and time their launch strategically to either change their planet's orbit to evade a deadly crash into a sun or produce enough thrust for their planet to escape the hostile trisolar system for good.

*choosing the figure-8 periodic solution is a hack to extend system longenvity - until we have symplectic integrator. 

### Principle
- no upgradeability - all children contract addresses are hardcoded in public server contract; to upgrade is to redploy the entire contract set at different addresses such that deployed worlds are guaranteed immutable from everyone

### Playable components of the game
- Solar Power Generator (SPG)
- Nuclear Power Generator (NPG)
- Elements in [Fe, Al, Cu, Si, Pu] of different purity grades
- Harvester for [Fe, Al, Cu, Si, Pu]
- Refinery for [Fe, Al, Cu, Si]
- Plutonium Enrichment Facility (PEF)
- Universal Transmission Line (UTL)
- Universal Transportation Belt (UTB)
- Omnipotent Production and Storage Facility (OPSF)
- Nuclear Driller & Propulsion Engine (NDPE)

### Game mechanics overview / scratchpad of design thoughts
- The centers of mass of all celestial bodies stay on the same 2D plane - for simplicity; can expand to full-3D in the future.
- The planet has the geometry of a cube (for tight deliverables, dealing with spherical geometry would be intimidating). Players inhabit the surface of a large cube, the size of which is negligible compared to the suns.
- The cube spins around an axis perpendicular to the 2D orbital plane.
- Every L2 block takes ~2min on Starknet testnet currently; we want the entire trisolar period to be ~7 days ⇒ 7*24*60/2 = ~5040 blocks per trisolar period.
- Energy/resource transport instantly from source to destination along their path of transportation; use transmission/transport rate to update energy/resource amount changes at source/destination, instead of placing resource being transported along the path of transporation.

### Technical specs overview
- Deploy a logger contract to record every event - not StarkNet event; custom game event, both macro and micro - since the dawn of each civilization; every new client that starts from blank state and goes through all the event updates would arrive at the same current state i.e. determinstic states; when a new L2 block has passed, clients would pull all events transpired in the last block and fast forward the visualization at frontend.
- Need to design game event struct carefully to retain all information for complete state reconstruction on client side without client having to peak at anywhere else in the contracts
- The dimension of the planet and the dimension of each device, in terms of grid count, are parameterized for tuning & modding. So are physics related parameters.

### Planet configuration
- Resource distribution across the the surface grids of the planet - using perlin noise in server’s constructor() ?

### Player joining the game
- can create a separate contract for signing up, which builds a merkle tree used later for checking permission to play
- or can simply create a function in server contract for signing up, and let that function stay alive for X L2 blocks / seconds
- every player starts with one solar panel, one metal harvester, and one OPSF.

### Foreseeable technical challenges / todos
- make the integrator symplectic to avoid energy drift - crucial for immutable, unstoppable game 
- need to implement collision test between sun-planet, which means game over
- testability of the game contracts
- the state forwarding per L2 block / evaluate the feasibility of lazy evaluation (may need to cache state to circumvent per-tx maximum step of 250k on starknet testnet); if asking the "unfortunate user" at the beginning of each block to forward both macro and micro world state (which won't make sense when fee kicks in), would tx step resource depletes? what are the alternatives: yagi; our own node calling it? not to mention if fee kicks in.
- (when moving to starknet mainnet) fee considerations; if desirable we can ask Starkware to spin up & run a dedicated (centralized) starknet instance for this game with guaranteed proving time, API gateway uptime etc, and Topology pays for associated cost

### Logistics system
- Universal Transport Belt (UTB) - for transporting any resource
- Universal Transmission Line (UTL) - for transporting power from any power generator
- need a build a standard to manage dynamic sets, where each set consists of a contiguous path of UTB/UTL

### Nuclear Driller & Propulsion Engine (NDPE)
- use nuclear fission to create an upward vortex, sucking high-density core matter of the planet from beneath the ground and push it upward perpendicular to the planet's surface
- reducing planet mass at the same time, thus changing orbital dynamics of the planet
- TODO: think penalty if going below minimum safe planet mass -- reduce cube dimension? end the game immediately?

### Omnipotent Production and Storage Facility (OPSF)
- can store unlimited amount of resources (coming from harvester directly / from transport belt) as well as completed devices
- note: player (invisible on the map) can also carry arbitrary amount of devices without cost; this removes the need to design logistics for device transportation or storage, which may be desirable for added complexity and mechanics in later iterations of this game e.g. inter-planetary PvP would call for strategic attack at device storage site
- may have slight variability over production rates for various devices

### The game server functions
- forward world state at macro scale: trisolar system physics
- forward world state at micro scale: production stats on the planet; iterate over harvestors, refinery, transmission/transport, PEF / OPSF

## TODOs:
#### Isaac
- (DONE) Test perlin noise
- (DONE) `logistics.cairo`: parametrize resource transfer rate (function of distance), energy transfer, resource transform/production rate (function of energy supplied); testing
- (DONE) `logistics.cairo` hooks up with `micro.cairo`
- `manufacturing.cairo`: device construction recipes, withdrawal; testing
- hook up `perlin.cairo` x `micro.cairo`
- testing: build model for resource & energy management, then use it to test `logistics.cairo` x `micro.cairo` at world forwarding
- NDPE: launch function + coordinate transform from micro => macro + apply momentum to planet during physics sim; testing
- Game over determination - detecting collision between planet and any of the three suns + testing
- Player transfers device between each other + testing
- event emission for future query needs - at world forwarding, client action performed etc
- documentation: Lucid charts for contract architecture; formula for coord transform, various parametrization schemes

#### Isaac Protocol
- Conceptualise: high-level signup flow, civilisation init & reset procedure, multi-server scheme e.g. 100/1k/10k servers, civ-longevity metrics towards the Isaac protocol; difficulty knobs (init: need to parametrize initial devices for players)
- DAO voting for contract migration determination
- Implement and test isaac-protocol

#### Isaac clients
- utb/utl view carries fraction info, enabling transmission animation in `https://isaac-micro-view.netlify.app/`
- CLI tool for viewing Isaac world - owner stats, grid stats, deployed-device stats by id etc
- web client to visualize planet in unfolded 2D form, mouse hovers showing coordinate

#### Log - completed before defcon demo
- (DONE) resource update at device (naive) + resource transported across transportation belts (naive) + testing
- (DONE) test macro.cairo (forwarding trisolar system and planet rotation)
- (DONE) device pickup + testing
- (DONE) server.cairo initializes macro dynamics; contract deployed to testnet
- (DONE) multi-grid device placement testing
- (DONE) fanin and fanout testing, including OPSF
- (DONE) [demo] visualizer of macro trisolar system
- (DONE) [demo] isaac-client-micro-write: make transaction to e.g. place device
- (DONE) [demo] isaac-client-micro-read: visualizer of micro planet surface activities
- (DONE) isaac-client-micro-write: add form-input for (1) admin give device (2) client pickup device
- (DONE) device-connected-to-multiple-utbs: deal with {storage N->m} or {O(M)} for updating utb emap
- (DONE)[demo] make multi-grid device one contiguous square instead of being drawn as multiple cells individually
- (DONE) use voyager to deploy on UTB-set connecting two devices
- (DONE) isaac-client-micro-read: visualize utb-set connecting harvester and refinery
- (DONE) isaac-client-micro-read: let utb-set slowly blink (color fading)
- (DONE) utl logic: add an extra key to all utb-related storage_var, and modify program accordingly
- (DONE) utl logic: energy update at device + energy transported across utl-set + testing
- (DONE) hook up isaac with yagi (4/17 latest)
- (DONE) getting ready for demo day: deploy more devices, utb-sets
- (DONE) make slide deck and prepare for demo procedure for DEFCON 

#### future items / directions
- layout **Isaac Protocol**: voting power is earned only through gameplay; non tradeable; non transferable; degrade over time (discounting past gameplay contribution) voting power governs the migration of the canonical Isaac contract deploy address so that the DAO can vote yes to a new address; after a rage quit period  the DAO will point to the new address as Isaac server address. Topology will retain most voting power to begin with, and dilute over time. The dilution schedule / function is not thought through yet. Vote is only for upgradeability decision of 1 contract address. "Basically the more you play the more say you have over whatever is played next ... but it decays over time to discount past participation; may need another vote for changing vote calculation & discount factor" -- this will be the first **"Republik"**
- symplectic integration - check out https://github.com/hannorein/rebound and https://rebound.readthedocs.io/en/latest/#papers
- planet core convection, manifesting as dynamic resource distribution on the surface
