

SpritePathTables
{
    ; PATHS.BIN is loaded at $A800 in the game ram bank
    &uword num_paths = $B000
    const uword paths = $B002

    sub Init(ubyte ramBank)
    {
        cx16.rambank(ramBank)
        void diskio.load_raw(iso:"PATHS.BIN", $B000)
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
            ubyte pathOffset = pathEntry * 5
            @(destination) = path[pathOffset] as ubyte
            pathOffset++
            @(destination+1) = path[pathOffset] as ubyte
            pathOffset++
            @(destination+2) = path[pathOffset] as ubyte
            pathOffset++
            @(destination+3) = path[pathOffset] as ubyte
            pathOffset++
            @(destination+4) = path[pathOffset] as ubyte
            if (@(destination) == 1)
            {
                ubyte shipRotOffset = path[pathOffset] as ubyte << 1
                @(destination+5) = ship_rotation_table[shipRotOffset] + ship_sprite_offset[shipIndex]
                @(destination+6) = ship_rotation_table[shipRotOffset + 1]
            }
        }
    }
}
