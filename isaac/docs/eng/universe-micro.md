# Micro simulation

### The micro coordinate system
The planet is shaped like a cube of equal dimension on each side. Denoting the dimension of the cube as `D`, the surface of the cube is endowed with a **grid coordinate system** over integers by **unfolding** the cube to a 2D plane:
<img src="/assets/images/micro_grid.png"/>

where:
- Face 3 is the top face, whose surface normal points upward from the orbital plane; Face 1 surface normal points downward from the orbital plane.
- Face 0 surface normal points toward +x in the **macro coordinate system** when planet rotation is 0.

Apparently, not every integer pair is a **valid grid coordinate** on the surface of the cube. For example, coordinates that lie within the square of `x = 0 ~ D-1` and `y = 0 ~ D-1` are not valid coordinates.

### Natural resources

##### Element types
All element types are defined in the namespace `core/contracts/design/constants.cairo` :: `ns_element_types`.

| Type index | Name                   |
| ------------------ | ---------------------- |
| 0                  | Raw iron               |
| 1                  | Refined iron           |
| 2                  | Raw aluminum           |
| 3                  | Refined aluminum       |
| 4                  | Raw copper             |
| 5                  | Refined copper         |
| 6                  | Raw silicon            |
| 7                  | Refined silicon        |
| 8                  | Raw plutonium-241      |
| 9                  | Enriched plutonium-241 |

##### Perlin noise for distribution
___ TODO ___

### Devices

##### Device types
All device types are defined in the namespace `core/contracts/design/constants.cairo` :: `ns_device_types`.

| Type index  | Name                                             | Description                                                              |
| ------------------ | ------------------------------------------------ | ------------------------------------------------------------------------ |
| 0                  | Solar power generator (SPG)            | A power generation device that generates power from exposure to solar radiation    |
| 1                  | Nuclear power generator (NPG)          | A power generation device that generates power from nuclear fission        |
| 2                  | Iron harvester                         | A harvester device that harvests iron from the planet surface underneath |
| 3                  | Aluminum harvester                     | A harvester device that harvests aluminum from the planet surface underneath |
| 4                  | Copper harvester                       | A harvester device that harvests copper from the planet surface underneath |
| 5                  | Silicon harvester                      | A harvester device that harvests silicon from the planet surface underneath |
| 6                  | Plutonium-241 harvester                | A harvester device that harvests plutonium-241 from the planet surface underneath |
| 7                  | Iron refinery                                    | A transformer device that refines iron that is transported in via UTB    |
| 8                  | Aluminum refinery                                | A transformer device that refines aluminum that is transported in via UTB|
| 9                  | Copper refinery                                  | A transformer device that refines copper that is transported in via UTB  |
| 10                 | Silicon refinery                                 | A transformer device that refines silicon that is transported in via UTB |
| 11                 | Plutonium Enrichment Facility (PEF)      | A transformer device that enriches plutonium-241 that is transported in via UTB |
| 12                 | Universal Transporation Belt (UTB)           | A logistical device able to transport any element via contiguous placement |
| 13                 | Universal Transmission Line (UTL)            | A logistical device able to transport energy via contiguous placement      |
| 14                 | Universal Production & Storage Factility (UPSF)  | Production & storage device for constructing any device including itself |
| 15                 | Nuclear Driller & Propulsion Engine (NDPE)       | A device that is planted on the surface of the planet, drills the planet matter underneath, and propels the matter upward with energy generated from nuclear fission to exert reverse impulse to the planet |

##### Construction
There are resource and energy requirement for constructing devices.

- Resource requirement is defined in the namespace `core/contracts/util/manufacturing.cairo` :: `ns_manufacturing`.
- For energy requirement is defined in the namespace `core/contracts/design/constants.cairo` :: `ns_energy_requirements`.

These requirement numbers are subject to update.

##### Placement
Each device type takes up a **square-shaped footprint** of particular dimension. For example, harvester devices each take up 1x1 area, whereas transformer devices each take up 2x2 area, and each UPSF takes up a 5x5 area. Device overlap is prohibited. Footprint regulation can be found in the function `core/contracts/design/constants.cairo` :: `get_device_dimension_ptr()`

