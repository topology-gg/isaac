from dataclasses import dataclass
from typing import Any, Iterator, Tuple

from apibara.model import Event


STARK_PRIME = (
    3618502788666131213697322783095070105623107215331596699973092056135872020481
)
STARK_PRIME_HALF = (
    1809251394333065606848661391547535052811553607665798349986546028067936010240
)


def _felt_from_iter(it: Iterator[bytes], scale=False, signed=True):
    fe = int.from_bytes(next(it), "big")

    if signed:
        if fe > STARK_PRIME_HALF:
            fe = fe - STARK_PRIME

    if not scale:
        return fe
    return fe / (10**20)


@dataclass
class Vec2:
    x: float
    y: float

    @staticmethod
    def from_iter(it: Iterator[bytes], scale=False):
        x = _felt_from_iter(it, scale=scale)
        y = _felt_from_iter(it, scale=scale)
        return Vec2(x, y)

    def to_json(self) -> Any:
        return {"x": self.x, "y": self.y}


@dataclass
class Dynamic:
    q: Vec2
    qd: Vec2

    @staticmethod
    def from_iter(it: Iterator[bytes]):
        q  = Vec2.from_iter(it = it, scale=True)
        qd = Vec2.from_iter(it = it, scale=True)
        return Dynamic(q, qd)

    def to_json(self) -> Any:
        return {
            "q": self.q.to_json(),
            "qd": self.qd.to_json(),
        }


@dataclass
class Dynamics:
    sun0: Dynamic
    sun1: Dynamic
    sun2: Dynamic
    planet: Dynamic

    @staticmethod
    def from_iter(it: Iterator[bytes]):
        sun0 = Dynamic.from_iter(it)
        sun1 = Dynamic.from_iter(it)
        sun2 = Dynamic.from_iter(it)
        planet = Dynamic.from_iter(it)
        return Dynamics(sun0, sun1, sun2, planet)

    def to_json(self) -> Any:
        return {
            "sun0": self.sun0.to_json(),
            "sun1": self.sun1.to_json(),
            "sun2": self.sun2.to_json(),
            "planet": self.planet.to_json(),
        }

###

#
# Decode any event to extract event_counter, which is always the first member
#
def extract_counter_from_event (event: Event) -> Tuple [int]:
    it = iter(event.data)
    event_counter = _felt_from_iter(it, scale=False)

    return event_counter

###

#
# Decode event: universe::forward_world_macro_occurred
#
def decode_forward_world_event(event: Event) -> Tuple[Dynamic, int]:
    it = iter(event.data)

    event_counter = _felt_from_iter(it, scale=False)
    dynamics = Dynamics.from_iter(it)
    phi = _felt_from_iter(it, scale=False)

    return dynamics, phi

#
# Decode event: universe::give_undeployed_fungible_device_occurred
#
def decode_give_undeployed_fungible_device_occurred_event (event: Event) -> Tuple [int, int, int, int]:

    # @event
    # func give_undeployed_fungible_device_occurred (
    #         event_counter : felt,
    #         to : felt,
    #         type : felt,
    #         amount : felt
    #     ):
    # end

    it = iter (event.data)

    event_counter = _felt_from_iter (it, scale=False)
    to_account    = _felt_from_iter (it, scale=False, signed=False)
    device_type   = _felt_from_iter (it, scale=False)
    device_amount = _felt_from_iter (it, scale=False)

    return event_counter, to_account, device_type, device_amount

#
# Decode event: universe::activate_universe_occurred
#
def decode_activate_universe_occurred_event (event: Event) -> Tuple [int, int]:

    # @event
    # func activate_universe_occurred (
    #         event_counter : felt,
    #         civ_idx : felt
    #     ):
    # end

    it = iter (event.data)

    event_counter = _felt_from_iter (it, scale=False)
    civ_idx       = _felt_from_iter (it, scale=False)

    return event_counter, civ_idx

