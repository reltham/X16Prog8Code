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
    byte[] infoIcons = [ 8,    ; 1
                         24,   ; 5
                         32,   ; 10
                         48,   ; 20
                         56,   ; 30
                         64,   ; 50
                         72 ]  ; player ship

    byte[] scoringSprites = [ 162,  ; 150
                              163,  ; 400
                              164,  ; 800
                              165,  ; 1000
                              166,  ; 1500
                              167,  ; 1600
                              150,  ; 2000 (2 sprites)
                              152 ] ; 3000 (2 sprites)
}