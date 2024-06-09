

SpritePathTables
{
    ; PATHS.BIN is loaded at $B000 in the game ram bank
    &uword num_paths = $B400
    const uword paths = $B402

    sub Init()
    {
        void diskio.load_raw(iso:"PATHS.BIN", $B400)
    }

    ; index, VH flips (0 - no flips, 1 - h flip, 2 - v flip, 3 both flips)
    ; 24 direction
    ubyte[] ship_rotation_table = [
        0, 0,
        1, 0,
        2, 0,
        3, 0,
        4, 0,
        5, 0,
        6, 0,
        5, 2,
        4, 2,
        3, 2,
        2, 2,
        1, 2,
        0, 2,
        1, 3,
        2, 3,
        3, 3,
        4, 3,
        5, 3,
        6, 3,
        5, 1,
        4, 1,
        3, 1,
        2, 1,
        1, 1 ]

    ; first number of pair is the ship in normal colors, the second number is the "lit up" colors 
    ubyte[] ship_sprite_offset = [
          1,  33,   ; boss green
         17,  33,   ; boss blue
         49,  65,   ; butterfly
         81,  97,   ; bee
          9,  25,   ; scorpion
         41,  57,   ; green ship
         73,  89,   ; galaxian
        105, 121,   ; dragonfly
        137, 153,   ; enterprise
        169, 185 ]  ; player ship

    sub GetSpriteOffset(ubyte shipIndex) -> ubyte
    {
        return ship_sprite_offset[shipIndex]
    }
    
    sub GetSpriteRotationInfo(ubyte shipIndex, ubyte direction) -> uword
    {
        return mkword(ship_sprite_offset[shipIndex] + ship_rotation_table[direction * 2], ship_rotation_table[(direction * 2) + 1]) 
    }

    ; fill up a "struct" with path data and ship sprite data
    ; the path data is the x and y offsets for this step in the path, and the rotation as a number from 0 to 23
    ; the ship sprite data gives the sprite index and flip bits
    sub GetPathEntry(ubyte pathIndex, ubyte pathEntry, ubyte shipIndex, uword destination)
    {
        if (pathIndex < num_paths)
        {
            uword @zp path = peekw(paths + (pathIndex * 2))
            uword @zp pathOffset = path + (pathEntry as uword * 5)
            @(destination) = pathOffset[0] as ubyte
            @(destination+1) = pathOffset[1] as ubyte
            @(destination+2) = pathOffset[2] as ubyte
            @(destination+3) = pathOffset[3] as ubyte
            @(destination+4) = pathOffset[4] as ubyte
            if (@(destination) == 1)
            {
                ubyte shipRotOffset = pathOffset[4] as ubyte << 1
                @(destination+5) = ship_rotation_table[shipRotOffset] + ship_sprite_offset[shipIndex]
                @(destination+6) = ship_rotation_table[shipRotOffset + 1]
            }
        }
    }
}