#
# Decode event: universe::terminate_universe_occurred
#
def decode_terminate_universe_occurred_event (event: Event) -> Tuple [int, int, int, int]:
    it = iter(event.data)

    # @event
    # func terminate_universe_occurred (
    #         bool_universe_terminable : felt,
    #         destruction_by_which_sun : felt,
    #         bool_universe_max_age_reached : felt,
    #         bool_universe_escape_condition_met : felt
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    bool_universe_terminable           = _felt_from_iter (it, scale=False)
    destruction_by_which_sun           = _felt_from_iter (it, scale=False)
    bool_universe_max_age_reached      = _felt_from_iter (it, scale=False)
    bool_universe_escape_condition_met = _felt_from_iter (it, scale=False)

    return bool_universe_terminable, destruction_by_which_sun, bool_universe_max_age_reached, bool_universe_escape_condition_met

#
# Decode event: universe::player_deploy_device_occurred
#
def decode_player_deploy_device_occurred_event (event: Event) -> Tuple [int, int, int, Vec2]:
    it = iter(event.data)

    # @event
    # func player_deploy_device_occurred (
    #         owner : felt,
    #         device_id : felt,
    #         grid : Vec2
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    owner         = _felt_from_iter (it, scale=False, signed=False)
    device_id     = _felt_from_iter (it, scale=False, signed=False)
    grid          = Vec2.from_iter  (it, scale=False)

    return owner, device_id, grid

#
# Decode event: universe::player_pickup_device_occurred
#
def decode_player_pickup_device_occurred_event (event: Event) -> Tuple [int, int, Vec2]:
    it = iter(event.data)

    # @event
    # func player_pickup_device_occurred (
    #         event_counter : felt,
    #         owner : felt,
    #         device_id : felt,
    #         grid : Vec2
    #     ):
    # end

    event_counter = _felt_from_iter (it, scale=False)
    owner         = _felt_from_iter (it, scale=False, signed=False)
    device_id     = _felt_from_iter (it, scale=False, signed=False)
    grid          = Vec2.from_iter  (it, scale=False)

    return owner, device_id, grid

#
# Decode event: universe::player_deploy_utx_occurred
#
def decode_player_deploy_utx_occurred_event (event: Event) -> Tuple [int, int, int, Vec2, Vec2, int, list]:
    it = iter (event.data)

    # @event
    # func player_deploy_utx_occurred (
    #         owner : felt,
    #         utx_label : felt,
    #         utx_device_type : felt,
    #         src_device_grid : Vec2,
    #         dst_device_grid : Vec2,
    #         locs_len : felt,
    #         locs : Vec2*
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    owner           = _felt_from_iter (it, scale=False, signed=False)
    utx_label       = _felt_from_iter (it, scale=False, signed=False)
    utx_device_type = _felt_from_iter (it, scale=False)
    src_device_grid = Vec2.from_iter  (it, scale=False)
    dst_device_grid = Vec2.from_iter  (it, scale=False)
    locs_len        = _felt_from_iter (it, scale=False)
    locs = [
        Vec2.from_iter(it, scale=False).to_json() for _ in range (locs_len)
    ]

    return owner, utx_label, utx_device_type, src_device_grid, dst_device_grid, locs_len, locs

#
# Decode event: universe::player_pickup_utx_occurred
#
def decode_player_pickup_utx_occurred_event (event: Event) -> Tuple [int, Vec2]:
    it = iter (event.data)

    # @event
    # func player_pickup_utx_occurred (
    #         owner : felt,
    #         grid : Vec2
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    owner = _felt_from_iter (it, scale=False, signed=False)
    grid  = Vec2.from_iter  (it, scale=False)

    return owner, grid

#
# Decode event: universe::resource_update_at_harvester_occurred
#
def decode_resource_update_at_harvester_occurred_event (event: Event) -> Tuple [int, int]:
    it = iter (event.data)

    # @event
    # func resource_update_at_harvester_occurred (
    #         device_id : felt,
    #         new_quantity : felt
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    device_id    = _felt_from_iter (it, scale=False, signed=False)
    new_quantity = _felt_from_iter (it, scale=False)

    return device_id, new_quantity

