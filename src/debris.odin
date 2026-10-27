package main

import rl "vendor:raylib"
import "core:math/rand"

Debris_Data :: struct {
    position: rl.Vector2,
    parts: [8]PartData,
    part_count: i32,
}

Debris_Manager :: struct {
    active_debris: [8]Debris_Data,
    debris_count: i32,
}

reset_debris :: proc(debris: ^Debris_Data) {
    debris.position = rl.Vector2 { 0, 0 }
    debris.part_count = 0
}

NEIGHBOR_PARTS :: [4][2]i32 {
    { 1, 0 },
    { -1, 0 },
    { 0, 1 },
    { 0, -1 },
}

generate_random_debris :: proc(manager: ^Debris_Manager) {
    if manager.debris_count < len(manager.active_debris) {
        new_debris := &manager.active_debris[manager.debris_count]
        manager.debris_count += 1

        reset_debris(new_debris)

        new_debris.position = rl.Vector2 { SCREEN_WIDTH / 2, 200 }

        part_count := rand.int32_range(2, 8)

        current_part_pos: [2]i32 = { 0, 0 }
        part_id := rand.choice_enum(PartId)
        new_debris.parts[0] = { id = part_id, position = current_part_pos}

        for i in 1..<part_count {

            no_issues := false
            neighbor_dirs := NEIGHBOR_PARTS

            verify: for n := 0; n < 4 && !no_issues; n += 1 {
                desired_pos := current_part_pos + neighbor_dirs[rand.int32_range(0, 3)]
                for j in 0..<i {
                    if new_debris.parts[j].position == desired_pos {
                        continue verify
                    }
                }

                no_issues = true
                current_part_pos = desired_pos
            }

            if no_issues {
                part_id := rand.choice_enum(PartId)
                new_debris.parts[i] = { id = part_id, position = current_part_pos}
            } else {
                part_count = i
                break
            }
        }
        new_debris.part_count = part_count

        bounds := get_debris_bounds(new_debris^)
        new_debris.position.y = -bounds.height
        new_debris.position.x = rand.float32_range(bounds.width, SCREEN_WIDTH - bounds.width)
    }
}

get_debris_bounds :: proc(debris: Debris_Data) -> rl.Rectangle {
    min_pos: [2]i32 = {}
    max_pos: [2]i32 = {}

    // Is this making a copy of the array?
    parts_array := debris.parts

    int_position: [2]i32= { i32(debris.position.x), i32(debris.position.y) }

    for part in parts_array[0:debris.part_count] {
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
        debris.position.x + f32(min_pos.x),
        debris.position.y + f32(min_pos.y),
        f32(max_pos.x - min_pos.x),
        f32(max_pos.y - min_pos.y)
    }
}