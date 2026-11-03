package main

import rl "vendor:raylib"

MAX_DESTRUCTION :: 128
PART_DRIFT_SPEED :f32 : 60
PART_TIMEOUT :f32  : 4

Destruction_System :: struct {
    parts: [MAX_DESTRUCTION]PartId,
    positions: [MAX_DESTRUCTION]rl.Vector2,
    velocities: [MAX_DESTRUCTION]rl.Vector2,
    timeout: [MAX_DESTRUCTION]f32,
    active_destruction: i32,
    next_free_part: i32,
}

create_destruction_system :: proc() -> Destruction_System {
    return {}
}

destruction_add_part :: proc(ds: ^Destruction_System, player_data: Player_Data, part_id: PartId, location: [2]i32) {

    part_world_position := player_data.position + to_vector(part_position(location))
    delta := part_world_position - player_data.position
    part_velocity := rl.Vector2Normalize(delta) * PART_DRIFT_SPEED


    index := ds.next_free_part
    ds.next_free_part = (ds.next_free_part + 1) % MAX_DESTRUCTION

    ds.parts[index] = part_id
    ds.positions[index] = part_world_position
    ds.velocities[index] = part_velocity
    ds.timeout[index] = PART_TIMEOUT

    ds.active_destruction += 1
}

destruction_update :: proc(ds: ^Destruction_System) {
    if ds.active_destruction <= 0 {
        return
    }

    frame_time := get_capped_frame_time()
    for i in 0..<MAX_DESTRUCTION {
        if ds.timeout[i] > 0 {
            ds.timeout[i] -= frame_time
            if ds.timeout[i] < 0 {
                ds.active_destruction -= 1
            }

            ds.positions[i] += ds.velocities[i] * frame_time
        }
    }
}

destruction_render :: proc(ds: Destruction_System) {
    if ds.active_destruction <= 0 {
        return
    }

    for i in 0..<MAX_DESTRUCTION {
        if ds.timeout[i] > 0 {
            position := ds.positions[i]
            alpha := 255 - u8((max(0, PART_TIMEOUT - ds.timeout[i]) / PART_TIMEOUT * 255))
            rl.DrawTexture(part_textures[ds.parts[i]], i32(position.x), i32(position.y), rl.Color {255, 255, 255, alpha})
        }
    }
}



