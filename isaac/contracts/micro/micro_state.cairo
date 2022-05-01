%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.util.structs import (
    Vec2
)

##############################
## Grids
##############################

## Note: for utb-set or utl-set, GridStat.deployed_device_id is the set label
struct GridStat:
    member populated : felt
    member deployed_device_type : felt
    member deployed_device_id : felt
    member deployed_device_owner : felt
end

@storage_var
func grid_stats (grid : Vec2) -> (grid_stat : GridStat):
end

##############################
## Devices (including opsf)
##############################

@storage_var
func device_undeployed_ledger (owner : felt, type : felt) -> (amount : felt):
end

struct DeviceDeployedEmapEntry:
    member grid : Vec2
    member type : felt
    member id : felt
end

struct TransformerResourceBalances:
    member balance_resource_before_transform : felt
    member balance_resource_after_transform : felt
end

@storage_var
func device_deployed_emap_size () -> (size : felt):
end

@storage_var
func device_deployed_emap (emap_index : felt) -> (emap_entry : DeviceDeployedEmapEntry):
end

# for quick reverse lookup (device-id to emap-index), assuming device-id is valid
@storage_var
func device_deployed_id_to_emap_index (id : felt) -> (emap_index : felt):
end

#
# Resource balances
#
@storage_var
func harvesters_deployed_id_to_resource_balance (id : felt) -> (balance : felt):
end

@storage_var
func transformers_deployed_id_to_resource_balances (id : felt) -> (balances : TransformerResourceBalances):
end

@storage_var
func opsf_deployed_id_to_resource_balances (id : felt, element_type : felt) -> (balance : felt):
end

#
# Energy balances
#
@storage_var
func device_deployed_id_to_energy_balance (id : felt) -> (energy : felt):
end


##############################
## utx
##############################

#
# Use enumerable map (Emap) to maintain the an array of (set label, utx index start, utx index end)
# credit to Peteris at yagi.fi
#
struct UtxSetDeployedEmapEntry:
    member utx_set_deployed_label : felt
    member utx_deployed_index_start : felt
    member utx_deployed_index_end : felt
    member src_device_id : felt
    member dst_device_id : felt
end

@storage_var
func utx_set_deployed_emap_size (utx_device_type : felt) -> (size : felt):
end

@storage_var
func utx_set_deployed_emap (utx_device_type : felt, emap_index : felt) -> (emap_entry : UtxSetDeployedEmapEntry):
end

# for quick reverse lookup (utx-set label to emap-index)
@storage_var
func utx_set_deployed_label_to_emap_index (utx_device_type : felt, label : felt) -> (emap_index : felt):
end

#
# Append-only
#
@storage_var
func utx_deployed_index_to_grid_size (utx_device_type : felt) -> (size : felt):
end

@storage_var
func utx_deployed_index_to_grid (utx_device_type : felt, index : felt) -> (grid : Vec2):
end

#
# Recording the utx-sets tethered to a given id of deployed-device
#
@storage_var
func utx_tether_count_of_deployed_device (utx_device_type : felt, device_id : felt) -> (count : felt):
end

@storage_var
func utx_tether_labels_of_deployed_device (utx_device_type : felt, device_id : felt, idx : felt) -> (utx_set_label : felt):
end

