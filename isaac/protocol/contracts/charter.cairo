%lang starknet
from starkware.cairo.common.cairo_builtins import HashBuiltin

const PROPOSAL_PERIOD = 720 # 1 day = 24hr * 60min / 2min (~block time) = 720 blocks
const NEW_VOICES_FOR_GRADE_0 = 5 # in quadratic terms maps to 2 votes plus 1 voice left
const NEW_VOICES_FOR_GRADE_1 = 82 # in quadratic terms maps to 9 votes plus 1 voice left

@view
func lookup_proposal_period {} (
    ) -> (period : felt):

    let period = PROPOSAL_PERIOD

    return (period)
end

@view
func lookup_voices_given_play_grade {} (
    play_grade : felt) -> (votes : felt):
    alloc_locals

    if play_grade == 0:
        return (NEW_VOICES_FOR_GRADE_0)
    end

    if play_grade == 1:
        return (NEW_VOICES_FOR_GRADE_1)
    end

    #
    # Otherwise return 0 voice
    #
    return (0)
end

@view
func lookup_voices_required_given_intended_votes {} (
    intended_votes : felt) -> (voices_required : felt):

    #
    # Use plural voting with power of 2
    #
    let voices_required = intended_votes * intended_votes

    return (voices_required)
end