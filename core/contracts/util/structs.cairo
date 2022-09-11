struct Vec2 {
    x: felt,
    y: felt,
}

// normally:
//   q refers to position
//   qd refers to velocity
struct Dynamic {
    q: Vec2,
    qd: Vec2,
}

struct Dynamics {
    sun0: Dynamic,
    sun1: Dynamic,
    sun2: Dynamic,
    plnt: Dynamic,
}

struct MacroEvent {
    new_dynamics: Dynamics,
}

// TODO
struct MicroEvent {
    x: felt,
    y: felt,
}

struct UtbSetInfo {
    owner: felt,
    start_index: felt,
    end_index: felt,
}

struct Play {
    player_address: felt,
    grade: felt,
}
