%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.math import assert_le
from starkware.cairo.common.math_cmp import is_le
from starkware.cairo.common.alloc import alloc
from starkware.starknet.common.syscalls import (get_block_number, get_caller_address)

from contracts.design.constants import (
    CIV_SIZE, UNIVERSE_COUNT
)
from contracts.lobby.lobby_state import (
    ns_lobby_state_functions
)

## This contract is endorseable by IsaacDAO, which implements the CarseDAO standard