Special placement regulation is enforced with UTB and UTL:
1. A set of UTB/UTL needs to be contiguously placed as a whole. See the following illustration for examples.
2. The beginning coordinate of a set of UTB/UTL needs to neighbor its source device, while its ending coordinate needs to neighbor its destination device.

<img src="/assets/images/contiguity.png"/>
In the above illustration, green squares are source devices with labels starting with S, yellow squares are destination devices with labels starting with D, and blue lines are valid placement of UTB/UTL set. S1 is connected to D1. S3 is connected to D3. Both S2a and S2b are conneted to D2.
<br></br>

##### NDPE launches
To maximize the coordination requirement to survive this reality, Isaac automatically enforces **synchronized NDPE launch**: if **any** deployed NDPE is launched by its owner, **every** deployed NDPE, regardless of its owner, automatically launches at the same tick.


### Resource logistics

##### Resource harvesting
A deployed harvester device would automatically harvest its corresponding resource type from the planet grid underneath.

Note that:
1. The quantity harvested per tick is the **product** of **the resource concentration at the grid** and **an energy boost factor**. The energy boost factor is proportional to the energy supplied to the device via UTL. This mechanic is regulated in the namespace `core/contracts/util/logistics.cairo` :: `ns_logistics_harvester`.
2. Each harvester device has a maximum quantity of raw resource it can carry without having it transported off via UTB. The max carry quantities are regulated in the namespace `core/contracts/design/constants.cairo` :: `ns_harvester_max_carry`.

##### Resource transformation
A deployed transformer device -- refineries (for FE, AL, CU, SI) or enrichment facility (for Pu-241) -- transforms the incoming raw resource (transported in via UTB) into refined/enriched resource.

Note that:
1. In the current design, there is no max-carry constraint enforced on transformer device, which means there is **no backpressure** along the resource pipeline. (Adding backpressure would enforce new constraint for the civilization of players to work with and could very well be a future item based on community decision)
2. The rate of transformation is the **product** of **a base quantity** and **an energy boost factor**. The energy boost factor is proportional to the energy supplied to the device via UTL. This mechanic is regulated in the namespace `core/contracts/util/logistics.cairo` :: `ns_logistics_transformer`.

##### Resource transportation
A deployed and contiguous set of UTBs transports resource from its source device to its destination device. Note that the rate of transportation is the product of `the quantity of resource at source device` and `a decay factor`. Having the quantity of resource at source device in the product creates a **forward pressure** effect. The decay factor is an **exponential decay over the length** of UTB set, which reflects transportation efficiency drop over increased distance.

Note that multiple fan-in (multiple source devices feeding resource to one destination device) and fan-out (one source device feeding resource to multiple destination devices) are doable and sometimes desirable. Fan-in/out are concepts [borrowed](https://en.wikipedia.org/wiki/Fan-in) from the logical circuit design domain.

The transportation mechanics are regulated in `core/contracts/util/logistics.cairo` :: `ns_logistics_utb`.

### Power logistics

##### Power generation
Power generation devices include solar power generator (SPG) and nuclear power generator (NPG):
- SPG's rate of power generation depends on solar exposure, which is computed from which face the SPG is deployed on, planet rotation, and the distance from the planet to the suns. For example, the planet face pointing away from a given sun is in the shadow of the planet and subsequently does not receive solar radiation from that sun. Further, for simplicity, suns are considered completely transparent, meaning a sun's radiation would penetrate another sun with 100% transmittance. These mechanics are regulated in the namespaces `core/contracts/micro/micro_solar.cairo` :: `ns_micro_solar` and `core/contracts/util/logistics.cairo` :: `ns_logistics_xpg`.
- NPG's rate of power generation depends on a base rate and a energy boost factor. The mechanics are regulated in the namespace `core/contracts/util/logistics.cairo` :: `ns_logistics_xpg`.

##### Power transmission
A deployed and contiguous set of UTLs transports energy from its power-generating source device to its power-consuming destination device. Note that the rate of transmission is the product of `the quantity of energy at source device` and `a decay factor`. Having the quantity of energy at source device in the product creates a **forward pressure** effect. The decay factor is an **exponential decay over the length** of UTL set, which reflects transmission efficiency drop over increased distance.

The transmission mechanics is regulated in `core/contracts/util/logistics.cairo` :: `ns_logistics_utl`.

### Micro world forwarding
- analogous to circuit simuation

