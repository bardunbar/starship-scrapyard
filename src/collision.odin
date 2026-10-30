package main

import "core:math"
import rl "vendor:raylib"

Corners :: enum { TL, TR, BL, BR }

ContactData :: struct {
    do_slide: bool,
    do_weld: bool,
    slide_offset: f32,
    player_relative_location: [2]i32,
}

get_part_contacts :: proc(player_data: ^Player_Data, debris: ^Debris_Data) -> [len(debris.parts)]ContactData {

    // Check to see if this debris contacts or slides against the player

    debris_delta_position := debris.position - player_data.position
    debris_relative_position := debris_delta_position / to_vector(ship_part_size)

    // This is the location that the debris is closest to
    debris_relative_location: [2]i32 = {
        i32(math.round(debris_relative_position.x)),
        i32(math.round(debris_relative_position.y)),
    }

    // This is the location that the debris origin is inside of
    debris_actual_location: [2]i32 = {
        i32(math.floor(debris_relative_position.x)),
        i32(math.floor(debris_relative_position.y)),
    }

    contacts := [len(debris.parts)]ContactData {}

    // For each part in the debris
    for part, part_index in debris.parts[:debris.part_count] {
        // Calculate its effective player local position
        player_local_location := debris_actual_location + part.position
        cells_to_check :[Corners][2]i32 = {
            .TL = player_local_location,
            .TR = player_local_location + { 1, 0 },
            .BL = player_local_location + { 0, 1 },
            .BR = player_local_location + { 1, 1 },
        }

        hits: [Corners]rl.Rectangle = {}
        for parts, part_id in player_data.parts {
            for part_data in parts {
                for cell, corner in cells_to_check {
                    if part_data.position == cell {
                        // Get the collision rect for this collision
                        player_part_rect := part_rect(player_data.position, cell)
                        debris_part_rect := part_rect(debris.position, part.position)
                        overlap := rl.GetCollisionRec(player_part_rect, debris_part_rect)
                        overlap.x, overlap.y = 1, 1 // Mark the collision as a hit, we only care about w/h
                        hits[corner] = overlap
                    }
                }
            }
        }

        do_slide := false
        do_weld := false
        slide_offset: f32 = 0

        // At this point we have between 0 and (hopefully not) 4 hits. In practice the max we should be able to hit is 3
        // Depending on the coordinates and width of the hit we should be able to determine if the hit is a slide or a weld.
        for overlap, corner in hits {
            if overlap.x == 1 {
                switch corner {
                case .TL:
                    // Should never weld, always slide
                    do_slide = true
                    slide_offset = overlap.width
                case .TR:
                    // Should never weld, always slide
                    do_slide = true
                    slide_offset = -overlap.width
                case .BL:
                    // Slide or weld depending on overlap width
                    if overlap.width < f32(ship_part_size.x) * 0.2 {
                        do_slide = true
                        slide_offset = overlap.width
                    } else {
                        do_weld = true
                    }
                case .BR:
                    // Slide or weld depending on overlap width
                    if overlap.width < f32(ship_part_size.x) * 0.2 {
                        do_slide = true
                        slide_offset = -overlap.width
                    } else {
                        do_weld = true
                    }
                }
            }
        }

        contacts[part_index] = {
            do_slide = do_slide,
            do_weld = do_weld,
            slide_offset = slide_offset,
            player_relative_location = debris_relative_location,
        }
    }

    return contacts
}