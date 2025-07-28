
SpritePathTables
{
    ; PATHS.BIN is loaded at $7000 in the game ram bank
    &uword num_paths = $7000
    const uword paths = $7002

    sub Init()
    {
        void diskio.load_raw(iso:"PATHS.BIN", $7000)
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
                @(destination+5) = GameData.ship_rotation_table[shipRotOffset] + GameData.ship_sprite_offset[shipIndex]
                @(destination+6) = GameData.ship_rotation_table[shipRotOffset + 1]
            }
        }
    }
}
