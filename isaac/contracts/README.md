## Technical notes and illustrations

### The grid coordinate system on cube surface
The cube is unfolded to 2d plane with its face & edge labeled as follows:
![image](https://user-images.githubusercontent.com/59590480/160504758-1d957148-f085-4082-bc1d-30bb7e3610b2.png)

The key is here to be able to determine contiguity across faces, because transportation belts and transmission lines are allowed to travel across faces.

### Resource harvest & transportation systems
1. Each device has a maximum amount of resource it can carry
2. Transportation has a decade-over-distance property
3. TODO: deal with source device connected directly with destination device as neighbors
4. TODO: make harvester & refinery potentially bigger than 1x1 

### Trisolar system simulation
1. TODO: use symplectic integrator to avoid energy drift
