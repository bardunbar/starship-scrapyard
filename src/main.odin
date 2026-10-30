package main

import "core:mem"
import "core:log"
import rl "vendor:raylib"
import "core:fmt"
import "core:math"

SCREEN_WIDTH :: 720
SCREEN_HEIGHT :: 720

GAME_NAME :: "Starship Scrapyard"

ship_part_size: [2]i32 = {}

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

    part_textures := PartTextures {
        .Hull = hull_texture,
        .Blaster = blaster_texture,
        .Thruster = thruster_texture,
        .Shield = shield_texture,
    }

    player_data := Player_Data {
        position = rl.Vector2 { f32(SCREEN_WIDTH / 2 - core_texture.width / 2), f32(SCREEN_HEIGHT - 50 - core_texture.height) },
        texture = core_texture,
        horizontal_speed = 200,
        vertical_speed = 100,
    }

    append(&player_data.parts[PartId.Hull], PartData { position = { 0, -1 }, id = .Hull } )
//    append(&player_data.parts[PartId.Hull], PartData { position = { 1, -1 }, id = .Hull } )
//    append(&player_data.parts[PartId.Hull], PartData { position = { -1, -1 }, id = .Hull } )
    append(&player_data.parts[PartId.Hull], PartData { position = { 0, -2 }, id = .Hull } )

    append(&player_data.parts[PartId.Thruster], PartData { position = { 1, 0 }, id = .Thruster})
    append(&player_data.parts[PartId.Thruster], PartData { position = { -1, 0 }, id = .Thruster})

//    append(&player_data.parts[PartId.Blaster], PartData { position = { 2, -1 }, id = .Blaster})
//    append(&player_data.parts[PartId.Blaster], PartData { position = { -2, -1 }, id = .Blaster})

    append(&player_data.parts[PartId.Shield], PartData { position = { 0, -3 }, id = .Shield } )
//    append(&player_data.parts[PartId.Shield], PartData { position = { 1, -2 }, id = .Shield } )
//    append(&player_data.parts[PartId.Shield], PartData { position = { -1, -2 }, id = .Shield } )

    debris_manager := Debris_Manager {}
    generate_random_debris(&debris_manager)

    rl.SetTargetFPS(60)

    frame_counter := 0

    for !rl.WindowShouldClose() {

        frame_counter += 1

        {
            // Update game logic

            // Handle inputs
            input_vector := rl.Vector2 { 0, 0 }
            if rl.IsKeyDown(rl.KeyboardKey.A) {
                input_vector.x -= 1
            }

            if rl.IsKeyDown(rl.KeyboardKey.D) {
                input_vector.x += 1
            }

            player_data.position += rl.Vector2 { input_vector.x *  player_data.horizontal_speed * rl.GetFrameTime(), 0 }

            player_bounds := get_player_bounds(&player_data)

            // Update any active debris -- Loop in reverse so we can remove with a swap
            #reverse for &debris, index in debris_manager.active_debris[0:debris_manager.debris_count] {
               debris.position += rl.Vector2 { 0, player_data.vertical_speed * rl.GetFrameTime() }
                bounds := get_debris_bounds(&debris)

                if (bounds.y > SCREEN_HEIGHT) {
                    sliced_debris := debris_manager.active_debris[0:]
                    array_swap_back(&sliced_debris, index, int(debris_manager.debris_count - 1))
                    debris_manager.debris_count -= 1
                    generate_random_debris(&debris_manager)
                } else {
                    contacts := get_part_contacts(&player_data, &debris)

                    running_slide_adjustment: f32 = 0
                    should_weld := false
                    for contact, index in contacts[:debris.part_count] {
                        if contact.do_weld {
                            should_weld = true
                            weld_debris_to_player(&player_data, &debris, contact.player_relative_location)

                            sliced_debris := debris_manager.active_debris[0:]
                            array_swap_back(&sliced_debris, index, int(debris_manager.debris_count - 1))
                            debris_manager.debris_count -= 1
                            generate_random_debris(&debris_manager)
                            break
                        } else if contact.do_slide {
                            running_slide_adjustment = contact.slide_offset
                        }
                    }

                    if !should_weld {
                        debris.position.x += running_slide_adjustment
                    }

//                    if rl.CheckCollisionRecs(player_bounds, bounds) {
//                        should_weld, player_pos, debris_translation := does_collide_with_player(&player_data, &debris)
//                        if should_weld {
//                            weld_debris_to_player(&player_data, &debris, debris_translation)
//
//                            sliced_debris := debris_manager.active_debris[0:]
//                            array_swap_back(&sliced_debris, index, int(debris_manager.debris_count - 1))
//                            debris_manager.debris_count -= 1
//                            generate_random_debris(&debris_manager)
//                        }
//                    }
                }
            }
        }

        {
            // Render the world
            rl.BeginTextureMode(render_target)
            defer rl.EndTextureMode()

            rl.ClearBackground(rl.BLACK)

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
        }

        {
            // Render to screen

            rl.BeginDrawing()
            defer rl.EndDrawing()

            rl.ClearBackground(rl.RAYWHITE)

            rl.DrawTexturePro(
                render_target.texture,
                rl.Rectangle {
                    0, 0, f32(render_target.texture.width), -f32(render_target.texture.height),
                },
                rl.Rectangle {
                    0, 0, f32(render_target.texture.width), f32(render_target.texture.height),
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

