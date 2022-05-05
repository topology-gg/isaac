%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le, sign)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    SCALE_FP, PI,
    ns_solar_power
)
from contracts.util.structs import (
    Vec2, Dynamics
)
from contracts.macro.macro_state import (
    ns_macro_state_functions
)
from contracts.macro.macro_simulation import (
    mul_fp, div_fp, div_fp_ul, sqrt_fp
)
from contracts.util.grid import (
    locate_face_and_edge_given_valid_grid
)

##############################

struct MacroDistanceSquares:
    member distance_sq_to_sun0 : felt
    member distance_sq_to_sun1 : felt
    member distance_sq_to_sun2 : felt
end

struct MacroVectors:
    member vector_plnt_to_sun0 : Vec2
    member vector_plnt_to_sun1 : Vec2
    member vector_plnt_to_sun2 : Vec2
end

struct PlanetSideSurfaceNormals:
    member normal_side0 : Vec2
    member normal_side2 : Vec2
    member normal_side4 : Vec2
    member normal_side5 : Vec2
end

struct MacroStatesForTransform:
    member macro_distances : MacroDistanceSquares
    member macro_vectors : MacroVectors
    member planet_side_surface_normals : PlanetSideSurfaceNormals
end

namespace ns_micro_solar:

    func distance_square {range_check_ptr} (
            pos0 : Vec2, pos1 : Vec2
        ) -> (res : felt):
        alloc_locals

        let x_delta = pos0.x - pos1.x
        let (x_delta_sq) = mul_fp (x_delta, x_delta)

        let y_delta = pos0.y - pos1.y
        let (y_delta_sq) = mul_fp (y_delta, y_delta)

        let res = x_delta_sq + y_delta_sq

        return (res)
    end

    func get_macro_distance_squares {range_check_ptr} (
            macro_state : Dynamics
        ) -> (
            macro_distance_squares : MacroDistanceSquares
        ):
        let (distance_sq_to_sun0) = distance_square (macro_state.sun0.q, macro_state.plnt.q)
        let (distance_sq_to_sun1) = distance_square (macro_state.sun1.q, macro_state.plnt.q)
        let (distance_sq_to_sun2) = distance_square (macro_state.sun2.q, macro_state.plnt.q)

        return (MacroDistanceSquares (
            distance_sq_to_sun0,
            distance_sq_to_sun1,
            distance_sq_to_sun2
        ))
    end

    func get_macro_vectors {range_check_ptr} (
            macro_state : Dynamics
        ) -> (
            macro_vectors : MacroVectors
        ):
        return (MacroVectors(
            vector_plnt_to_sun0 = Vec2(macro_state.sun0.q.x - macro_state.plnt.q.x, macro_state.sun0.q.y - macro_state.plnt.q.y),
            vector_plnt_to_sun1 = Vec2(macro_state.sun1.q.x - macro_state.plnt.q.x, macro_state.sun1.q.y - macro_state.plnt.q.y),
            vector_plnt_to_sun2 = Vec2(macro_state.sun2.q.x - macro_state.plnt.q.x, macro_state.sun2.q.y - macro_state.plnt.q.y)
        ))
    end

    func sine_7th {range_check_ptr} (
        theta : felt) -> (value : felt):
        alloc_locals

        #
        # sin(theta) ~= theta - theta^3/3! + theta^5/5! - theta^7/7!
        #

        local theta_norm
        let (bool) = is_le (PI, theta)
        if bool == 1:
            assert theta_norm = theta - PI
        else:
            assert theta_norm = theta
        end

        let (local theta_2) = mul_fp (theta_norm, theta_norm)
        let (local theta_3) = mul_fp (theta_2, theta_norm)
        let (local theta_5) = mul_fp (theta_2, theta_3)
        let (local theta_7) = mul_fp (theta_2, theta_5)

        let (theta_3_div6) = div_fp_ul (theta_3, 6)
        let (theta_5_div120) = div_fp_ul (theta_5, 120)
        let (theta_7_div5040) = div_fp_ul (theta_7, 5040)

        let value = theta_norm - theta_3_div6 + theta_5_div120 - theta_7_div5040

        if bool == 1:
            return (-value)
        else:
            return (value)
        end
    end

    func dot_fp {range_check_ptr} (
        v1 : Vec2, v2 : Vec2) -> (dot : felt):

        let (x_prod) = mul_fp (v1.x, v2.x)
        let (y_prod) = mul_fp (v1.y, v2.y)

        return (x_prod + y_prod)
    end

    func magnitude_fp {range_check_ptr} (
        v : Vec2) -> (mag : felt):

        let (vx_sq) = mul_fp (v.x, v.x)
        let (vy_sq) = mul_fp (v.y, v.y)
        let (mag) = sqrt_fp (vx_sq + vy_sq)

        return (mag)
    end

    func compute_vector_rotate {range_check_ptr} (
        vec : Vec2, phi : felt) -> (vec_rotated : Vec2):
        alloc_locals

        #
        # Compute cos(phi) and sin(phi)
        #
        let (local sin_phi) = sine_7th (phi)
        let (local sin_phi_sq) = mul_fp (sin_phi, sin_phi)
        local phi_ = phi
        with_attr error_message ("sqrt(1-sin^2) went wrong, with sin(phi) = {sin_phi}, phi = {phi_}"):
            let (cos_phi) = sqrt_fp (1*SCALE_FP - sin_phi_sq)
        end

        #
        # Apply rotation matrix
        # [[cos -sin],
        #  [sin  cos]]
        # => [x*cos - y*sin, x*sin + y*cos]
        #
        let (x_mul_cos) = mul_fp (vec.x, cos_phi)
        let (x_mul_sin) = mul_fp (vec.x, sin_phi)
        let (y_mul_cos) = mul_fp (vec.y, cos_phi)
        let (y_mul_sin) = mul_fp (vec.y, sin_phi)
        let vec_rotated : Vec2 = Vec2 (
            x_mul_cos - y_mul_sin,
            x_mul_sin + y_mul_cos
        )

        return (vec_rotated)
    end

    func compute_vector_rotate_90 {range_check_ptr} (
        vec : Vec2) -> (vec_rotated : Vec2):

        #
        # Apply rotation matrix
        # [[0 -1],
        #  [1  0]]
        # => [-y, x]
        #
        let vec_rotated : Vec2 = Vec2 (-vec.y, vec.x)

        return (vec_rotated)
    end

    func get_surface_normals {range_check_ptr} (
        phi : felt) -> (surface_normals : PlanetSideSurfaceNormals):

        #
        # Create unit vector in macro coordinate system
        #
        let unit_vec : Vec2 = Vec2 (1 * SCALE_FP, 0)

        #
        # Rotate unit vector by `phi`, `phi+pi/2`, `phi+pi`, `phi+3*pi/2`
        # to obtain surface normals of all sides (excluding top & bottom)
        #
        let (normal_side0 : Vec2) = compute_vector_rotate (unit_vec, phi)
        let (normal_side2 : Vec2) = compute_vector_rotate_90 (normal_side0)
        let (normal_side4 : Vec2) = compute_vector_rotate_90 (normal_side2)
        let (normal_side5 : Vec2) = compute_vector_rotate_90 (normal_side4)

        return (PlanetSideSurfaceNormals(
            normal_side0,
            normal_side2,
            normal_side4,
            normal_side5
        ))
    end

    func get_macro_states_for_transform {range_check_ptr} (
            macro_state : Dynamics,
            phi : felt
        ) -> (
            macro_states_for_transform : MacroStatesForTransform
        ):
        alloc_locals
        let (macro_distance_squares) = get_macro_distance_squares (macro_state)
        let (macro_vectors) = get_macro_vectors (macro_state)
        let (surface_normals) = get_surface_normals (phi)

        return (MacroStatesForTransform (
            macro_distance_squares,
            macro_vectors,
            surface_normals
        ))
    end

    func get_solar_exposure_fp {range_check_ptr} (
            grid : Vec2,
            macro_states : MacroStatesForTransform,
        ) -> (
            exposure_fp : felt
        ):
        alloc_locals

        ## note: assuming no occlusion i.e. solar radiation of one sun can "penetrate" perfectly another sun

        #
        # Identify face given grid
        #
        let (face, _, _, _) = locate_face_and_edge_given_valid_grid (grid)

        #
        # Calculate exposure in subroutines depending on side vs nonside
        #
        let (bool) = face_is_top_or_bottom (face)
        if bool == 1:
            let (exposure) = get_solar_exposure_nonside (macro_states)
            return (exposure)
        else:
            let (exposure) = get_solar_exposure_side (face, macro_states)
            return (exposure)
        end
    end

    func get_solar_exposure_nonside {range_check_ptr} (
            macro_states : MacroStatesForTransform
        ) -> (
            exposure : felt
        ):
        alloc_locals

        #
        # For each sun, calculate exposure
        #
        let (dist_0_sq) = mul_fp (
            macro_states.macro_distances.distance_sq_to_sun0,
            macro_states.macro_distances.distance_sq_to_sun0
        )
        let (dist_1_sq) = mul_fp (
            macro_states.macro_distances.distance_sq_to_sun1,
            macro_states.macro_distances.distance_sq_to_sun1
        )
        let (dist_2_sq) = mul_fp (
            macro_states.macro_distances.distance_sq_to_sun2,
            macro_states.macro_distances.distance_sq_to_sun2
        )

        let (exposure_0) = div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_0_sq)
        let (exposure_1) = div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_1_sq)
        let (exposure_2) = div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_2_sq)

        #
        # Calculate total exposure
        #
        let exposure = exposure_0 + exposure_1 + exposure_2

        return (exposure)
    end

    func get_solar_exposure_side {range_check_ptr} (
            face : felt,
            macro_states : MacroStatesForTransform
        ) -> (
            exposure : felt
        ):
        alloc_locals

        #
        # Get surface normal
        #
        local normal : Vec2
        if face == 0:
            assert normal = macro_states.planet_side_surface_normals.normal_side0
        else:
            if face == 2:
                assert normal = macro_states.planet_side_surface_normals.normal_side2
            else:
                if face == 4:
                    assert normal = macro_states.planet_side_surface_normals.normal_side4
                else:
                    assert normal = macro_states.planet_side_surface_normals.normal_side5
                end
            end
        end

        #
        # Compute dot products between surface normal and plnt->sun vectors
        #
        let (dot_0) = dot_fp (normal, macro_states.macro_vectors.vector_plnt_to_sun0)
        let (dot_1) = dot_fp (normal, macro_states.macro_vectors.vector_plnt_to_sun1)
        let (dot_2) = dot_fp (normal, macro_states.macro_vectors.vector_plnt_to_sun2)

        #
        # For each sun:
        # exposure = 0, if dot product <= 0;
        # exposure = constant * distance^-2 * cos(theta), otherwise;
        # where cos(theta) = normal dot plnt->sun / mag(normal) / mag(plnt->sun)
        # TODO: refactor if possible
        #

        local exposure_0
        local exposure_1
        local exposure_2
        let (sign_0) = sign (dot_0)
        let (sign_1) = sign (dot_1)
        let (sign_2) = sign (dot_2)
        let (mag_normal) = magnitude_fp (normal)

        if sign_0 == 1:
            let (mag_plnt_sun) = magnitude_fp (macro_states.macro_vectors.vector_plnt_to_sun0)
            let (cos_) = div_fp (dot_0, mag_normal)
            let (cos) = div_fp (cos_, mag_plnt_sun)
            let (dist_sq) = mul_fp (
                macro_states.macro_distances.distance_sq_to_sun0,
                macro_states.macro_distances.distance_sq_to_sun0
            )
            let (exposure_0_) = div_fp (ns_solar_power.BASE_RADIATION, dist_sq)
            let (exposure_0__) = mul_fp (exposure_0_, cos)
            assert exposure_0 = exposure_0__

            tempvar range_check_ptr = range_check_ptr
        else:
            assert exposure_0 = 0

            tempvar range_check_ptr = range_check_ptr
        end

        if sign_1 == 1:
            let (mag_plnt_sun) = magnitude_fp (macro_states.macro_vectors.vector_plnt_to_sun1)
            let (cos_) = div_fp (dot_1, mag_normal)
            let (cos) = div_fp (cos_, mag_plnt_sun)
            let (dist_sq) = mul_fp (
                macro_states.macro_distances.distance_sq_to_sun1,
                macro_states.macro_distances.distance_sq_to_sun1
            )
            let (exposure_1_) = div_fp (ns_solar_power.BASE_RADIATION, dist_sq)
            let (exposure_1__) = mul_fp (exposure_1_, cos)
            assert exposure_1 = exposure_1__

            tempvar range_check_ptr = range_check_ptr
        else:
            assert exposure_1 = 0

            tempvar range_check_ptr = range_check_ptr
        end

        if sign_2 == 1:
            let (mag_plnt_sun) = magnitude_fp (macro_states.macro_vectors.vector_plnt_to_sun2)
            let (cos_) = div_fp (dot_2, mag_normal)
            let (cos) = div_fp (cos_, mag_plnt_sun)
            let (dist_sq) = mul_fp (
                macro_states.macro_distances.distance_sq_to_sun2,
                macro_states.macro_distances.distance_sq_to_sun2
            )
            let (exposure_2_) = div_fp (ns_solar_power.BASE_RADIATION, dist_sq)
            let (exposure_2__) = mul_fp (exposure_2_, cos)
            assert exposure_2 = exposure_2__

            tempvar range_check_ptr = range_check_ptr
        else:
            assert exposure_2 = 0

            tempvar range_check_ptr = range_check_ptr
        end

        let exposure = exposure_0 + exposure_1 + exposure_2

        return (exposure)
    end

    func face_is_top_or_bottom {} (face) -> (bool):
        if face == 1:
            return (1)
        end

        if face == 3:
            return (1)
        else:
            return (0)
        end
    end

end # end namespace