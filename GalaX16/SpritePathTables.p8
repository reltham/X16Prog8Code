

SpritePathTables
{
    ; PATHS.BIN is loaded at $A800 in the game ram bank
    &uword num_paths = $A800
    const uword paths = $A802

    sub Init(ubyte ram_bank)
    {
        cx16.rambank(ram_bank)
        void diskio.load_raw(iso:"PATHS.BIN", $A800)
/* debug stuff
        txt.nl()
        txt.print(iso:"NUM PATHS ")
        txt.print_uw(num_paths)
        txt.nl()
        txt.print(iso:"PATH ADDR ")
        uword path = peekw(paths)
        txt.print_uw(path)
        txt.nl()
        byte k = 0
        for k in 0 to 5
        {
            txt.print_ub(path[k])
            txt.print(iso:" ")
        }
        txt.nl()
*/
    }

    ; index, VH flips (0 - no flips, 1 - h flip, 2 - v flip, 3 both flips)
    ; 24 direction
    ubyte[] shipRotationTable = [
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
    ubyte[] shipSpriteOffset = [  1,  33,   ; boss green
                                 17,  33,   ; boss blue
                                 49,  65,   ; butterfly
                                 81,  97,   ; bee
                                  9,  25,   ; scorpion
                                 41,  57,   ; green ship
                                 73,  89,   ; galaxian
                                105, 121,   ; dragonfly
                                137, 153,   ; enterprise
                                169, 185 ]  ; player ship

    ; fill up a "struct" with path data and ship sprite data
    ; the path data is the x and y offsets for this step in the path, and the rotation as a number from 0 to 23
    ; the ship sprite data gives the sprite index and flip bits
    sub GetPathEntry(ubyte pathIndex, ubyte pathEntry, ubyte shipIndex, uword Destination)
    {
        if (pathIndex < num_paths)
        {
            uword @zp path = peekw(paths + (pathIndex * 2))
            ubyte pathOffset = pathEntry * 5
            @(Destination) = path[pathOffset] as ubyte
            pathOffset++
            @(Destination+1) = path[pathOffset] as ubyte
            pathOffset++
            @(Destination+2) = path[pathOffset] as ubyte
            pathOffset++
            @(Destination+3) = path[pathOffset] as ubyte
            pathOffset++
            @(Destination+4) = path[pathOffset] as ubyte
            if (@(Destination) == 1)
            {
                ubyte shipRotOffset = path[pathOffset] as ubyte << 1
                @(Destination+5) = shipRotationTable[shipRotOffset] + shipSpriteOffset[shipIndex]
                @(Destination+6) = shipRotationTable[shipRotOffset + 1]
            }
        }
    }
}
