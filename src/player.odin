package main

import "core:math"
import "core:slice"
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

weld_debris_to_player :: proc(player_data: ^Player_Data, debris_data: ^Debris_Data, debris_translation: [2]i32) {

    for part in debris_data.parts[0:debris_data.part_count] {
        part_array := &player_data.parts[part.id]
        append(part_array, PartData { position = part.position + debris_translation, id = part.id })
    }

    // Since some debris might be shot apart we need to do this just in case
    player_check_for_unreachable_parts(player_data)
}

does_player_contain_part :: proc(player_data: ^Player_Data, part_location: [2]i32) -> bool {
    for parts in player_data.parts {
        for part_data in parts {
            if part_data.position == part_location {
                return true
            }
        }
    }

    return false
}

player_check_for_unreachable_parts :: proc(player_data: ^Player_Data) {
    // Do a walk of the player and mark any unreachable squares as missing
    tiles_found := [dynamic][2]i32 {}
    defer delete(tiles_found)

    tiles_to_check := [dynamic][2]i32 {}
    defer delete(tiles_to_check)

    append(&tiles_to_check, {0, 1})
    append(&tiles_to_check, {0, -1})
    append(&tiles_to_check, {1, 0})
    append(&tiles_to_check, {-1, 0})

    for len(tiles_to_check) > 0 {
        cur := pop_front(&tiles_to_check)
        if does_player_contain_part(player_data, cur) {
            if !slice.contains(tiles_found[:], cur) {
                append(&tiles_found, cur)

                if !slice.contains(tiles_to_check[:], cur + {0, 1}) && !slice.contains(tiles_found[:], cur + {0, 1}){
                    append(&tiles_to_check, cur + {0, 1})
                }
                if !slice.contains(tiles_to_check[:], cur + {0, -1}) && !slice.contains(tiles_found[:], cur + {0, -1}){
                    append(&tiles_to_check, cur + {0, -1})
                }
                if !slice.contains(tiles_to_check[:], cur + {1, 0}) && !slice.contains(tiles_found[:], cur + {1, 0}){
                    append(&tiles_to_check, cur + {0, 1})
                }
                if !slice.contains(tiles_to_check[:], cur + {-1, 0}) && !slice.contains(tiles_found[:], cur + {-1, 0}){
                    append(&tiles_to_check, cur + {-1, 0})
                }
            }
        }
    }

    // Any tiles in player not in tiles found need to be destroyed
    sliced_found := tiles_found[:]
    for &parts in player_data.parts {
        #reverse for part_data, index in parts {
            if !slice.contains(sliced_found, part_data.position) {
                destruction_add_part(&destruction, player_data^, part_data.id, part_data.position)
                unordered_remove(&parts, index)
            }
        }
    }
}

damage_player :: proc(player_data: ^Player_Data, impacting_debris: ^Debris_Data, impact_location: [2]i32, debris_part_index: int) {
    debris_part := &impacting_debris.parts[debris_part_index]

    player_hit := false

    // Find the tile that has been hit
    search: for &parts in player_data.parts {
        for &part_data, index in parts {
            if part_data.position == impact_location {
                should_break := false
                // Deal damage to the debris
                debris_part.health -= 1
                if debris_part.health <= 0 {
                    sliced_debris := impacting_debris.parts[:impacting_debris.part_count]
                    array_swap_back(&sliced_debris, debris_part_index, int(impacting_debris.part_count - 1))
                    impacting_debris.part_count -= 1
                    should_break = true
                }

                // Deal damage to the part
                part_data.health -= 1
                if part_data.health <= 0 {
                    destruction_add_part(&destruction, player_data^, part_data.id, part_data.position)
                    unordered_remove(&parts, index)
                    player_hit = true
                    should_break = true
                }

                if should_break {
                    break search
                }
            }
        }
    }

    if player_hit {
        player_check_for_unreachable_parts(player_data)
    }
}

