from dataclasses import dataclass
from typing import Any, Iterator, Tuple

from apibara.model import Event


STARK_PRIME = (
    3618502788666131213697322783095070105623107215331596699973092056135872020481
)
STARK_PRIME_HALF = (
    1809251394333065606848661391547535052811553607665798349986546028067936010240
)


def _felt_from_iter(it: Iterator[bytes], scale=True):
    fe = int.from_bytes(next(it), "big")
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
    def from_iter(it: Iterator[bytes]):
        x = _felt_from_iter(it)
        y = _felt_from_iter(it)
        return Vec2(x, y)

    def to_json(self) -> Any:
        return {"x": self.x, "y": self.y}


@dataclass
class Dynamic:
    q: Vec2
    qd: Vec2

    @staticmethod
    def from_iter(it: Iterator[bytes]):
        q = Vec2.from_iter(it)
        qd = Vec2.from_iter(it)
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

#
# Decode event: universe::`forward_world_macro_occurred`
#
def decode_forward_world_event(event: Event) -> Tuple[Dynamic, int]:
    data_iter = iter(event.data)

    dynamics = Dynamics.from_iter(data_iter)
    phi = _felt_from_iter(data_iter, scale=False)

    return dynamics, phi

#
# Decode event: universe::`give_undeployed_device_occurred`
#
def decode_give_undeployed_device_occurred_event (event: Event) -> Tuple []:

        # event_counter : felt,
        # to : felt,
        # type : felt,
        # amount : felt

    return