#
# Decode event: universe::resource_update_at_transformer_occurred
#
def decode_resource_update_at_transformer_occurred_event (event: Event) -> Tuple [int, int, int]:
    it = iter (event.data)

    # @event
    # func resource_update_at_transformer_occurred (
    #         device_id : felt,
    #         new_quantity_pre : felt,
    #         new_quantity_post : felt
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    device_id         = _felt_from_iter (it, scale=False, signed=False)
    new_quantity_pre  = _felt_from_iter (it, scale=False)
    new_quantity_post = _felt_from_iter (it, scale=False)

    return device_id, new_quantity_pre, new_quantity_post

#
# Decode event: universe::resource_update_at_upsf_occurred
#
def decode_resource_update_at_upsf_occurred_event (event: Event) -> Tuple [int, int, int]:
    it = iter (event.data)

    # @event
    # func resource_update_at_upsf_occurred (
    #         device_id : felt,
    #         element_type : felt,
    #         new_quantity : felt
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    device_id    = _felt_from_iter (it, scale=False, signed=False)
    element_type = _felt_from_iter (it, scale=False)
    new_quantity = _felt_from_iter (it, scale=False)

    return device_id, element_type, new_quantity

#
# Decode event: universe::energy_update_at_device_occurred
#
def decode_energy_update_at_device_occurred_event (event: Event) -> Tuple [int, int]:
    it = iter (event.data)

    # @event
    # func energy_update_at_device_occurred (
    #         device_id : felt,
    #         new_quantity : felt
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    device_id     = _felt_from_iter (it, scale=False, signed=False)
    new_quantity  = _felt_from_iter (it, scale=False)

    return device_id, new_quantity

#
# Decode event: universe::impulse_applied_occurred
#
def decode_impulse_applied_occurred_event (event: Event) -> Tuple [Vec2]:
    it = iter (event.data)

    # @event
    # func impulse_applied_occurred (
    #     impulse : Vec2
    # ):
    # end

    impulse = Vec2.from_iter (it, scale=True)

    return impulse

#
# Decode event: universe::player_transfer_undeployed_fungible_device_occurred
#
def decode_player_transfer_undeployed_fungible_device_occurred_event (event: Event) -> Tuple [int, int, int, int]:
    it = iter (event.data)

    # @event
    # func player_transfer_undeployed_fungible_device_occurred (
    #         event_counter : felt,
    #         src : felt,
    #         dst : felt,
    #         device_type : felt,
    #         device_amount : felt
    #     ):
    # end

    event_counter = _felt_from_iter (it, scale=False)
    src_account   = _felt_from_iter (it, scale=False, signed=False)
    dst_account   = _felt_from_iter (it, scale=False, signed=False)
    device_type   = _felt_from_iter (it, scale=False)
    device_amount = _felt_from_iter (it, scale=False)

    return src_account, dst_account, device_type, device_amount

#
# Decode event: universe::player_transfer_undeployed_nonfungible_device_occurred
#
def decode_player_transfer_undeployed_nonfungible_device_occurred_event (event: Event) -> Tuple [int, int, int]:
    it = iter (event.data)

    # @event
    # func player_transfer_undeployed_nonfungible_device_occurred (
    #         event_counter : felt,
    #         src : felt,
    #         dst : felt,
    #         device_id : felt
    #     ):
    # end

    event_counter = _felt_from_iter (it, scale=False)
    src_account   = _felt_from_iter (it, scale=False, signed=False)
    dst_account   = _felt_from_iter (it, scale=False, signed=False)
    device_id     = _felt_from_iter (it, scale=False, signed=False)

    return src_account, dst_account, device_id

