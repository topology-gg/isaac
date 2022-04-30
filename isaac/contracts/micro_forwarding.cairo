%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.hash_chain import hash_chain
from starkware.cairo.common.math import (assert_lt, assert_le, assert_nn, assert_not_equal, assert_nn_le)
from starkware.cairo.common.math_cmp import (is_le, is_nn_le, is_not_zero)
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    ns_device_types, assert_device_type_is_utx,
    harvester_device_type_to_element_type,
    transformer_device_type_to_element_types,
    get_device_dimension_ptr
)
from contracts.util.structs import (
    Vec2
)
from contracts.util.grid import (
    is_valid_grid, are_contiguous_grids_given_valid_grids,
    locate_face_and_edge_given_valid_grid,
    is_zero
)
from contracts.util.logistics import (
    ns_logistics_harvester, ns_logistics_transformer,
    ns_logistics_xpg, ns_logistics_utb, ns_logistics_utl
)
from contracts.micro_state import (
    ns_micro_state_functions,
    GridStat, DeviceDeployedEmapEntry, TransformerResourceBalances, UtxSetDeployedEmapEntry
)
from contracts.micro_devices import (
    ns_micro_devices
)
from contracts.micro_grids import (
    ns_micro_grids
)

namespace ns_micro_forwarding:

    func resource_energy_update_at_devices {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> ():

        let (emap_size) = ns_micro_state_functions.device_deployed_emap_size_read ()
        recurse_resource_energy_update_at_devices (
            len = emap_size,
            idx = 0
        )

        return ()
    end

    func recurse_resource_energy_update_at_devices {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            len : felt, idx : felt
        ) -> ():
        alloc_locals

        if idx == len:
            return ()
        end

        let (emap_entry) = ns_micro_state_functions.device_deployed_emap_read (idx)
        let (bool_is_harvester) = ns_micro_devices.is_device_harvester (emap_entry.type)
        let (bool_is_transformer) = ns_micro_devices.is_device_transformer (emap_entry.type)

        #
        # For power generator
        #
        local syscall_ptr : felt* = syscall_ptr
        local pedersen_ptr : HashBuiltin* = pedersen_ptr
        local range_check_ptr = range_check_ptr
        handle_power_generator:
        ## solar power generator
        if emap_entry.type == ns_device_types.DEVICE_SPG:
            let (energy_generated) = ns_logistics_xpg.spg_solar_exposure_to_energy_generated_per_tick (
                solar_exposure = 10 # TODO!!!
            )
            let (curr_energy) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (emap_entry.id)
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                emap_entry.id,
                curr_energy + energy_generated
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        ## nuclear power generator
        if emap_entry.type == ns_device_types.DEVICE_NPG:
            let (curr_energy) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (emap_entry.id)
            let (energy_generated) = ns_logistics_xpg.npg_energy_supplied_to_energy_generated_per_tick (curr_energy)
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                emap_entry.id,
                curr_energy + energy_generated
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        #
        # For harvester => increase resource based on resource concentration at land
        #
        local syscall_ptr : felt* = syscall_ptr
        local pedersen_ptr : HashBuiltin* = pedersen_ptr
        local range_check_ptr = range_check_ptr
        handle_harvester:
        if bool_is_harvester == 1:
            #
            # Get harvest quantity based on {element type, concentration (from perlin), and energy supplied at last tick}
            #
            let (element_type) = harvester_device_type_to_element_type (emap_entry.type)
            let (concentration) = ns_micro_grids.get_resource_concentration_at_grid (emap_entry.grid, element_type)
            let (energy_last_tick) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (emap_entry.id)
            let (quantity_harvested) = ns_logistics_harvester.harvester_quantity_per_tick (
                element_type, concentration, energy_last_tick
            )

            #
            # Update resource balance at this harvester
            #
            let (quantity_curr) = ns_micro_state_functions.harvesters_deployed_id_to_resource_balance_read (emap_entry.id)
            ns_micro_state_functions.harvesters_deployed_id_to_resource_balance_write (
                emap_entry.id,
                quantity_curr + quantity_harvested
            )

            #
            # Clear energy balance at this harvester -- only power generator can store energy
            #
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                emap_entry.id,
                0
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        #
        # For transformer (refinery/PEF) => decrease raw resource and increase transformed resource
        #
        local syscall_ptr : felt* = syscall_ptr
        local pedersen_ptr : HashBuiltin* = pedersen_ptr
        local range_check_ptr = range_check_ptr
        handle_transformer:
        if bool_is_transformer == 1:
            #
            # Determine the max quantity that can be transformed at this tick given element type and energy supplied at last tick
            #
            let (element_type_before, element_type_after) = transformer_device_type_to_element_types (emap_entry.type)
            let (balances) = ns_micro_state_functions.transformers_deployed_id_to_resource_balances_read (emap_entry.id)
            let (energy_last_tick) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (emap_entry.id)
            let (should_transform_quantity) = ns_logistics_transformer.transformer_quantity_per_tick (
                element_type_before,
                energy_last_tick
            )

            #
            # If balance of element_type_before < `should_transform_quantity`, only transform current balance;
            # otherwise, transform `should_transform_quantity`
            #
            local transform_amount
            let (bool) = is_le (balances.balance_resource_before_transform, should_transform_quantity)
            if bool == 1:
                assert transform_amount = balances.balance_resource_before_transform
            else:
                assert transform_amount = should_transform_quantity
            end

            #
            # Apply transform on balances
            #
            ns_micro_state_functions.transformers_deployed_id_to_resource_balances_write (
                emap_entry.id,
                TransformerResourceBalances (
                    balances.balance_resource_before_transform - transform_amount,
                    balances.balance_resource_after_transform + transform_amount
                )
            )

            #
            # Clear energy balance at this transformer -- only power generator can store energy
            #
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                emap_entry.id,
                0
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        #
        # Handle OPSF
        #
        local syscall_ptr : felt* = syscall_ptr
        local pedersen_ptr : HashBuiltin* = pedersen_ptr
        local range_check_ptr = range_check_ptr
        handle_opsf:
        if emap_entry.type == ns_device_types.DEVICE_OPSF:
            #
            # Clear energy balance at this OPSF -- only power generator can store energy
            #
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                emap_entry.id,
                0
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        #
        # Tail recursion
        #
        recurse:
        recurse_resource_energy_update_at_devices (len, idx + 1)

        return ()
    end

    func resource_transfer_across_utb_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> ():
        #
        # recursively traverse `utx_set_deployed_emap`
        #
        let (emap_size) = ns_micro_state_functions.utx_set_deployed_emap_size_read (ns_device_types.DEVICE_UTB)
        recurse_resource_transfer_across_utb_sets (
            len = emap_size, idx = 0
        )
        return ()
    end

    func recurse_resource_transfer_across_utb_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            len, idx
        ) -> ():
        alloc_locals

        #
        # transfer resource from source to destination according to transport rate
        # NOTE: source device can be connected to multiple utb, resulting in higher transport rate
        # NOTE: opsf as destination device can be connected to multiple utb transporting same/different kinds of resources
        #

        if idx == len:
            return ()
        end

        #
        # check if source device and destination device are still deployed;
        # note: haven't figured out how to do conditional jump in recursion elegantly
        #
        let (emap_entry) = ns_micro_state_functions.utx_set_deployed_emap_read (ns_device_types.DEVICE_UTB, idx)
        let (is_src_tethered) = is_not_zero (emap_entry.src_device_id)
        let (is_dst_tethered) = is_not_zero (emap_entry.dst_device_id)
        let  utb_set_length = emap_entry.utx_deployed_index_end - emap_entry.utx_deployed_index_start

        #
        # If both sides are tethered => handle resource transportation
        #
        if is_src_tethered * is_dst_tethered == 1:
            #
            # Find out source / destination device type
            #
            let (emap_index_src) = ns_micro_state_functions.device_deployed_id_to_emap_index_read (emap_entry.src_device_id)
            let (emap_entry_src) = ns_micro_state_functions.device_deployed_emap_read (emap_index_src)
            let (emap_index_dst) = ns_micro_state_functions.device_deployed_id_to_emap_index_read (emap_entry.dst_device_id)
            let (emap_entry_dst) = ns_micro_state_functions.device_deployed_emap_read (emap_index_dst)
            let src_type = emap_entry_src.type
            let dst_type = emap_entry_dst.type
            let (bool_src_harvester) = ns_micro_devices.is_device_harvester (src_type)
            let (bool_dst_opsf) = ns_micro_devices.is_device_opsf (dst_type)

            local quantity_received
            local element_type

            ## Handle source device first

            #
            # Source device is harvester
            #
            if bool_src_harvester == 1:
                #
                # Determine quantity to be sent from source
                #
                let (element_type_) = harvester_device_type_to_element_type (src_type)
                assert element_type = element_type_
                let (src_balance) = ns_micro_state_functions.harvesters_deployed_id_to_resource_balance_read (emap_entry.src_device_id)
                let (quantity_should_send) = ns_logistics_utb.utb_quantity_should_send_per_tick (
                    src_balance
                )

                #
                # Determine quantity to be received at destination
                #
                let (quantity_should_receive) = ns_logistics_utb.utb_quantity_should_receive_per_tick (
                    src_balance,
                    utb_set_length
                )
                assert quantity_received = quantity_should_receive

                #
                # Update source device resource balance
                #
                ns_micro_state_functions.harvesters_deployed_id_to_resource_balance_write (
                    emap_entry.src_device_id,
                    src_balance - quantity_should_send
                )

                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr

            #
            # Source device is transformer
            #
            else:
                #
                # Determine quantity to be sent from source
                #
                let (_, element_type_) = transformer_device_type_to_element_types (src_type)
                assert element_type = element_type_
                let (src_balances) = ns_micro_state_functions.transformers_deployed_id_to_resource_balances_read (emap_entry.src_device_id)
                let src_balance = src_balances.balance_resource_after_transform
                let (quantity_should_send) = ns_logistics_utb.utb_quantity_should_send_per_tick (
                    src_balance
                )

                #
                # Determine quantity to be received at destination
                #
                let (quantity_should_receive) = ns_logistics_utb.utb_quantity_should_receive_per_tick (
                    src_balance,
                    utb_set_length
                )
                assert quantity_received = quantity_should_receive

                #
                # Update source device resource balance
                #
                ns_micro_state_functions.transformers_deployed_id_to_resource_balances_write (
                    emap_entry.src_device_id,
                    TransformerResourceBalances(
                        src_balances.balance_resource_before_transform,
                        src_balance - quantity_should_send
                ))

                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr
            end

            ## Then handle destination device

            #
            # Destination device is OPSF
            #
            if bool_dst_opsf == 1:
                #
                # Update destination device resource balance
                #
                let (dst_balance) = ns_micro_state_functions.opsf_deployed_id_to_resource_balances_read (emap_entry.dst_device_id, element_type)
                ns_micro_state_functions.opsf_deployed_id_to_resource_balances_write (
                    emap_entry.dst_device_id,
                    element_type,
                    dst_balance + quantity_received
                )

                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr

            #
            # Destination device is transformer
            #
            else:
                #
                # Update destination device resource balance
                #
                let (dst_balances) = ns_micro_state_functions.transformers_deployed_id_to_resource_balances_read (emap_entry.dst_device_id)
                ns_micro_state_functions.transformers_deployed_id_to_resource_balances_write (
                    emap_entry.dst_device_id,
                    TransformerResourceBalances(
                        dst_balances.balance_resource_before_transform + quantity_received,
                        dst_balances.balance_resource_after_transform
                ))

                tempvar syscall_ptr = syscall_ptr
                tempvar pedersen_ptr = pedersen_ptr
                tempvar range_check_ptr = range_check_ptr
            end
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end

        recurse_resource_transfer_across_utb_sets (len, idx + 1)
        return ()
    end

    func energy_transfer_across_utl_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> ():
        #
        # recursively traverse `utx_set_deployed_emap`
        #
        let (emap_size) = ns_micro_state_functions.utx_set_deployed_emap_size_read (ns_device_types.DEVICE_UTL)
        recurse_energy_transfer_across_utl_sets (
            len = emap_size, idx = 0
        )
        return ()
    end

    func recurse_energy_transfer_across_utl_sets {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
            len, idx
        ) -> ():
        alloc_locals

        if idx == len:
            return ()
        end

        #
        # check if source device and destination device are still deployed
        #
        let (emap_entry) = ns_micro_state_functions.utx_set_deployed_emap_read (ns_device_types.DEVICE_UTL, idx)
        let (is_src_tethered) = is_not_zero (emap_entry.src_device_id)
        let (is_dst_tethered) = is_not_zero (emap_entry.dst_device_id)
        let  utl_set_length = emap_entry.utx_deployed_index_end - emap_entry.utx_deployed_index_start

        if is_src_tethered * is_dst_tethered == 1:
            #
            # Get device id of source and destination
            #
            let (emap_index_src) = ns_micro_state_functions.device_deployed_id_to_emap_index_read (emap_entry.src_device_id)
            let (emap_entry_src) = ns_micro_state_functions.device_deployed_emap_read (emap_index_src)
            let (emap_index_dst) = ns_micro_state_functions.device_deployed_id_to_emap_index_read (emap_entry.dst_device_id)
            let (emap_entry_dst) = ns_micro_state_functions.device_deployed_emap_read (emap_index_dst)
            let src_device_id = emap_entry_src.id
            let dst_device_id = emap_entry_dst.id
            let (src_device_energy) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (src_device_id)
            let (dst_device_energy) = ns_micro_state_functions.device_deployed_id_to_energy_balance_read (dst_device_id)

            #
            # Determine energy should send and energy should receive
            #
            let (energy_should_send) = ns_logistics_utl.utl_energy_should_send_per_tick (
                src_device_energy
            )
            let (energy_should_receive) = ns_logistics_utl.utl_energy_should_receive_per_tick (
                src_device_energy,
                utl_set_length
            )

            #
            # Effect energy update at source
            #
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                src_device_id,
                src_device_energy - energy_should_send
            )

            #
            # Effect energy update at destination
            # note: could have multi-fanin resulting higher energy boost
            #
            ns_micro_state_functions.device_deployed_id_to_energy_balance_write (
                dst_device_id,
                dst_device_energy + energy_should_receive
            )

            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        else:
            tempvar syscall_ptr = syscall_ptr
            tempvar pedersen_ptr = pedersen_ptr
            tempvar range_check_ptr = range_check_ptr
        end


        recurse_energy_transfer_across_utl_sets (
            len,
            idx + 1
        )
        return ()
    end

    func forward_world_micro {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        ) -> ():

        #
        # Effect resource & energy update at device;
        # akin to propagating D->Q for flip-flops in digital circuit
        #
        resource_energy_update_at_devices ()

        #
        # Effect resource transfer across deployed utb-sets;
        # akin to propagating values through wires in digital circuit
        #
        resource_transfer_across_utb_sets ()
        energy_transfer_across_utl_sets ()

        return ()
    end

end # end namespace
