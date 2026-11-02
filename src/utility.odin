package main

import rl "vendor:raylib"

array_swap_back :: proc (array: ^[]$T, index_to_remove, index_to_swap: int) {
    if (index_to_remove <= index_to_swap && index_to_swap < len(array)) {
        array[index_to_remove] = array[index_to_swap]
    }
}

to_vector :: proc (source: [2]i32) -> rl.Vector2 {
    return { f32(source.x), f32(source.y) }
}

part_position :: proc (source: [2]i32) -> [2]i32 {
    return source * ship_part_size
}

part_rect :: proc(origin: rl.Vector2, location: [2]i32) -> rl.Rectangle {
    location := part_position(location)
    position := to_vector(location) + origin
    return rl.Rectangle {
        position.x,
        position.y,
        f32(ship_part_size.x),
        f32(ship_part_size.y),
    }
}

get_capped_frame_time :: proc() -> f32 {
    return min(rl.GetFrameTime(), 0.1)
}

get_screen_bounds :: proc(camera: rl.Camera2D) -> rl.Rectangle {
    screen_tl := rl.GetScreenToWorld2D({}, camera)
    screen_br := rl.GetScreenToWorld2D({SCREEN_WIDTH, SCREEN_HEIGHT}, camera)

    return rl.Rectangle {
        x = screen_tl.x,
        y = screen_tl.y,
        width = screen_br.x - screen_tl.x,
        height = screen_br.y - screen_tl.y,
    }
}