namespace ns_micro_state_functions:

    ##############################
    ## Getters
    ##############################

    @view
    func grid_stats_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2) -> (grid_stat : GridStat):
        let (grid_stat) = grid_stats.read (grid)
        return (grid_stat)
    end

    @view
    func device_undeployed_ledger_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        owner : felt, type : felt) -> (amount : felt):
        let (amount) = device_undeployed_ledger.read (owner, type)
        return (amount)
    end

    @view
    func device_deployed_emap_size_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} () -> (size : felt):
        let (size) = device_deployed_emap_size.read ()
        return (size)
    end

    @view
    func device_deployed_emap_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        emap_index : felt) -> (emap_entry : DeviceDeployedEmapEntry):
        let (emap_entry) = device_deployed_emap.read (emap_index)
        return (emap_entry)
    end

    @view
    func device_deployed_id_to_emap_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt) -> (emap_index : felt):
        let (emap_index) = device_deployed_id_to_emap_index.read (id)
        return (emap_index)
    end

    @view
    func harvesters_deployed_id_to_resource_balance_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt) -> (balance : felt):
        let (balance) = harvesters_deployed_id_to_resource_balance.read (id)
        return (balance)
    end

    @view
    func transformers_deployed_id_to_resource_balances_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt) -> (balances : TransformerResourceBalances):
        let (balances) = transformers_deployed_id_to_resource_balances.read (id)
        return (balances)
    end

    @view
    func opsf_deployed_id_to_resource_balances_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt, element_type : felt) -> (balance : felt):
        let (balance) = opsf_deployed_id_to_resource_balances.read (id, element_type)
        return (balance)
    end

    @view
    func device_deployed_id_to_energy_balance_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt) -> (energy : felt):
        let (energy) = device_deployed_id_to_energy_balance.read (id)
        return (energy)
    end

    @view
    func utx_set_deployed_emap_size_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt) -> (size : felt):
        let (size) = utx_set_deployed_emap_size.read (utx_device_type)
        return (size)
    end

    @view
    func utx_set_deployed_emap_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, emap_index : felt) -> (emap_entry : UtxSetDeployedEmapEntry):
        let (emap_entry) = utx_set_deployed_emap.read (utx_device_type, emap_index)
        return (emap_entry)
    end

    @view
    func utx_set_deployed_label_to_emap_index_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, label : felt) -> (emap_index : felt):
        let (emap_index) = utx_set_deployed_label_to_emap_index.read (utx_device_type, label)
        return (emap_index)
    end

    @view
    func utx_deployed_index_to_grid_size_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt) -> (size : felt):
        let (size) = utx_deployed_index_to_grid_size.read (utx_device_type)
        return (size)
    end

    @view
    func utx_deployed_index_to_grid_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, index : felt) -> (grid : Vec2):
        let (grid) = utx_deployed_index_to_grid.read (utx_device_type, index)
        return (grid)
    end

    @view
    func utx_tether_count_of_deployed_device_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, device_id : felt) -> (count : felt):
        let (count) = utx_tether_count_of_deployed_device.read (utx_device_type, device_id)
        return (count)
    end

    @view
    func utx_tether_labels_of_deployed_device_read {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, device_id : felt, idx : felt) -> (utx_set_label : felt):
        let (utx_set_label) = utx_tether_labels_of_deployed_device.read (utx_device_type, device_id, idx)
        return (utx_set_label)
    end

    ##############################
    ## Setters
    ##############################

    func grid_stats_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        grid : Vec2, grid_stat : GridStat) -> ():
        grid_stats.write (grid, grid_stat)
        return ()
    end

    func device_undeployed_ledger_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        owner : felt, type : felt, amount : felt) -> ():
        device_undeployed_ledger.write (owner, type, amount)
        return ()
    end

    func device_deployed_emap_size_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (size : felt) -> ():
        device_deployed_emap_size.write (size)
        return ()
    end

    func device_deployed_emap_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        emap_index : felt, emap_entry : DeviceDeployedEmapEntry) -> ():
        device_deployed_emap.write (emap_index, emap_entry)
        return ()
    end

    func device_deployed_id_to_emap_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt, emap_index : felt) -> ():
        device_deployed_id_to_emap_index.write (id, emap_index)
        return ()
    end

    func harvesters_deployed_id_to_resource_balance_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt, balance : felt) -> ():
        harvesters_deployed_id_to_resource_balance.write (id, balance)
        return ()
    end

    func transformers_deployed_id_to_resource_balances_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt, balances : TransformerResourceBalances) -> ():
        transformers_deployed_id_to_resource_balances.write (id, balances)
        return ()
    end

    func opsf_deployed_id_to_resource_balances_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt, element_type : felt, balance : felt) -> ():
        opsf_deployed_id_to_resource_balances.write (id, element_type, balance)
        return ()
    end

    func device_deployed_id_to_energy_balance_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        id : felt, energy : felt) -> ():
        device_deployed_id_to_energy_balance.write (id, energy)
        return ()
    end

    func utx_set_deployed_emap_size_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, size : felt) -> ():
        utx_set_deployed_emap_size.write (utx_device_type, size)
        return ()
    end

    func utx_set_deployed_emap_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, emap_index : felt, emap_entry : UtxSetDeployedEmapEntry) -> ():
        utx_set_deployed_emap.write (utx_device_type, emap_index, emap_entry)
        return ()
    end

    func utx_set_deployed_label_to_emap_index_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, label : felt, emap_index : felt) -> ():
        utx_set_deployed_label_to_emap_index.write (utx_device_type, label, emap_index)
        return ()
    end

    func utx_deployed_index_to_grid_size_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, size : felt) -> ():
        utx_deployed_index_to_grid_size.write (utx_device_type, size)
        return ()
    end

    func utx_deployed_index_to_grid_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, index : felt, grid : Vec2) -> ():
        utx_deployed_index_to_grid.write (utx_device_type, index, grid)
        return ()
    end

    func utx_tether_count_of_deployed_device_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, device_id : felt, count : felt) -> ():
        utx_tether_count_of_deployed_device.write (utx_device_type, device_id, count)
        return ()
    end

    func utx_tether_labels_of_deployed_device_write {syscall_ptr : felt*, pedersen_ptr : HashBuiltin*, range_check_ptr} (
        utx_device_type : felt, device_id : felt, idx : felt, utx_set_label : felt) -> ():
        utx_tether_labels_of_deployed_device.write (utx_device_type, device_id, idx, utx_set_label)
        return ()
    end
end # end namespace
