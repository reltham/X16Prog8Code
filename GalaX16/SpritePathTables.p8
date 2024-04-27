

SpritePathTables
{
    ; this will all be in a data file that get's loaded into the game data ram bank
    ; command, command data, X offset, Y offset, rotation
    byte[] path1 = [
            1, 3, 10,   0,  7,
            1, 3,  9,   0,  7,
            1, 3,  9,   0,  7,
            1, 3,  9,   1,  7,
            1, 3,  9,   1,  8,
            1, 3,  9,   2,  8,
            1, 3,  9,   3,  8,
            1, 3,  8,   4,  9,
            1, 3,  7,   5, 10,
            1, 3,  5,   6, 10,
            1, 2,  4,   6, 11,
            1, 2,  2,   7, 12,
            1, 2,  1,   7, 12,
            1, 2,  1,   7, 12,
            1, 2,  0,   7, 12,
            1, 2,  0,   7, 12,
            1, 2,  0,   7, 12,
            1, 2,  0,   7, 12,
            1, 2,  0,   7, 12,
            1, 2,  0,   7, 12,
            1, 2,  1,   7, 12,
            1, 2,  2,   7, 11,
            1, 2,  3,   7, 11,
            1, 3,  5,   6, 10,
            1, 3,  6,   5,  9,
            1, 3,  7,   4,  9,
            1, 3,  8,   3,  8,
            1, 3,  9,   2,  8,
            1, 3,  9,   2,  7,
            1, 3,  9,   1,  7,
            1, 3,  9,   1,  7,
            1, 3,  9,   0,  7,
            1, 3,  9,   0,  7,
            0, 0,  0,   0,  0 ]

    byte[] path2 = [
            1, 1, -25,   0, 17,
            1, 1, -24,   0, 17,
            1, 1, -24,   0, 17,
            1, 1, -24,   1, 17,
            1, 1, -24,   3, 17,
            1, 1, -24,   5, 17,
            1, 1, -23,   7, 16,
            1, 1, -22,  11, 15,
            1, 1, -18,  16, 14,
            1, 1, -14,  20, 13,
            1, 1,  -8,  23, 12,
            1, 1,  -3,  24, 12,
            1, 1,   1,  24, 12,
            1, 1,   6,  24, 11,
            1, 1,  11,  22, 10,
            1, 1,  15,  19,  9,
            1, 1,  19,  15,  9,
            1, 1,  22,  10,  8,
            1, 1,  24,   5,  7,
            1, 1,  24,   1,  6,
            1, 1,  24,  -3,  6,
            1, 1,  23,  -8,  5,
            1, 1,  21, -13,  4,
            1, 1,  17, -17,  3,
            1, 1,  13, -20,  2,
            1, 1,   8, -23,  1,
            1, 1,   4, -24,  1,
            1, 1,  -1, -24, 23,
            1, 1,  -6, -24, 22,
            1, 1, -11, -22, 21,
            1, 1, -16, -18, 20,
            1, 1, -20, -14, 19,
            1, 1, -22,  -9, 19,
            1, 1, -24,  -6, 18,
            1, 1, -24,  -4, 18,
            1, 1, -24,  -2, 18,
            1, 1, -24,  -1, 18,
            1, 1, -24,   0, 18,
            1, 1, -25,   0, 18,
            0, 0,   0,   0,  0 ]

    byte[] path3 = [
            1, 30, 10,   0,  6,
            1,  1,  0,   0,  7,
            1,  1,  0,   0,  8,
            1,  1,  0,   0,  9,
            1,  1,  0,   0, 10,
            1,  1,  0,   0, 11,
            1, 30,  0,  10, 12,
            1,  1,  0,   0, 13,
            1,  1,  0,   0, 14,
            1,  1,  0,   0, 15,
            1,  1,  0,   0, 16,
            1,  1,  0,   0, 17,
            1, 30,-10,   0, 18,
            1,  1,  0,   0, 19,
            1,  1,  0,   0, 20,
            1,  1,  0,   0, 21,
            1,  1,  0,   0, 22,
            1,  1,  0,   0, 23,
            1, 30,  0, -10,  0,
            1,  1,  0,   0,  1,
            1,  1,  0,   0,  2,
            1,  1,  0,   0,  3,
            1,  1,  0,   0,  4,
            1,  1,  0,   0,  5,
            0,  0,  0,   0,  0 ]

    uword num_paths = 3
    uword[] paths = [ &path2, &path3, &path1 ]

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

        ; check to see if we hit the end of the path
        sub CheckEnd(ubyte pathIndex, ubyte pathEntry) -> bool
        {
            if (pathIndex < num_paths)
            {
                uword path = paths[pathIndex]
                ubyte pathOffset = pathEntry * 5
                if (path[pathOffset] == 0 and path[pathOffset+1] == 0)
                {
                    return true
                }
            }
            return false
        }

        ; fill up a "struct" with path data and ship sprite data
        ; the path data is the x and y offsets for this step in the path, and the rotation as a number from 0 to 23
        ; the ship sprite data gives the sprite index and flip bits
        sub GetPathEntry(ubyte pathIndex, ubyte pathEntry, ubyte shipIndex, uword Destination)
        {
            if (pathIndex < num_paths)
            {
                uword path = paths[pathIndex]
                ubyte pathOffset = pathEntry * 5
                if (path[pathOffset] == 1)
                {
                    @(Destination) = path[pathOffset + 2] as ubyte
                    @(Destination+1) = path[pathOffset + 3] as ubyte
                    @(Destination+2) = path[pathOffset + 1] as ubyte
                    ubyte shipRotOffset = path[pathOffset + 4] as ubyte << 1
                    @(Destination+3) = shipRotationTable[shipRotOffset] + shipSpriteOffset[shipIndex]
                    @(Destination+4) = shipRotationTable[shipRotOffset + 1]
                }
            }
        }
}
