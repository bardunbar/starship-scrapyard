package main

import "core:log"
import rl "vendor:raylib"
//import "core:fmt"

SCREEN_WIDTH :: 720
SCREEN_HEIGHT :: 720

GAME_NAME :: "Starship Scrapyard"

main :: proc() {
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
    ship_part_size := [2]i32 {ship_part_width, ship_part_height}

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
    }

    append(&player_data.parts[PartId.Hull], PartData { position = { 0, -1 }, id = .Hull } )
    append(&player_data.parts[PartId.Hull], PartData { position = { 1, -1 }, id = .Hull } )
    append(&player_data.parts[PartId.Hull], PartData { position = { -1, -1 }, id = .Hull } )
    append(&player_data.parts[PartId.Hull], PartData { position = { 0, -2 }, id = .Hull } )

    append(&player_data.parts[PartId.Thruster], PartData { position = { 1, 0 }, id = .Thruster})
    append(&player_data.parts[PartId.Thruster], PartData { position = { -1, 0 }, id = .Thruster})

    append(&player_data.parts[PartId.Blaster], PartData { position = { 2, -1 }, id = .Blaster})
    append(&player_data.parts[PartId.Blaster], PartData { position = { -2, -1 }, id = .Blaster})

    append(&player_data.parts[PartId.Shield], PartData { position = { 0, -3 }, id = .Shield } )
    append(&player_data.parts[PartId.Shield], PartData { position = { 1, -2 }, id = .Shield } )
    append(&player_data.parts[PartId.Shield], PartData { position = { -1, -2 }, id = .Shield } )

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

            for current_debris in debris_manager.active_debris[0:debris_manager.debris_count] {
                current_debris := current_debris

                for part  in current_debris.parts[0:current_debris.part_count] {
                    part_texture := part_textures[part.id]

                    debris_pos_int :[2]i32 = { i32(current_debris.position.x), i32(current_debris.position.y) }

                    part_position := debris_pos_int + (part.position * ship_part_size)
                    rl.DrawTexture(part_texture, part_position.x, part_position.y, rl.WHITE)
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

}

