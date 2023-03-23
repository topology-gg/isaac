from typing import Any, Iterator, Tuple

from apibara.starknet import FieldElement, felt
from apibara.starknet.proto.starknet_pb2 import Event

STARK_PRIME = (
    3618502788666131213697322783095070105623107215331596699973092056135872020481
)
STARK_PRIME_HALF = (
    1809251394333065606848661391547535052811553607665798349986546028067936010240
)


# Convert a FieldElement to an int.
def int_from_felt(it: Iterator[FieldElement]):
    i = felt.to_int(next(it))
    return i


#
# Decode event: new_puzzle_occurred
#
def decode_sns_register_occurred(event: Event) -> Tuple[int, int]:
    it = iter(event.data)

    addr = int_from_felt(it)
    name = int_from_felt(it)

    return addr, name
