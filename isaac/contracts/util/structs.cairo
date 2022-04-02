
struct Vec2:
    member x : felt
    member y : felt
end

# normally:
#   q refers to position
#   qd refers to velocity
struct Dynamic:
    member q : Vec2
    member qd : Vec2
end

struct Dynamics:
    member sun0 : Dynamic
    member sun1 : Dynamic
    member sun2 : Dynamic
    member plnt : Dynamic
end

struct MacroEvent:
    member new_dynamics : Dynamics
end

# TODO
struct MicroEvent:
    member x : felt
    member y : felt
end

struct UtbSetInfo:
    member owner : felt
    member start_index : felt
    member end_index : felt
end