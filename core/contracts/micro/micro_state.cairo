%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc

from contracts.util.structs import Vec2

//#############################
// # Grids
//#############################

// # Note: for utb-set or utl-set, GridStat.deployed_device_id is the set label
struct GridStat {
    populated: felt,
    deployed_device_type: felt,
    deployed_device_id: felt,
    deployed_device_owner: felt,
}

// @storage_var
// func grid_stats (grid : Vec2) -> (grid_stat : GridStat):
// end
@storage_var
func grid_stats(civ_idx: felt, grid: Vec2) -> (grid_stat: GridStat) {
}

//#############################
// # Devices (including opsf)
//#############################

@storage_var
func fungible_device_undeployed_ledger(owner: felt, type: felt) -> (amount: felt) {
}

struct DeviceEmapEntry {
    owner: felt,
    type: felt,
    id: felt,
    is_deployed: felt,
    grid: Vec2,
}

struct TransformerResourceBalances {
    balance_resource_before_transform: felt,
    balance_resource_after_transform: felt,
}

@storage_var
func device_emap_size() -> (size: felt) {
}

@storage_var
func device_emap(emap_index: felt) -> (emap_entry: DeviceEmapEntry) {
}

// for quick reverse lookup (device-id to emap-index)
@storage_var
func device_id_to_emap_index(id: felt) -> (emap_index: felt) {
}

//
// Resource balances
//
@storage_var
func harvesters_id_to_resource_balance(id: felt) -> (balance: felt) {
}

@storage_var
func transformers_id_to_resource_balances(id: felt) -> (balances: TransformerResourceBalances) {
}

@storage_var
func opsf_id_to_resource_balances(id: felt, element_type: felt) -> (balance: felt) {
}

//
// Energy balances
//
@storage_var
func device_id_to_energy_balance(id: felt) -> (energy: felt) {
}

//#############################
// # utx
//#############################

//
// Use enumerable map (Emap) to maintain the an array of (set label, utx index start, utx index end)
// credit to Peteris at yagi.fi
//
struct UtxSetDeployedEmapEntry {
    utx_set_deployed_label: felt,
    utx_deployed_index_start: felt,
    utx_deployed_index_end: felt,
    src_device_id: felt,
    dst_device_id: felt,
}

@storage_var
func utx_set_deployed_emap_size(utx_device_type: felt) -> (size: felt) {
}

@storage_var
func utx_set_deployed_emap(utx_device_type: felt, emap_index: felt) -> (
    emap_entry: UtxSetDeployedEmapEntry
) {
}

// for quick reverse lookup (utx-set label to emap-index)
@storage_var
func utx_set_deployed_label_to_emap_index(utx_device_type: felt, label: felt) -> (
    emap_index: felt
) {
}

//
// Append-only
//
@storage_var
func utx_deployed_index(utx_device_type: felt) -> (size: felt) {
}

@storage_var
func utx_deployed_index_to_grid(utx_device_type: felt, index: felt) -> (grid: Vec2) {
}

//
// Recording the utx-sets tethered to a given id of deployed-device
//
@storage_var
func utx_tether_count_of_deployed_device(utx_device_type: felt, device_id: felt) -> (count: felt) {
}

@storage_var
func utx_tether_labels_of_deployed_device(utx_device_type: felt, device_id: felt, idx: felt) -> (
    utx_set_label: felt
) {
}

namespace ns_micro_state_functions {
    //#############################
    // # Getters
    //#############################

