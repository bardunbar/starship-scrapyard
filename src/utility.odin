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