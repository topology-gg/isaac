%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le, assert_not_zero, sign
from starkware.cairo.common.math_cmp import is_le, is_nn_le, is_not_zero
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import get_block_number, get_caller_address

from contracts.design.constants import (
    SCALE_FP, PI,
    ns_solar_power
)
from contracts.util.structs import (Vec2, Dynamics)
from contracts.util.numerics import (mul_fp, div_fp, div_fp_ul, sqrt_fp, sine_7th)
from contracts.util.vector_ops import (distance_2, dot_fp, magnitude_fp, compute_vector_rotate, compute_vector_rotate_90)
from contracts.util.grid import (locate_face_and_edge_given_valid_grid)

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

    func get_macro_distance_squares {range_check_ptr} (
            macro_state : Dynamics
        ) -> (
            macro_distance_squares : MacroDistanceSquares
        ):
        let (distance_sq_to_sun0) = distance_2 (macro_state.sun0.q, macro_state.plnt.q)
        let (distance_sq_to_sun1) = distance_2 (macro_state.sun1.q, macro_state.plnt.q)
        let (distance_sq_to_sun2) = distance_2 (macro_state.sun2.q, macro_state.plnt.q)

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

        with_attr error_message ("micro_solar.cairo:170 / Pre-division check: about to perform div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_0_sq) but dist_0_sq = 0"):
            assert_not_zero (dist_0_sq)
        end
        let (exposure_0) = div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_0_sq)

        with_attr error_message ("micro_solar.cairo:175 / Pre-division check: about to perform div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_1_sq) but dist_1_sq = 0"):
            assert_not_zero (dist_1_sq)
        end
        let (exposure_1) = div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_1_sq)

        with_attr error_message ("micro_solar.cairo:180 / Pre-division check: about to perform div_fp (ns_solar_power.OBLIQUE_RADIATION, dist_2_sq) but dist_2_sq = 0"):
            assert_not_zero (dist_2_sq)
        end
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
        let (local mag_normal) = magnitude_fp (normal)

        if sign_0 == 1:
            let (local mag_plnt_sun) = magnitude_fp (macro_states.macro_vectors.vector_plnt_to_sun0)

            with_attr error_message ("micro_solar.cairo:245 / Pre-division check: about to perform div_fp (dot_0, mag_normal) but mag_normal = 0"):
                assert_not_zero (mag_normal)
            end
            let (cos_) = div_fp (dot_0, mag_normal)

            with_attr error_message ("micro_solar.cairo:250 / Pre-division check: about to perform div_fp (cos_, mag_plnt_sun) but mag_plnt_sun = 0"):
                assert_not_zero (mag_plnt_sun)
            end
            let (cos) = div_fp (cos_, mag_plnt_sun)

            let (local dist_sq) = mul_fp (
                macro_states.macro_distances.distance_sq_to_sun0,
                macro_states.macro_distances.distance_sq_to_sun0
            )
            with_attr error_message ("micro_solar.cairo:259 / Pre-division check: about to perform div_fp (ns_solar_power.BASE_RADIATION, dist_sq) but dist_sq = 0"):
                assert_not_zero (dist_sq)
            end
            let (exposure_0_) = div_fp (ns_solar_power.BASE_RADIATION, dist_sq)

            let (exposure_0__) = mul_fp (exposure_0_, cos)
            assert exposure_0 = exposure_0__

            tempvar range_check_ptr = range_check_ptr
        else:
            assert exposure_0 = 0

            tempvar range_check_ptr = range_check_ptr
        end

        if sign_1 == 1:
            let (local mag_plnt_sun) = magnitude_fp (macro_states.macro_vectors.vector_plnt_to_sun1)

            with_attr error_message ("micro_solar.cairo:277 / Pre-division check: about to perform div_fp (dot_1, mag_normal) but mag_normal = 0"):
                assert_not_zero (mag_normal)
            end
            let (cos_) = div_fp (dot_1, mag_normal)

            with_attr error_message ("micro_solar.cairo:282 / Pre-division check: about to perform div_fp (cos_, mag_plnt_sun) but mag_plnt_sun = 0"):
                assert_not_zero (mag_plnt_sun)
            end
            let (cos) = div_fp (cos_, mag_plnt_sun)

            let (local dist_sq) = mul_fp (
                macro_states.macro_distances.distance_sq_to_sun1,
                macro_states.macro_distances.distance_sq_to_sun1
            )

            with_attr error_message ("micro_solar.cairo:292 / Pre-division check: about to perform div_fp (ns_solar_power.BASE_RADIATION, dist_sq) but dist_sq = 0"):
                assert_not_zero (dist_sq)
            end
            let (exposure_1_) = div_fp (ns_solar_power.BASE_RADIATION, dist_sq)

            let (exposure_1__) = mul_fp (exposure_1_, cos)
            assert exposure_1 = exposure_1__

            tempvar range_check_ptr = range_check_ptr
        else:
            assert exposure_1 = 0

            tempvar range_check_ptr = range_check_ptr
        end

        if sign_2 == 1:
            let (local mag_plnt_sun) = magnitude_fp (macro_states.macro_vectors.vector_plnt_to_sun2)

            with_attr error_message ("micro_solar.cairo:310 / Pre-division check: about to perform div_fp (dot_2, mag_normal) but mag_normal = 0"):
                assert_not_zero (mag_normal)
            end
            let (cos_) = div_fp (dot_2, mag_normal)

            with_attr error_message ("micro_solar.cairo:315 / Pre-division check: about to perform div_fp (cos_, mag_plnt_sun) but mag_plnt_sun = 0"):
                assert_not_zero (mag_plnt_sun)
            end
            let (cos) = div_fp (cos_, mag_plnt_sun)

            let (local dist_sq) = mul_fp (
                macro_states.macro_distances.distance_sq_to_sun2,
                macro_states.macro_distances.distance_sq_to_sun2
            )

            with_attr error_message ("micro_solar.cairo:325 / Pre-division check: about to perform div_fp (ns_solar_power.BASE_RADIATION, dist_sq) but dist_sq = 0"):
                assert_not_zero (dist_sq)
            end
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