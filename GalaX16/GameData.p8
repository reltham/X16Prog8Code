; game data for GalaX16

GameData
{
    ; game ram bank layout
    ;
    ; $A000 - $AFFF -> 4K - 128 entities, 32 bytes each
    ; $B000 - $B3FF -> 1K - 128 sprites, 8 bytes each
    ; $B400 - $BFFF -> 3K for paths
    ;
    const ubyte ram_bank = 2

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
        1, 1, 1, 1, 1, ; explosion 1
        1, 1, 1,       ; rocks
        1, 1, 1, 1, 1, ; explosion 2
        1, 1, 1,       ; yellow space station
        2,             ; player ship
        2,             ; 4 spike thing
        3,             ; player missle
        3,             ; enemy missle
        4, 4           ; blue space station
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
        2, ; red1
        2, ; red2
        3, ; green1
        3, ; green2
        4, ; blue1
        4  ; blue2
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

    sub Begin()
    {
        cx16.rambank(ram_bank)
    }

    sub End()
    {
        cx16.rambank(0)
    }

}