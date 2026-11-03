package main

import rl "vendor:raylib"

MAX_PROJECTILES :: 128

Projectile_System :: struct {
    positions: [MAX_PROJECTILES]rl.Vector2,
    active_projectiles: i32,
    projectile_texture: rl.Texture2D,
    projectile_speed: f32,
}

create_projectile_system :: proc() -> Projectile_System {
    return {
        projectile_texture = rl.LoadTexture("assets/kenny/puzzle pack/element_yellow_diamond.png"),
        projectile_speed = 300
    }
}

destroy_projectile_system :: proc(ps: ^Projectile_System) {
    rl.UnloadTexture(ps.projectile_texture)
}

projectile_reset :: proc(ps: ^Projectile_System) {
    ps.active_projectiles = 0
}


projectile_add :: proc(ps: ^Projectile_System, position: rl.Vector2) {
    if ps.active_projectiles < MAX_PROJECTILES {
        ps.positions[ps.active_projectiles] = position
        ps.active_projectiles += 1
    }
}

projectile_get_bounds :: proc(ps: ^Projectile_System, position: rl.Vector2) -> rl.Rectangle {
    // Hardcoded for now, but should improve this later
    return {
        x = position.x + 4,
        y = position.y + 4,
        width = 24,
        height = 24,
    }
}

projectile_update :: proc(ps: ^Projectile_System, dm: ^Debris_Manager) {
    frame_time := get_capped_frame_time()
    #reverse for &pos, i in ps.positions[:ps.active_projectiles] {
        pos.y -= ps.projectile_speed * frame_time

        if pos.y < screen_rect.y - f32(ps.projectile_texture.height) {
            sliced_projectiles := ps.positions[:ps.active_projectiles]
            array_swap_back(&sliced_projectiles, i, int(ps.active_projectiles - 1))
            ps.active_projectiles -= 1
        } else {
            for &debris in dm.active_debris[:dm.debris_count] {
                debris_bounds := get_debris_bounds(&debris)
                projectile_bounds := projectile_get_bounds(ps, pos)
                if rl.CheckCollisionRecs(debris_bounds, projectile_bounds) {
                    // Find the part that we hit, if any

                    #reverse for &part, part_index in debris.parts[:debris.part_count] {
                        part_bounds := part_rect(debris.position, part.position)
                        if rl.CheckCollisionRecs(part_bounds, projectile_bounds) {
                            part.health -= 2
                            if part.health <= 0 {
                                sliced_debris := debris.parts[:debris.part_count]
                                array_swap_back(&sliced_debris, part_index, int(debris.part_count - 1))
                                debris.part_count -= 1
                            }

                            sliced_projectiles := ps.positions[:ps.active_projectiles]
                            array_swap_back(&sliced_projectiles, i, int(ps.active_projectiles - 1))
                            ps.active_projectiles -= 1
                            break
                        }
                    }
                }
            }
        }
    }
}

projectile_render :: proc(ps: ^Projectile_System) {
    for pos in ps.positions[:ps.active_projectiles] {
        rl.DrawTextureEx(ps.projectile_texture, pos, {}, 0.75, rl.WHITE)
    }
}



