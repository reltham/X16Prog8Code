; game data for GalaX16

GameData
{
    const ubyte enemy_bullet = 19
    const ubyte player_bullet = 18
    const ubyte player_ship = 16
    const ubyte enemy_explosion_start = 0
    const ubyte player_explosion_start = 8
    
    ubyte[] sprite_indices = [
         0,  1,  2,  3,  4, ; explosion 1
         5,  6,  7,         ; rocks
         8,  9, 10, 11, 12, ; explosion 2
        13, 14, 15,         ; yellow space station
        23,                 ; player ship
        31,                 ; 4 spike thing
        39,                 ; player missle
        47,                 ; enemy missle
        55, 63              ; blue space station
    ]

    ubyte[] sprite_palettes = [
        8, 8, 8, 8, 8, ; explosion 1
        8, 8, 8,       ; rocks
        8, 8, 8, 8, 8, ; explosion 2
        8, 8, 8,       ; yellow space station
        9,             ; player ship
        9,             ; 4 spike thing
        10,            ; player missle
        10,            ; enemy missle
        11, 11         ; blue space station
    ]

    ubyte[6] scoreValues = [
        50, ; red1
        30, ; red2
        25, ; green1
        20, ; green2
        16, ; blue1
         8  ; blue2
    ]

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

    ubyte[] ship_sprite_offset = [
        16, ; red1
        24, ; red2
        32, ; green1
        40, ; green2
        48, ; blue1
        56  ; blue2
    ]
    ubyte[] ship_sprite_palettes = [
         9, ; red1
         9, ; red2
        10, ; green1
        10, ; green2
        11, ; blue1
        11  ; blue2
    ]

    sub GetShipSpriteOffset(ubyte shipIndex) -> ubyte
    {
        return ship_sprite_offset[shipIndex]
    }
    sub GetShipSpritePalette(ubyte shipIndex) -> ubyte
    {
        return ship_sprite_palettes[shipIndex]
    }

    sub GetSpriteRotationInfo(ubyte shipIndex, ubyte direction) -> uword
    {
        return mkword(ship_sprite_offset[shipIndex] + ship_rotation_table[direction * 2], ship_rotation_table[(direction * 2) + 1]) 
    }
}