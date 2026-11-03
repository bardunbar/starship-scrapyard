package main

import "core:mem"
import "core:log"
import rl "vendor:raylib"
import "core:fmt"
//import "core:math"

SCREEN_WIDTH :: 1920
SCREEN_HEIGHT :: 1080

GAME_NAME :: "Starship Scrapyard"
BASE_PLAYER_SPEED :f32: 150

ship_part_size: [2]i32 = {}
screen_rect: rl.Rectangle = {}
part_textures: PartTextures = {}
destruction: Destruction_System = {}
projectiles: Projectile_System = {}

main :: proc() {
    when ODIN_DEBUG {
        track: mem.Tracking_Allocator
        mem.tracking_allocator_init(&track, context.allocator)
        context.allocator = mem.tracking_allocator(&track)

        defer {
            if len(track.allocation_map) > 0 {
                fmt.eprintf("=== %v allocations not freed: ===\n", len(track.allocation_map))
                for _, entry in track.allocation_map {
                    fmt.eprintf("- %v bytes @ %v\n", entry.size, entry.location)
                }
            }
            mem.tracking_allocator_destroy(&track)
        }
    }

    context.logger = log.create_console_logger()
    log.info(GAME_NAME)

    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, GAME_NAME)
    defer rl.CloseWindow()

    render_target := rl.LoadRenderTexture(SCREEN_WIDTH, SCREEN_HEIGHT)
    defer rl.UnloadRenderTexture(render_target)
    rl.SetTextureFilter(render_target.texture, rl.TextureFilter.BILINEAR)

    // Load up some images
    core_texture := rl.LoadTexture("assets/kenny/puzzle pack/element_grey_square.png")
    defer rl.UnloadTexture(core_texture)

    ship_part_width := core_texture.width
    ship_part_height := core_texture.height
    ship_part_size = [2]i32 {ship_part_width, ship_part_height}

    hull_texture := rl.LoadTexture("assets/kenny/puzzle pack/element_green_square.png")
    defer rl.UnloadTexture(hull_texture)

    blaster_texture := rl.LoadTexture("assets/kenny/puzzle pack/element_red_square.png")
    defer rl.UnloadTexture(blaster_texture)

    thruster_texture := rl.LoadTexture("assets/kenny/puzzle pack/element_yellow_square.png")
    defer rl.UnloadTexture(thruster_texture)

    shield_texture := rl.LoadTexture("assets/kenny/puzzle pack/element_blue_square.png")
    defer rl.UnloadTexture(shield_texture)

    junk_texture := rl.LoadTexture("assets/kenny/puzzle pack/element_black_square.png")
    defer rl.UnloadTexture(junk_texture)

    part_textures = PartTextures {
        .Hull = hull_texture,
        .Blaster = blaster_texture,
        .Thruster = thruster_texture,
        .Shield = shield_texture,
        .Junk = junk_texture,
    }

    camera := rl.Camera2D {
        target = {},
        offset = {},
        rotation = 0,
        zoom = 1,
    }

    screen_rect = get_screen_bounds(camera)

    initialize_starfields()
    defer teardown_starfields()

    player_data := Player_Data {
        position = rl.Vector2 { screen_rect.width / 2 - f32(core_texture.width / 2), screen_rect.height - f32(50 + core_texture.height) },
        texture = core_texture,
        horizontal_speed = 300,
        vertical_speed = BASE_PLAYER_SPEED,
    }

    append(&player_data.parts[PartId.Hull], create_part({ 0, -1 }, .Hull))
    append(&player_data.parts[PartId.Hull], create_part({ 1, -1 }, .Hull))
    append(&player_data.parts[PartId.Hull], create_part({ -1, -1 }, .Hull))
//    append(&player_data.parts[PartId.Hull], create_part({ 0, -2 }, .Hull))
//
//    append(&player_data.parts[PartId.Thruster], create_part({ 1, 0 }, .Thruster))
//    append(&player_data.parts[PartId.Thruster], create_part({ -1, 0 }, .Thruster))
//
//    append(&player_data.parts[PartId.Blaster], create_part({ 2, -1 }, .Blaster))
//    append(&player_data.parts[PartId.Blaster], create_part({ -2, -1 }, .Blaster))
//
//    append(&player_data.parts[PartId.Shield], create_part({ 0, -3 }, .Shield))
//    append(&player_data.parts[PartId.Shield], create_part({ 1, -2 }, .Shield))
//    append(&player_data.parts[PartId.Shield], create_part({ -1, -2 }, .Shield))

    debris_manager := Debris_Manager {
        debris_spawn_time = 0
    }
