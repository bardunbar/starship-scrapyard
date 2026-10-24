package main

import rl "vendor:raylib"

Player_Data :: struct {
    position: rl.Vector2,
    texture: rl.Texture,
    horizontal_speed: f32,
    vertical_speed: f32,
    parts: [PartId][dynamic]PartData,
}