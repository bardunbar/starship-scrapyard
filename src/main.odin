package main

import "core:log"
import rl "vendor:raylib"

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

    rl.SetTargetFPS(60)

    frame_counter := 0

    for !rl.WindowShouldClose() {

        frame_counter += 1

        {
            rl.BeginTextureMode(render_target)
            defer rl.EndTextureMode()

            rl.ClearBackground(rl.RAYWHITE)

            rl.DrawRectangle(70, 90, 200, 200, rl.BLACK)
            rl.DrawRectangle(70 + 16, 90 + 16, 200 - 32, 200 - 32, rl.RAYWHITE)
            rl.DrawText("raylib", 70 + 200 - rl.MeasureText("raylib", 40) - 32, 90 + 200 - 40 - 24, 40, rl.BLACK)

            rl.DrawText("6.x", 290, 90 - 26, 280, rl.BLACK)
            rl.DrawText("GAMEJAM", 70, 90 + 210, 120, rl.MAROON)

            if (frame_counter / 20) % 2 == 0 {
                rl.DrawText("are you ready?", 160, 500, 50, rl.BLACK)
            }

            rl.DrawRectangleLinesEx(rl.Rectangle { 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT}, 16, rl.BLACK)
        }

        {
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
                rl.Vector2 { 0, 0},
                0.0,
                rl.WHITE,
            )
        }
    }

}

