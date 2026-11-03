package main

import rl "vendor:raylib"
import "core:math/rand"

Debris_Data :: struct {
    position: rl.Vector2,
    parts: [8]PartData,
    part_count: i32,
}

DEBRIS_SPAWN_INTERVAL :f32: 3
Debris_Manager :: struct {
    active_debris: [16]Debris_Data,
    debris_count: i32,
    debris_spawn_time: f32,
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

debris_update :: proc(manager: ^Debris_Manager) {
    #reverse for debris, index in manager.active_debris[:manager.debris_count] {
        if debris.part_count <= 0 {
            sliced_debris := manager.active_debris[0:]
            array_swap_back(&sliced_debris, index, int(manager.debris_count - 1))
            manager.debris_count -= 1
            manager.debris_spawn_time = 0
//            generate_random_debris(manager)
        }

    }

    if manager.debris_spawn_time > 0 {
        manager.debris_spawn_time -= get_capped_frame_time()
    } else if manager.debris_count < 10 {
        if rand.int32_range(0, 5) == 0 {
            generate_random_debris(manager)
        } else {
            generate_junk_debris(manager)
        }

        manager.debris_spawn_time = DEBRIS_SPAWN_INTERVAL
    }
}

generate_junk_debris :: proc(manager: ^Debris_Manager) {
    if manager.debris_count < len(manager.active_debris) {
        new_debris := &manager.active_debris[manager.debris_count]
        manager.debris_count += 1

        reset_debris(new_debris)

        new_debris.position = rl.Vector2 { screen_rect.width / 2, 200 }

        part_count := rand.int32_range(1, 3)

        current_part_pos: [2]i32 = { 0, 0 }
        part_id := rand.choice_enum(PartId)
//        new_debris.parts[0] = { id = .Junk, position = current_part_pos}
        new_debris.parts[0] = create_part(current_part_pos, .Junk, 2)
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
                new_debris.parts[i] = create_part(current_part_pos, .Junk, 2)
            } else {
                part_count = i
                break
            }
        }
        new_debris.part_count = part_count

        bounds := get_debris_bounds(new_debris)
        new_debris.position.y = -bounds.height
        new_debris.position.x = rand.float32_range(bounds.width, screen_rect.width - bounds.width)

    }
}

generate_random_debris :: proc(manager: ^Debris_Manager) {
    if manager.debris_count < len(manager.active_debris) {
        new_debris := &manager.active_debris[manager.debris_count]
        manager.debris_count += 1

        reset_debris(new_debris)

        new_debris.position = rl.Vector2 { screen_rect.width / 2, 200 }

        part_count := rand.int32_range(2, 8)

        current_part_pos: [2]i32 = { 0, 0 }
        part_id := rand.choice_enum(PartId)
        new_debris.parts[0] = create_part(current_part_pos, part_id)

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
//                part_id := rand.choice_enum(PartId)
                part_id := PartId(rand.int32_range(0, 3))
                new_debris.parts[i] = create_part(current_part_pos, part_id)
            } else {
                part_count = i
                break
            }
        }
        new_debris.part_count = part_count

        bounds := get_debris_bounds(new_debris)
        new_debris.position.y = -bounds.height
        new_debris.position.x = rand.float32_range(bounds.width, screen_rect.width - bounds.width)
    }
}

get_debris_bounds :: proc(debris: ^Debris_Data) -> rl.Rectangle {
    local_bounds := get_part_bounds(debris.parts[0:debris.part_count])
    local_bounds.x = debris.position.x + local_bounds.x
    local_bounds.y = debris.position.y + local_bounds.y

    return local_bounds
}