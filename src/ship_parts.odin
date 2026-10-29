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

do_parts_collide :: proc(parts, others: []PartData, parts_offset, others_offset: rl.Vector2) -> bool {

    for part in parts {
        local_part_pos := part.position * ship_part_size

        part_rect := rl.Rectangle {
            f32(local_part_pos.x) + parts_offset.x,
            f32(local_part_pos.y) + parts_offset.y,
            f32(ship_part_size.x),
            f32(ship_part_size.y)
        }

        for other in others {

            local_other_pos := other.position * ship_part_size
            other_rect := rl.Rectangle {
                f32(local_other_pos.x) + others_offset.x,
                f32(local_other_pos.y) + others_offset.y,
                f32(ship_part_size.x),
                f32(ship_part_size.y)
            }

            if rl.CheckCollisionRecs(part_rect, other_rect) {
                return true
            }
        }
    }
    return false
}