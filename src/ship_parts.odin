package main

import rl "vendor:raylib"

PartId :: enum {Hull, Blaster, Thruster, Shield}

PartData :: struct {
    position: [2]i32,
    id: PartId,
}

PartTextures :: [PartId] rl.Texture

get_part_bounds :: proc(parts: []PartData) -> rl.Rectangle {
    min_pos: [2]i32 = {}
    max_pos: [2]i32 = {}

    for part in parts {
        min_pos.x = min(part.position.x, min_pos.x)
        min_pos.y = min(part.position.y, min_pos.y)

        max_pos.x = max(part.position.x, max_pos.x)
        max_pos.y = max(part.position.y, max_pos.y)
    }

    min_pos = min_pos * ship_part_size
    // The max value also needs to take into account the size of the texture itself so this final addition effectively
    // means we are treating the bottom right corner of the max index as the max instead of the top left.
    max_pos = max_pos * ship_part_size + ship_part_size

    return rl.Rectangle {
        f32(min_pos.x),
        f32(min_pos.y),
        f32(max_pos.x - min_pos.x),
        f32(max_pos.y - min_pos.y)
    }
}