    @view
    func grid_stats_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        civ_idx: felt, grid: Vec2
    ) -> (grid_stat: GridStat) {
        let (grid_stat) = grid_stats.read(civ_idx, grid);
        return (grid_stat,);
    }

    @view
    func fungible_device_undeployed_ledger_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(owner: felt, type: felt) -> (amount: felt) {
        let (amount) = fungible_device_undeployed_ledger.read(owner, type);
        return (amount,);
    }

    @view
    func device_emap_size_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        ) -> (size: felt) {
        let (size) = device_emap_size.read();
        return (size,);
    }

    @view
    func device_emap_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        emap_index: felt
    ) -> (emap_entry: DeviceEmapEntry) {
        let (emap_entry) = device_emap.read(emap_index);
        return (emap_entry,);
    }

    @view
    func device_id_to_emap_index_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt) -> (emap_index: felt) {
        let (emap_index) = device_id_to_emap_index.read(id);
        return (emap_index,);
    }

    @view
    func harvesters_id_to_resource_balance_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt) -> (balance: felt) {
        let (balance) = harvesters_id_to_resource_balance.read(id);
        return (balance,);
    }

    @view
    func transformers_id_to_resource_balances_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt) -> (balances: TransformerResourceBalances) {
        let (balances) = transformers_id_to_resource_balances.read(id);
        return (balances,);
    }

    @view
    func opsf_id_to_resource_balances_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt, element_type: felt) -> (balance: felt) {
        let (balance) = opsf_id_to_resource_balances.read(id, element_type);
        return (balance,);
    }

    @view
    func device_id_to_energy_balance_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt) -> (energy: felt) {
        let (energy) = device_id_to_energy_balance.read(id);
        return (energy,);
    }

    @view
    func utx_set_deployed_emap_size_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt) -> (size: felt) {
        let (size) = utx_set_deployed_emap_size.read(utx_device_type);
        return (size,);
    }

    @view
    func utx_set_deployed_emap_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, emap_index: felt) -> (emap_entry: UtxSetDeployedEmapEntry) {
        let (emap_entry) = utx_set_deployed_emap.read(utx_device_type, emap_index);
        return (emap_entry,);
    }

    @view
    func utx_set_deployed_label_to_emap_index_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, label: felt) -> (emap_index: felt) {
        let (emap_index) = utx_set_deployed_label_to_emap_index.read(utx_device_type, label);
        return (emap_index,);
    }

    @view
    func utx_deployed_index_read{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        utx_device_type: felt
    ) -> (size: felt) {
        let (size) = utx_deployed_index.read(utx_device_type);
        return (size,);
    }

    @view
    func utx_deployed_index_to_grid_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, index: felt) -> (grid: Vec2) {
        let (grid) = utx_deployed_index_to_grid.read(utx_device_type, index);
        return (grid,);
    }

    @view
    func utx_tether_count_of_deployed_device_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, device_id: felt) -> (count: felt) {
        let (count) = utx_tether_count_of_deployed_device.read(utx_device_type, device_id);
        return (count,);
    }

    @view
    func utx_tether_labels_of_deployed_device_read{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, device_id: felt, idx: felt) -> (utx_set_label: felt) {
        let (utx_set_label) = utx_tether_labels_of_deployed_device.read(
            utx_device_type, device_id, idx
        );
        return (utx_set_label,);
    }

    //#############################
    // # Setters
    //#############################

    func grid_stats_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        civ_idx: felt, grid: Vec2, grid_stat: GridStat
    ) -> () {
        grid_stats.write(civ_idx, grid, grid_stat);
        return ();
    }

    func fungible_device_undeployed_ledger_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(owner: felt, type: felt, amount: felt) -> () {
        fungible_device_undeployed_ledger.write(owner, type, amount);
        return ();
    }

    func device_emap_size_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        size: felt
    ) -> () {
        device_emap_size.write(size);
        return ();
    }

    func device_emap_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        emap_index: felt, emap_entry: DeviceEmapEntry
    ) -> () {
        device_emap.write(emap_index, emap_entry);
        return ();
    }

    func device_id_to_emap_index_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt, emap_index: felt) -> () {
        device_id_to_emap_index.write(id, emap_index);
        return ();
    }

    func harvesters_id_to_resource_balance_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt, balance: felt) -> () {
        harvesters_id_to_resource_balance.write(id, balance);
        return ();
    }

    func transformers_id_to_resource_balances_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt, balances: TransformerResourceBalances) -> () {
        transformers_id_to_resource_balances.write(id, balances);
        return ();
    }

    func opsf_id_to_resource_balances_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt, element_type: felt, balance: felt) -> () {
        opsf_id_to_resource_balances.write(id, element_type, balance);
        return ();
    }

    func device_id_to_energy_balance_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(id: felt, energy: felt) -> () {
        device_id_to_energy_balance.write(id, energy);
        return ();
    }

    func utx_set_deployed_emap_size_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, size: felt) -> () {
        utx_set_deployed_emap_size.write(utx_device_type, size);
        return ();
    }

    func utx_set_deployed_emap_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, emap_index: felt, emap_entry: UtxSetDeployedEmapEntry) -> () {
        utx_set_deployed_emap.write(utx_device_type, emap_index, emap_entry);
        return ();
    }

    func utx_set_deployed_label_to_emap_index_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, label: felt, emap_index: felt) -> () {
        utx_set_deployed_label_to_emap_index.write(utx_device_type, label, emap_index);
        return ();
    }

    func utx_deployed_index_write{syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr}(
        utx_device_type: felt, size: felt
    ) -> () {
        utx_deployed_index.write(utx_device_type, size);
        return ();
    }

    func utx_deployed_index_to_grid_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, index: felt, grid: Vec2) -> () {
        utx_deployed_index_to_grid.write(utx_device_type, index, grid);
        return ();
    }

    func utx_tether_count_of_deployed_device_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, device_id: felt, count: felt) -> () {
        utx_tether_count_of_deployed_device.write(utx_device_type, device_id, count);
        return ();
    }

    func utx_tether_labels_of_deployed_device_write{
        syscall_ptr: felt*, pedersen_ptr: HashBuiltin*, range_check_ptr
    }(utx_device_type: felt, device_id: felt, idx: felt, utx_set_label: felt) -> () {
        utx_tether_labels_of_deployed_device.write(utx_device_type, device_id, idx, utx_set_label);
        return ();
    }
}  // end namespace
