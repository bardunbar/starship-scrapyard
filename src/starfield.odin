package main

import "core:math/rand"
import rl "vendor:raylib"

starfield_texture: rl.RenderTexture2D = {}

StarfieldLayer :: struct {
    color: rl.Color,

}

Starfield :: struct {

}

initialize_starfields :: proc() {
    star_texture := rl.LoadTexture("assets/kenny/particle pack/star_01.png")
    defer rl.UnloadTexture(star_texture)

    starfield_texture = rl.LoadRenderTexture(i32(screen_rect.width), i32(screen_rect.height))

    {
        rl.BeginTextureMode(starfield_texture)
        defer rl.EndTextureMode()

        for i in 0..<100 {
            rl.DrawTexture(star_texture, rand.int32_range(0, i32(screen_rect.width)), rand.int32_range(0, i32(screen_rect.height)), rl.WHITE)
        }
    }
}


teardown_starfields :: proc() {
    rl.UnloadRenderTexture(starfield_texture)
}

render_starfield_layer :: proc() {
    rl.DrawTexture(starfield_texture.texture, i32(screen_rect.x), i32(screen_rect.y), rl.WHITE)
}