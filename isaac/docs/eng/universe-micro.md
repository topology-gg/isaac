# Micro simulation

### Grid coordinate system
<img src="/assets/images/micro_grid.png"/>

### Natural resources

##### Element types
All element types are defined in the namespace `core/contracts/design/constants.cairo` :: `ns_element_types`.

| element type index | Name                   |
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

| device type index  | Name                                             | Description                                                              |
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
| 12                 | Universal Transporation Belt (UTB)               | Logistical device able to transport any element via contiguous placement |
| 13                 | Universal Transmission Line (UTL)                | Logistical device able to transport energy via contiguous placement    |
| 14                 | Universal Production & Storage Factility (UPSF)  | Production & storage device for constructing any device including itself |
| 15                 | Nuclear Driller & Propulsion Engine (NDPE)       | A device that is planted on the surface of the planet, drills the planet matter underneath, and propels the matter upward with energy generated from nuclear fission to exert reverse impulse to the planet |

##### Construction
There are resource and energy requirement for constructing devices.

- Resource requirement is defined in the namespace `core/contracts/util/manufacturing.cairo` :: `ns_manufacturing`.
- For energy requirement is defined in the namespace `core/contracts/design/constants.cairo` :: `ns_energy_requirements`.

These requirement numbers are subject to update.

##### Placement
- device footprint
- contiguity test for utx
__TODO__ figures showing utx contiguity across faces/corners of the planet

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

The transportation mechanics is regulated in `core/contracts/util/logistics.cairo` :: `ns_logistics_utb`.

### Power logistics

##### Power generation
Power generation devices include solar power generator (SPG) and nuclear power generator (NPG):
- SPG's rate of power generation depends on solar exposure
- otherwise rate is generally a function of energy supplied

##### Power transmission
A deployed and contiguous set of UTLs transports energy from its power-generating source device to its power-consuming destination device. Note that the rate of transmission is the product of `the quantity of energy at source device` and `a decay factor`. Having the quantity of energy at source device in the product creates a **forward pressure** effect. The decay factor is an **exponential decay over the length** of UTL set, which reflects transmission efficiency drop over increased distance.

The transmission mechanics is regulated in `core/contracts/util/logistics.cairo` :: `ns_logistics_utl`.

### Micro world forwarding
- analogous to circuit simuation

