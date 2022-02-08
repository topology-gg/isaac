# Fountain
A 2-dimensional physics engine written in Cairo


### 2-dimensional ellastic collision
![image](https://user-images.githubusercontent.com/59590480/152895476-b6c0ec94-174d-4abe-b452-ee77640b8f33.png)

source: https://en.wikipedia.org/wiki/Elastic_collision


### Physics engine
- `euler_step_single_circle_aabb_boundary()`: Forward the position and velocity of one circle by one step with Euler method, where the circle is bounded by an axis-aligned box
- `collision_pair_circles`(): For two circle objects, given their current positions and next candidate positions, which come from Euler forward function, detect if they would have collided, and handle the collision by snapping them to the point of impact, and set their velocities assuming fully elastic collision. Note that this function assumes the two circle objects to share the same radius value, and that it does not handle potential tunneling effect.
- `friction_single_circle()`: Handle acceleration recalculation with kinetic friction


### Scene forwarder
- `forward_scene_capped_counting_collision()`: Forward a scene of circle objects by cap number of steps, where each step involves forwarding each object with Euler method, handling all possible collisions, and recalculate acceleration based on friction. The function keeps count of collision occurences between all pairs of objects.
