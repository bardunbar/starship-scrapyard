package main

import "core:math"
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

does_collide_with_player :: proc(player_data: ^Player_Data, debris_data: ^Debris_Data) -> (bool, [2]i32, [2]i32) {
    parts := debris_data.parts[0:debris_data.part_count]

    min_dist_sqr := f32(math.F32_MAX)
    player_local_collision_position: [2]i32 = {}
    debris_translation: [2]i32 = {}
    found_collision := false

    for player_parts in player_data.parts {
        collision, player_collision, debris_collision := do_parts_collide(
            player_parts[:],
            parts,
            player_data.position,
            debris_data.position )

        if collision {

            player_pos := to_vector(part_position(player_collision)) + player_data.position
            debris_pos := to_vector(part_position(debris_collision)) + debris_data.position
            delta := debris_pos - player_pos

            dist_sqr := rl.Vector2DistanceSqr(player_pos, debris_pos)

            if dist_sqr < min_dist_sqr {
                min_dist_sqr = dist_sqr

                if math.abs(delta.x) > math.abs(delta.y) {
                    player_local_collision_position = player_collision + { i32(math.sign(delta.x)), 0 }
                } else {
                    player_local_collision_position = player_collision - { 0, 1 }
                }

                debris_translation = player_local_collision_position - debris_collision

                found_collision = true
            }
        }
    }
    return found_collision, player_local_collision_position, debris_translation
}

weld_debris_to_player :: proc(player_data: ^Player_Data, debris_data: ^Debris_Data, player_pos, debris_translation: [2]i32) {

    for part in debris_data.parts[0:debris_data.part_count] {
        part_array := &player_data.parts[part.id]
        append(part_array, PartData { position = part.position + debris_translation, id = part.id })
    }
}