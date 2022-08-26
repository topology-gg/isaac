Upgrade to non-fungible devices

- manufacture
- deploy
- pick up
- transfer

new method:
- create device of empty balance

modified method interface:
- player_deploy_device_by_grid (device_id, grid)
- player_transfer_undeployed_device (device_id, to_player_idx)

change:
- reset_and_deactivate_universe: adapt to new ledger structures

        let (emap_size_curr) = ns_micro_state_functions.device_deployed_emap_size_read ()
        ns_micro_state_functions.device_deployed_emap_size_write (emap_size_curr + 1)

        #
        # Create new device id
        #
        let (block_height) = get_block_number ()
        tempvar data_ptr : felt* = new (5, block_height, caller, type, grid.x, grid.y)
        let (new_id) = hash_chain {hash_ptr = pedersen_ptr} (data_ptr)