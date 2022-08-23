from typing import Any, Iterator, Tuple

from apibara.model import Event


STARK_PRIME = (
    3618502788666131213697322783095070105623107215331596699973092056135872020481
)
STARK_PRIME_HALF = (
    1809251394333065606848661391547535052811553607665798349986546028067936010240
)

def _felt_from_iter (it: Iterator[bytes], signed=True):
    fe = int.from_bytes(next(it), "big")

    if signed:
        if fe > STARK_PRIME_HALF:
            fe = fe - STARK_PRIME

    return fe

#
# Decode event: new_puzzle_occurred
#
def decode_sns_register_occurred (event: Event) -> Tuple[int, int]:
    it = iter(event.data)

    # @event
    # func sns_register_occurred (
    #         addr : felt,
    #         name : felt
    #     ):
    # end

    addr = _felt_from_iter (it, signed=False)
    name = _felt_from_iter (it, signed=False)

    return addr, name
