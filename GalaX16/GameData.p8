; game data for GalaX16

; full formation = 40 enemies:
; 4 boss galalas centered at top
; 16 red butterflies in 2 rows of 8
; 20 blue bees in 2 rows of 10
;
; other sprites:
; player bullets: 8
; enemy bullets: 12
; player ships: 1-9
; level flags: 1-11

GameData
{
    ubyte[] info_icons = [  8,    ; 1
                           24,   ; 5
                           48,   ; 10
                           64,   ; 20
                           80,   ; 30
                           96,   ; 50
                           112 ]  ; player ships remaining

    ubyte[] scoring_sprites = [ 162,  ; 150
                                163,  ; 400
                                164,  ; 800
                                165,  ; 1000
                                166,  ; 1500
                                167,  ; 1600
                                149,  ; 2000 (2 sprites)
                                151 ] ; 3000 (2 sprites)

    ubyte[] enemy_explosion = [ 146, 
                                147,
                                148,
                                133,  ; 4 sprites
                                117 ] ; 4 sprites

    ubyte[] player_explosion = [ 240,  ; these are all 4 sprites each
                                 244,
                                 248,
                                 252 ] 

    const ubyte enemy_bullet  = 168
    const ubyte player_bullet = 179

    ; only the first 4 ships have formation anims
    ubyte[] ship_sprite_formation_anims = [  0,  1,
                                            16, 17,
                                            48, 49,
                                            80, 81 ]

    ubyte[] four_sprite_offsets = [  0,  0,
                                    16,  0,
                                     0, 16,
                                    16, 16 ]
}