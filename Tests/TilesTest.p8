%import textio
%import diskio
%zeropage basicsafe

main {
    sub start() {

        txt.chrout(19)      ; HOME
        txt.print("\ntiles test\n\n")

        ; load tile maps and tileset into VERA
        void diskio.vload("utopiamap.bin", 0, $0000)
        void diskio.vload("tileset.bin", 0, $2000)

        ; enable sprites, layer0, and layer1
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01110000

        cx16.VERA_L0_CONFIG = %00010011
        cx16.VERA_L0_MAPBASE = 0
        cx16.VERA_L0_TILEBASE = msb($1000) | %00000011

        cx16.VERA_L1_CONFIG = %00010011
        cx16.VERA_L1_MAPBASE = msb($0800)
        cx16.VERA_L1_TILEBASE = msb($1000) | %00000011

        ubyte i = 0
        repeat {
            i++
            if (i > 7) i = 0
            sys.wait(mkword(0,1))
        }
    }
}

;    &ubyte  VERA_L0_CONFIG      = VERA_BASE + $000D
;    &ubyte  VERA_L0_MAPBASE     = VERA_BASE + $000E
;    &ubyte  VERA_L0_TILEBASE    = VERA_BASE + $000F
;    &ubyte  VERA_L0_HSCROLL_L   = VERA_BASE + $0010
;    &ubyte  VERA_L0_HSCROLL_H   = VERA_BASE + $0011
;    &ubyte  VERA_L0_VSCROLL_L   = VERA_BASE + $0012
;    &ubyte  VERA_L0_VSCROLL_H   = VERA_BASE + $0013
;    &ubyte  VERA_L1_CONFIG      = VERA_BASE + $0014
;    &ubyte  VERA_L1_MAPBASE     = VERA_BASE + $0015
;    &ubyte  VERA_L1_TILEBASE    = VERA_BASE + $0016
;    &ubyte  VERA_L1_HSCROLL_L   = VERA_BASE + $0017
;    &ubyte  VERA_L1_HSCROLL_H   = VERA_BASE + $0018
;    &ubyte  VERA_L1_VSCROLL_L   = VERA_BASE + $0019
;    &ubyte  VERA_L1_VSCROLL_H   = VERA_BASE + $001A
