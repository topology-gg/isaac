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
    member score0_ball : ObjectState
    member score1_ball : ObjectState
    member forbid_ball : ObjectState
    member player_ball : ObjectState
end

struct LevelState:
    member score0_ball : Vec2
    member score1_ball : Vec2
    member forbid_ball : Vec2
    member player_ball : Vec2
end
