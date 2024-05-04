
sprites
{
    ; sprites are loaded into VERA memory at $8000
    ; sprites are 16x16x4bpp, so 128 bytes per sprite
    const uword sprite_data_addr = $8000
    const uword sprite_size = 128

    sub Init()
    {
        ; load our sprites into VERA, the palette is loaded right into the palette registers at $fa00
        void diskio.vload_raw(iso:"GALSPRITES.PAL", 1, $fa00)
        void diskio.vload_raw(iso:"GALSPRITES.BIN", 0, sprite_data_addr)

        ; enable sprites
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01000000
    }

    ; widthHeight = (width << 2) | (height)
    ;  width and height are 0 to 3 for 0 = 8, 1 = 16, 2 = 32, 3 = 64.
    ; modeZDepthVHFlips = (mode << 4) | (zDepth << 2) | (vFlip << 1) | hFlip
    ;  mode is 0 = 4bpp and 1 = 8bpp
    ;  zDepth is 0 to 3, 0 = disabled, 1 = behind layer0, 2 = between layer0 and layer1, 3 = in front of layer1
    ;  vFlip and hFlip are 0 = not flipped, 1 = flipped
    ; collisionMaskPaletteOffset
    ;  paletteOffset lower 4 bits
    ;  collisionMask upper 4 bits
    sub setup(ubyte spriteNum, ubyte widthHeight, ubyte modeZDepthVHFlip, ubyte collisionMaskPaletteOffset)
    {
        uword offset = spriteNum as uword << 3
        ubyte temp1 = (widthHeight << 4) | (collisionMaskPaletteOffset & $0F)
        ubyte temp2 = (collisionMaskPaletteOffset & $F0) | (modeZDepthVHFlip & $0F)
        ubyte temp3 = ((modeZDepthVHFlip & $F0) << 3) | (cx16.vpeek(1, $fc01 + offset) & $7F)
        cx16.vpoke(1, $fc01 + offset, temp3)
        cx16.vpoke(1, $fc06 + offset, temp2)
        cx16.vpoke(1, $fc07 + offset, temp1)
    }
/*
    ; widthHeightPaletteOffset = (width << 6) | (height << 4) | paletteOffset
    ;  width and height are 2 bits each: 0 to 3 for 0 = 8, 1 = 16, 2 = 32, 3 = 64.
    ;  paletteOffset 4 bits
    ; collisionMaskZDepthVHFlips = (collisionMask << 4) | (zDepth << 2) | (vFlip << 1) | hFlip
    ;  collisionMask 4 bit mask
    ;  zDepth is 2 bits: 0 to 3, 0 = disabled, 1 = behind layer0, 2 = between layer0 and layer1, 3 = in front of layer1
    ;  vFlip and hFlip are 1 bit each: 0 = not flipped, 1 = flipped
    ; mode is 0 = 4bpp and 1 = 8bpp
    sub setup2(ubyte spriteNum, ubyte widthHeightPaletteOffset, ubyte collisionMaskZDepthVHFlip, ubyte mode)
    {

        uword offset = spriteNum as uword << 3
        cx16.vpoke_mask(1, $fc01 + offset, %01111111, ((mode & $01) << 7))
        cx16.vpoke(1, $fc06 + offset, collisionMaskZDepthVHFlip)
        cx16.vpoke(1, $fc07 + offset, widthHeightPaletteOffset)
    }
*/
    asmsub updateEx(ubyte VHFlips @X) clobbers (A, X)
    {
        %asm {{
            ; setup our address in vera with auto increment of 1
            stz  cx16.VERA_CTRL
            lda  #%00010001
            sta  cx16.VERA_ADDR_H
            lda  cx16.r0
            sta  cx16.VERA_ADDR_L
            lda  cx16.r0+1
            sta  cx16.VERA_ADDR_M

            ; write out sprite image address, we always use 4bit color, so mode bit is 0
            lda  cx16.r1
            sta  cx16.VERA_DATA0    
            lda  cx16.r1+1 
            sta  cx16.VERA_DATA0

            ; write out position
            lda  cx16.r2
            sta  cx16.VERA_DATA0
            lda  cx16.r2+1
            sta  cx16.VERA_DATA0
            lda  cx16.r3
            sta  cx16.VERA_DATA0
            lda  cx16.r3+1
            sta  cx16.VERA_DATA0

            ; write vh flips, retaining rest of register's value
            txa
            and  #%00000011
            ora  #%11111100
            sta  cx16.VERA_DATA0

            rts
        }}
    }
}
