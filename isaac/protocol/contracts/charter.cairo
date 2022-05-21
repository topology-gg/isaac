%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

const PROPOSAL_PERIOD = 720 # 1 day = 24hr * 60min / 2min (~block time) = 720 blocks
const NEW_VOTES_FOR_GRADE_0 = 1
const NEW_VOTES_FOR_GRADE_1 = 3

@view
func lookup_proposal_period {} (
    ) -> (period : felt):

    let period = PROPOSAL_PERIOD

    return (period)
end

@view
func lookup_votes_given_play_grade {} (
    play_grade : felt) -> (votes : felt):
    alloc_locals

    if play_grade == 0:
        return (NEW_VOTES_FOR_GRADE_0)
    end

    if play_grade == 1:
        return (NEW_VOTES_FOR_GRADE_1)
    end

    local pg = play_grade
    with_attr error_message ("play_grade value (pg) unrecognized"):
        assert 1 = 0
    end
    return (0)
end