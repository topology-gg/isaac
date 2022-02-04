%lang starknet

struct Vec2:
    member x : felt
    member y : felt
end

struct ObjectState:
    member pos : Vec2
    member vel : Vec2
    member acc : Vec2
end

struct GameState:
    member score0_ball : BallState
    member score1_ball : BallState
    member forbid_ball : BallState
    member player1_ball : BallState
    member player2_ball : BallState
    member player3_ball : BallState
end
