package main

import rl "vendor:raylib"

Player_Data :: struct {
    position: rl.Vector2,
    texture: rl.Texture,
    horizontal_speed: f32,
    vertical_speed: f32,
    parts: [PartId][dynamic]PartData,
}

get_player_bounds :: proc(player_data: ^Player_Data) -> rl.Rectangle {
    min_pos := rl.Vector2 {}
    max_pos := rl.Vector2 {}

    for parts_of_type in player_data.parts {
        local_bounds := get_part_bounds(parts_of_type[:])

        min_pos.x = min(min_pos.x, local_bounds.x)
        min_pos.y = min(min_pos.y, local_bounds.y)

        max_pos.x = max(max_pos.x, local_bounds.x + local_bounds.width)
        max_pos.y = max(max_pos.y, local_bounds.y + local_bounds.height)
    }

    return rl.Rectangle {
        player_data.position.x + min_pos.x,
        player_data.position.y + min_pos.y,
        max_pos.x - min_pos.x,
        max_pos.y - min_pos.y,
    }
}

does_collide_with_player :: proc(player_data: ^Player_Data, debris_data: ^Debris_Data) -> bool {
    parts := debris_data.parts[0:debris_data.part_count]
    for player_parts in player_data.parts {
        if do_parts_collide(player_parts[:], parts, player_data.position, debris_data.position) {
            return true
        }
    }
    return false
}