//    generate_random_debris(&debris_manager)
//    generate_junk_debris(&debris_manager)

    destruction = create_destruction_system()
    projectiles = create_projectile_system()
    defer destroy_projectile_system(&projectiles)

    rl.SetTargetFPS(60)

    frame_counter := 0


    for !rl.WindowShouldClose() {

        frame_counter += 1

        {
            // Update game logic
            if rl.IsKeyPressed(rl.KeyboardKey.B) {
                rl.ToggleBorderlessWindowed()
            }

            // Handle inputs
            input_vector := rl.Vector2 { 0, 0 }
            if rl.IsKeyDown(rl.KeyboardKey.A) {
                input_vector.x -= 1
            }

            if rl.IsKeyDown(rl.KeyboardKey.D) {
                input_vector.x += 1
            }

            if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
                for blaster in player_data.parts[.Blaster] {
                    projectile_add(&projectiles, player_data.position + to_vector(part_position(blaster.position)))
                }
            }

            player_data.position += rl.Vector2 { input_vector.x *  player_data.horizontal_speed * get_capped_frame_time(), 0 }

            player_bounds := get_player_bounds(&player_data)

            // Update any active debris -- Loop in reverse so we can remove with a swap
            #reverse for &debris, index in debris_manager.active_debris[0:debris_manager.debris_count] {
               debris.position += rl.Vector2 { 0, player_data.vertical_speed * get_capped_frame_time() }
                bounds := get_debris_bounds(&debris)

                if (bounds.y > screen_rect.height) {
                    debris.part_count = 0
//                    sliced_debris := debris_manager.active_debris[0:]
//                    array_swap_back(&sliced_debris, index, int(debris_manager.debris_count - 1))
//                    debris_manager.debris_count -= 1
//                    generate_random_debris(&debris_manager)
//                    generate_junk_debris(&debris_manager)
                } else {
                    contacts := get_part_contacts(&player_data, &debris)

                    running_slide_adjustment: f32 = 0
                    should_weld := false
                    for contact, index in contacts[:debris.part_count] {
                        if contact.do_weld {

                            // Check the contact type, if its junk then we need to handle junk.
                            if debris.parts[index].id == .Junk {
                                impacting_location := contact.player_relative_location + debris.parts[index].position + {0, 1}
                                damage_player(&player_data, &debris, impacting_location, index)
                            } else {
                                // Otherwise do a weld
                                should_weld = true
                                weld_debris_to_player(&player_data, &debris, contact.player_relative_location)


                                player_data.vertical_speed = BASE_PLAYER_SPEED + f32(len(player_data.parts[.Thruster])) * 10
//                                sliced_debris := debris_manager.active_debris[0:]
//                                array_swap_back(&sliced_debris, index, int(debris_manager.debris_count - 1))
//                                debris_manager.debris_count -= 1
                                debris.part_count = 0
//                                generate_random_debris(&debris_manager)
//                                generate_junk_debris(&debris_manager)
                                break
                            }
                        } else if contact.do_slide {
                            running_slide_adjustment = contact.slide_offset
                        }
                    }

                    if !should_weld {
                        debris.position.x += running_slide_adjustment
                    }
                }
            }

            screen_rect = get_screen_bounds(camera)

            update_starfields()

            debris_update(&debris_manager)
            destruction_update(&destruction)
            projectile_update(&projectiles, &debris_manager)
        }

        {
            // Render the world
            rl.BeginTextureMode(render_target)
            defer rl.EndTextureMode()

            rl.ClearBackground(rl.BLACK)
            render_starfield_layer()

            rl.BeginMode2D(camera)
            defer rl.EndMode2D()

            rl.DrawTexture(player_data.texture, i32(player_data.position.x), i32(player_data.position.y), rl.WHITE)
            player_pos_int := [2]i32 { i32(player_data.position.x), i32(player_data.position.y)}

            for parts, part_id in player_data.parts {
                part_texture := part_textures[part_id]

                for part_data in parts {

                    part_position := player_pos_int + (part_data.position * ship_part_size)
                    rl.DrawTexture(part_texture, part_position.x, part_position.y, rl.WHITE)
                }
            }

            when ODIN_DEBUG {
                // Draw the player bounds
                rl.DrawRectangleLinesEx(get_player_bounds(&player_data), 4.0, rl.GREEN)
            }
            for current_debris in debris_manager.active_debris[0:debris_manager.debris_count] {
                current_debris := current_debris

                for part  in current_debris.parts[0:current_debris.part_count] {
                    part_texture := part_textures[part.id]

                    debris_pos_int :[2]i32 = { i32(current_debris.position.x), i32(current_debris.position.y) }

                    part_position := debris_pos_int + (part.position * ship_part_size)
                    rl.DrawTexture(part_texture, part_position.x, part_position.y, rl.WHITE)
                }

                when ODIN_DEBUG {
                    rl.DrawRectangleLinesEx(rl.Rectangle {current_debris.position.x, current_debris.position.y, f32(ship_part_width), f32(ship_part_height), }, 2.0, rl.YELLOW)
                    rl.DrawRectangleLinesEx(get_debris_bounds(&current_debris), 4.0, rl.YELLOW)
                }
            }

            projectile_render(&projectiles)
            destruction_render(destruction)
        }

        {
            // Render to screen

            rl.BeginDrawing()
            defer rl.EndDrawing()

            rl.ClearBackground(rl.BLACK)

            render_aspect := f32(render_target.texture.width) / f32(render_target.texture.height)
            target_height := f32(rl.GetScreenHeight())
            target_width := render_aspect * target_height
            target_x := (f32(rl.GetScreenWidth()) - target_width) / 2.0
            rl.DrawTexturePro(
                render_target.texture,
                rl.Rectangle {
                    0, 0, f32(render_target.texture.width), -f32(render_target.texture.height),
                },
                rl.Rectangle {
                    target_x, 0, target_width, target_height,
                },
                rl.Vector2 { 0, 0 },
                0.0,
                rl.WHITE,
            )
        }
    }


    for parts in player_data.parts {
        delete(parts)
    }

    log.destroy_console_logger(context.logger)
}

