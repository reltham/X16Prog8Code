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

    ;const ubyte enemy_bullet = 12
    ;const ubyte player_bullet = 13
    ;const ubyte enemy_explosion_start = 14
/*
    ubyte[] sprite_indices = [  8,    ; 1
                                24,   ; 5
                                40,   ; 10
                                56,   ; 20
                                72,   ; 30
                                88,   ; 50
                                104,  ; player ships remaining
                                162,  ; 150
                                163,  ; 400
                                ;164,  ; 800
                                165,  ; 1000
                                166,  ; 1500
                                167,  ; 1600
                                ;149,  ; 2000 (2 sprites)
                                ;151,  ; 3000 (2 sprites)
                                168,  ; enemy bullet
                                179,  ; player bullet
                                146,  ; enemy explosion 
                                147,
                                148
    ]
    */
    ubyte[] sprite_indices_4 = [
                                133,  ; enemy eplosion
                                117,  
                                240,  ; player explosion
                                244,
                                248,
                                252
    ]
    
    sub GetSpriteIndicesLen() -> ubyte
    {
        return len(sprite_indices)
    }

    ubyte[] four_sprite_offsets = [  0,  0,
                                    16,  0,
                                     0, 16,
                                    16, 16 ]

    ubyte[6] scoreValues2 = [
        10, ; red1
        20, ; red2
        30, ; green1
        20, ; green2
        16, ; blue1
        8   ; blue2
    ]

    ubyte[9] scoreValues = [
        10, ; boss green
        40, ; boss blue
        16, ; butterfly
        8,  ; bee
        10, ; scorpion
        20, ; green ship
        30, ; galaxian
        40, ; dragonfly
        50  ; enterprise
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
/*
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
*/
    ; only the first 4 ships have formation anims
    ubyte[] ship_sprite_formation_anims = [  0,  1,
                                            16, 17,
                                            48, 49,
                                            80, 81 ]


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