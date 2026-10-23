package main

import rl "vendor:raylib"

PartId :: enum {Hull, Blaster, Thruster, Shield}

PartData :: struct {
    position: [2]i32,
}

PartTextures :: [PartId] rl.Texture