#
# Decode event: universe::player_upsf_build_fungible_device_occurred
#
def decode_player_upsf_build_fungible_device_occurred_event (event: Event) -> Tuple [int, Vec2, int, int]:
    it = iter (event.data)

    # @event
    # func player_upsf_build_fungible_device_occurred (
    #         event_counter : felt,
    #         owner : felt,
    #         grid : Vec2,
    #         device_type : felt,
    #         device_count : felt
    #     ):
    # end

    event_counter = _felt_from_iter (it, scale=False)
    owner         = _felt_from_iter (it, scale=False, signed=False)
    grid          = Vec2.from_iter  (it, scale=False)
    device_type   = _felt_from_iter (it, scale=False)
    device_count  = _felt_from_iter (it, scale=False)

    return owner, grid, device_type, device_count

#
# Decode event: universe::create_new_nonfungible_device_occurred
#
def decode_create_new_nonfungible_device_occurred_event (event: Event) -> Tuple [int, int, int]:
    it = iter (event.data)

    # @event
    # func create_new_nonfungible_device_occurred (
    #         event_counter : felt,
    #         owner : felt,
    #         type : felt,
    #         id : felt
    #     ):
    # end

    event_counter = _felt_from_iter (it, scale=False)
    owner         = _felt_from_iter (it, scale=False, signed=False)
    device_type   = _felt_from_iter (it, scale=False)
    device_id     = _felt_from_iter (it, scale=False, signed=False))

    return owner, device_type, device_id


##############
# Lobby events
##############

#
# Decode event: lobby::universe_activation_occurred
#
def decode_universe_activation_occurred_event (event: Event) -> Tuple [int, int, int, int, list]:

    # @event
    # func universe_activation_occurred (
    #     event_counter      : felt,
    #     universe_index     : felt,
    #     universe_address   : felt,
    #     arr_player_adr_len : felt,
    #     arr_player_adr     : felt*
    # ):
    # end

    it = iter (event.data)

    event_counter      = _felt_from_iter (it, scale=False)
    universe_idx       = _felt_from_iter (it, scale=False)
    universe_adr       = _felt_from_iter (it, scale=False, signed=False)
    arr_player_adr_len = _felt_from_iter (it, scale=False)
    arr_player_adr     = [
        _felt_from_iter (it, scale=False, signed=False) for _ in range (arr_player_adr_len)
    ]

    return event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr

#
# Decode event: lobby::universe_deactivation_occurred
#
def decode_universe_deactivation_occurred_event (event: Event) -> Tuple [int, int, int, int, list]:

    # @event
    # func universe_deactivation_occurred (
    #     event_counter      : felt,
    #     universe_index     : felt,
    #     universe_address   : felt,
    #     arr_player_adr_len : felt,
    #     arr_player_adr     : felt*
    # ):
    # end

    it = iter (event.data)

    event_counter      = _felt_from_iter (it, scale=False)
    universe_idx       = _felt_from_iter (it, scale=False)
    universe_adr       = _felt_from_iter (it, scale=False, signed=False)
    arr_player_adr_len = _felt_from_iter (it, scale=False)
    arr_player_adr     = [
        _felt_from_iter (it, scale=False, signed=False) for _ in range (arr_player_adr_len)
    ]

    return event_counter, universe_idx, universe_adr, arr_player_adr_len, arr_player_adr

#
# Decode event: lobby::ask_to_queue_occurred
#
def decode_ask_to_queue_occurred_event (event: Event) -> Tuple [int, int]:
    it = iter (event.data)

    # @event
    # func ask_to_queue_occurred (
    #     account : felt,
    #     queue_idx : felt
    #     ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    account    = _felt_from_iter (it, scale=False, signed=False)
    queue_idx  = _felt_from_iter (it, scale=False)

    return account, queue_idx

#
# Decode event: lobby::give_invitation_occurred
#
def decode_give_invitation_occurred_event (event: Event) -> Tuple [int, int]:
    it = iter (event.data)

    # @event
    # func give_invitation_occurred (
    #     event_counter : felt,
    #     account : felt
    # ):
    # end

    event_counter = _felt_from_iter(it, scale=False)
    account = _felt_from_iter(it, scale=False, signed=False)

    return account
