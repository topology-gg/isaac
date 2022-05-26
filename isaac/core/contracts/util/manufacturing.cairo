%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import (assert_nn, assert_le, assert_not_zero, abs_value, signed_div_rem)
from starkware.cairo.common.math_cmp import (is_le, is_not_zero, is_nn_le, is_nn)
from starkware.cairo.common.registers import get_label_location
from starkware.cairo.common.alloc import alloc
from contracts.util.structs import (Vec2)

from contracts.macro.macro_simulation import (
    div_fp, mul_fp
)
from contracts.design.constants import (
    ns_element_types,
    ns_device_types,
    ns_energy_requirements
)

#
# Functions involved in recipes for device manufacturing at UPSF
#
namespace ns_manufacturing:
    func get_resource_energy_requirement_given_device_type {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr
        } (
            device_type : felt
        ) -> (
            energy : felt,
            resource_arr_len : felt,
            resource_arr : felt*
        ):

        #
        # SPG
        #
        if device_type == ns_device_types.DEVICE_SPG:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 0
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 50
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 100
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_SPG,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # NPG
        #
        if device_type == ns_device_types.DEVICE_NPG:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 0
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 500
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 2000

            return (
                ns_energy_requirements.DEVICE_NPG,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # FE HARV
        #
        if device_type == ns_device_types.DEVICE_FE_HARV:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 300
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 0
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 0
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_FE_HARV,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # AL HARV
        #
        if device_type == ns_device_types.DEVICE_AL_HARV:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 500
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 0
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_AL_HARV,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # CU HARV
        #
        if device_type == ns_device_types.DEVICE_CU_HARV:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 300
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 300
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 0
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_CU_HARV,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # SI HARV
        #
        if device_type == ns_device_types.DEVICE_SI_HARV:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 200
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_SI_HARV,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # PU HARV
        #
        if device_type == ns_device_types.DEVICE_PU_HARV:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 200
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_PU_HARV,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # FE REFN
        #
        if device_type == ns_device_types.DEVICE_FE_REFN:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 200
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_FE_REFN,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # AL REFN
        #
        if device_type == ns_device_types.DEVICE_AL_REFN:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 200
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_AL_REFN,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # CU REFN
        #
        if device_type == ns_device_types.DEVICE_CU_REFN:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 200
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_CU_REFN,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # SI REFN
        #
        if device_type == ns_device_types.DEVICE_SI_REFN:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 200
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 0
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 100
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 0
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_SI_REFN,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # PEF
        #
        if device_type == ns_device_types.DEVICE_PEF:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 500
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 500
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 500
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 500
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_PEF,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # UTB
        #
        if device_type == ns_device_types.DEVICE_UTB:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 25
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 50
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 25
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 10
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_UTB,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # UTL
        #
        if device_type == ns_device_types.DEVICE_UTL:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 25
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 25
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 50
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 10
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_UTL,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # UPSF
        #
        if device_type == ns_device_types.DEVICE_UPSF:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 2000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 2000
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 2000
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 2000
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 0

            return (
                ns_energy_requirements.DEVICE_UPSF,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        #
        # NDPE
        #
        if device_type == ns_device_types.DEVICE_NDPE:
            let (arr) = alloc ()
            assert [arr + ns_element_types.ELEMENT_FE_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_FE_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_AL_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_AL_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_CU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_CU_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_SI_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_SI_REF] = 1000
            assert [arr + ns_element_types.ELEMENT_PU_RAW] = 0
            assert [arr + ns_element_types.ELEMENT_PU_ENR] = 1000

            return (
                ns_energy_requirements.DEVICE_NDPE,
                ns_element_types.ELEMENT_COUNT,
                arr
            )
        end

        with_attr error_message ("Invalid device type"):
            assert 1 = 0
        end
        let (null) = alloc ()
        return (0, 0, null)

    end
end