%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

const PROPOSAL_PERIOD = 720 # 1 day = 24hr * 60min / 2min (~block time) = 720 blocks

@view
func lookup_proposal_period {} (
    ) -> (period : felt):

    let period = PROPOSAL_PERIOD

    return (period)
end
