package main

import "core:math/rand"
import rl "vendor:raylib"

starfield: Starfield = {}

StarfieldLayer :: struct {
    color: rl.Color,
    fields: [2]rl.RenderTexture2D,
    active_layer: i32,
    position: f32,
    speed: f32,
    star_count: i32,
}

Starfield :: struct {
    layers: [3]StarfieldLayer,
}

initialize_starfields :: proc() {
    star_texture := rl.LoadTexture("assets/kenny/particle pack/star_01.png")
    defer rl.UnloadTexture(star_texture)

    starfield.layers[0] = {
        color = rl.DARKGRAY,
        speed = 6,
        star_count = 100,
    }

    starfield.layers[1] = {
        color = rl.GRAY,
        speed = 20,
        star_count = 50,
    }

    starfield.layers[2] = {
        color = rl.WHITE,
        speed = 50,
        star_count = 10,
    }

    for &layer in starfield.layers {
        layer.fields[0] = rl.LoadRenderTexture(i32(screen_rect.width), i32(screen_rect.height))
        layer.fields[1] = rl.LoadRenderTexture(i32(screen_rect.width), i32(screen_rect.height))

        {
            rl.BeginTextureMode(layer.fields[0])
            defer rl.EndTextureMode()

            for i in 0..<layer.star_count {
                rl.DrawTexture(star_texture, rand.int32_range(0, i32(screen_rect.width)), rand.int32_range(0, i32(screen_rect.height) - star_texture.height), rl.WHITE)
            }
        }

        {
            rl.BeginTextureMode(layer.fields[1])
            defer rl.EndTextureMode()

            for i in 0..<layer.star_count {
                rl.DrawTexture(star_texture, rand.int32_range(0, i32(screen_rect.width)), rand.int32_range(0, i32(screen_rect.height) - star_texture.height), rl.WHITE)
            }
        }
    }
}


teardown_starfields :: proc() {
    for &layer in starfield.layers {
        rl.UnloadRenderTexture(layer.fields[0])
        rl.UnloadRenderTexture(layer.fields[1])
    }
}

update_starfields :: proc() {
    for &layer in starfield.layers {
        layer.position += layer.speed * get_capped_frame_time()
        if layer.position >= screen_rect.y + screen_rect.height {
            layer.active_layer = (layer.active_layer + 1) % 2
            layer.position -= f32(layer.fields[layer.active_layer].texture.height)
        }
    }
}

render_starfield_layer :: proc() {
    for layer in starfield.layers {
        active_texture := layer.fields[layer.active_layer]
        other_texture := layer.fields[(layer.active_layer + 1) % 2]

        rl.DrawTexture(active_texture.texture, i32(screen_rect.x), i32(screen_rect.y + layer.position), layer.color)
        rl.DrawTexture(other_texture.texture, i32(screen_rect.x), i32(screen_rect.y + layer.position) - other_texture.texture.height, layer.color)
    }
}