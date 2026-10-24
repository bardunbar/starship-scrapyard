package main

import rl "vendor:raylib"

PartId :: enum {Hull, Blaster, Thruster, Shield}

PartData :: struct {
    position: [2]i32,
    id: PartId,
}

PartTextures :: [PartId] rl.Texture