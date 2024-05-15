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
}