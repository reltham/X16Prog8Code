

SpritePathTables
{

    ; X offset, Y offset, sprite frame index
    byte[] path = [
             10,   0,  7,
              9,   0,  7,
              9,   0,  7,
              9,   1,  7,
              9,   1,  8,
              9,   2,  8,
              9,   3,  8,
              8,   4,  9,
              7,   5, 10,
              5,   6, 10,
              4,   6, 11,
              2,   7, 12,
              1,   7, 12,
              1,   7, 12,
              0,   7, 12,
              0,   7, 12,
              0,   7, 12,
              0,   7, 12,
              0,   7, 12,
              0,   7, 12,
              1,   7, 12,
              2,   7, 11,
              3,   7, 11,
              5,   6, 10,
              6,   5,  9,
              7,   4,  9,
              8,   3,  8,
              9,   2,  8,
              9,   2,  7,
              9,   1,  7,
              9,   1,  7,
              9,   0,  7,
              9,   0,  7,
              0,   0,  0 ]

    byte[] path2 = [
            -25,   0, 17,
            -24,   0, 17,
            -24,   0, 17,
            -24,   1, 17,
            -24,   3, 17,
            -24,   5, 17,
            -23,   7, 16,
            -22,  11, 15,
            -18,  16, 14,
            -14,  20, 13,
             -8,  23, 12,
             -3,  24, 12,
              1,  24, 12,
              6,  24, 11,
             11,  22, 10,
             15,  19,  9,
             19,  15,  9,
             22,  10,  8,
             24,   5,  7,
             24,   1,  6,
             24,  -3,  6,
             23,  -8,  5,
             21, -13,  4,
             17, -17,  3,
             13, -20,  2,
              8, -23,  1,
              4, -24,  1,
             -1, -24, 23,
             -6, -24, 22,
            -11, -22, 21,
            -16, -18, 20,
            -20, -14, 19,
            -22,  -9, 19,
            -24,  -6, 18,
            -24,  -4, 18,
            -24,  -2, 18,
            -24,  -1, 18,
            -24,   0, 18,
            -25,   0, 18,
              0,   0,  0 ]

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

        ubyte[] shipSpriteOffset = [ 1, 33, 9, 25, 41, 57, 49, 65, 73, 89, 81, 97, 105,
                                    121,
                                    137,
                                    153,
                                    169,
                                    185,
                                    17]

        sub CheckEnd(ubyte pathIndex, ubyte pathEntry) -> bool
        {
            ubyte pathOffset = pathEntry * 3
            when pathIndex {
                0 -> if (path[pathOffset] == 0 and path[pathOffset+2] == 0) return true
                1 -> if (path2[pathOffset] == 0 and path2[pathOffset+2] == 0) return true
            }
            return false
        }

        sub GetPathEntry(ubyte pathIndex, ubyte pathEntry, ubyte shipIndex, uword Destination)
        {
            ubyte pathOffset = pathEntry * 3
            when pathIndex {
             0 -> {
                @(Destination) = path[pathOffset] as ubyte
                @(Destination+1) = path[pathOffset + 1] as ubyte
                @(Destination+2) = path[pathOffset + 2] as ubyte
                ubyte shipRotOffset = path[pathOffset + 2] as ubyte << 1
                @(Destination+3) = shipRotationTable[shipRotOffset] + shipSpriteOffset[shipIndex]
                @(Destination+4) = shipRotationTable[shipRotOffset + 1]
                }
             1 -> {
                @(Destination) = path2[pathOffset] as ubyte
                @(Destination+1) = path2[pathOffset + 1] as ubyte
                @(Destination+2) = path2[pathOffset + 2] as ubyte
                ubyte shipRotOffset2 = path2[pathOffset + 2] as ubyte << 1
                @(Destination+3) = shipRotationTable[shipRotOffset2] + shipSpriteOffset[shipIndex]
                @(Destination+4) = shipRotationTable[shipRotOffset2 + 1]
                }
            }
        }
}
