from dataclasses import dataclass
from typing import Any, Iterator, Tuple

from apibara.model import Event


STARK_PRIME = (
    3618502788666131213697322783095070105623107215331596699973092056135872020481
)
STARK_PRIME_HALF = (
    1809251394333065606848661391547535052811553607665798349986546028067936010240
)

def _felt_from_iter (it: Iterator[bytes]):
    fe = int.from_bytes(next(it), "big")
    if fe > STARK_PRIME_HALF:
        fe = fe - STARK_PRIME
    return fe


@dataclass
class Cir:
    cell_idx: int
    typ: int

    # struct Cir:
    #     member cell_index : felt
    #     member type : felt
    # end

    @staticmethod
    def from_iter(it: Iterator[bytes]):
        cell_idx = _felt_from_iter (it)
        typ      = _felt_from_iter (it)
        return Cir (cell_idx, typ)

    def to_json(self) -> Any:
        return {"cell_idx": self.cell_idx, "typ": self.typ}


#
# Decode event: new_puzzle_occurred
#
def decode_new_puzzle_occurred (event: Event) -> Tuple[int, int, list]:
    it = iter(event.data)

    # @event
    # func new_puzzle_occurred (
    #         puzzle_id : felt,
    #         arr_circles_len : felt,
    #         arr_circles : Cir*
    #     ):
    # end

    puzzle_id       = _felt_from_iter (it)
    arr_circles_len = _felt_from_iter (it)
    arr_circles     = [
        Cir.from_iter (it) for _ in range (arr_circles_len)
    ]

    return puzzle_id, arr_circles_len, arr_circles

#
# Decode event: success_occurred
#
def decode_success_occurred (event: Event) -> Tuple[int, int, int, list]:
    it = iter(event.data)

    # @event
    # func success_occurred (
    #         solver : felt,
    #         puzzle_id : felt,
    #         arr_cell_indices_len : felt,
    #         arr_cell_indices : felt*
    #     ):
    # end

    solver               = _felt_from_iter (it)
    puzzle_id            = _felt_from_iter (it)
    arr_cell_indices_len = _felt_from_iter (it)
    arr_cell_indices     = [
        _felt_from_iter (it) for _ in range (arr_cell_indices_len)
    ]

    return solver, puzzle_id, arr_cell_indices_len, arr_cell_indices

# @event
# func s2m_ended_occurred ():
# end
# => this event does not require decoding because it has no payload
