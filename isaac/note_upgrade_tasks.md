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

