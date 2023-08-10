
sprites
{

    ; widthHeight = (width << 2) | (height)
    ;  width and height are o to 3 for 0 = 8, 1 = 16, 2 = 32, 3 = 64.
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

    ; set sprites H and V flips
    sub flips(ubyte spriteNum, ubyte VHFlips)
    {

        uword offset = mkword(0,spriteNum) << 3
        cx16.vpoke_mask(1, $fc06 + offset, %11111100, (VHFlips & $03))
    }

    asmsub positionEx(ubyte bank @A, uword address @R0, uword xPos @R1, uword yPos @R2) clobbers(A) {
        %asm {{
            stz  cx16.VERA_CTRL
            and  #1
            ora  #%10000
            sta  cx16.VERA_ADDR_H
            lda  cx16.r0
            sta  cx16.VERA_ADDR_L
            lda  cx16.r0+1
            sta  cx16.VERA_ADDR_M
            lda  cx16.r1
            sta  cx16.VERA_DATA0
            lda  cx16.r1+1
            sta  cx16.VERA_DATA0
            lda  cx16.r2
            sta  cx16.VERA_DATA0
            lda  cx16.r2+1
            sta  cx16.VERA_DATA0
            rts
        }}
    }

    ; xPos and yPox only use the lower 10 bits, the upper bits are ignored
    sub position(ubyte spriteNum, uword xPos, uword yPos)
    {

        uword offset = spriteNum as uword << 3
        positionEx(1, $fc02 + offset, xPos, yPos)
    }

    asmsub set_addressEx(ubyte bank @A, uword address @R0, uword sprite_address @R1) clobbers (A) {
        %asm {{
            stz  cx16.VERA_CTRL
            and  #1
            sta  cx16.VERA_ADDR_H
            lda  cx16.r0
            sta  cx16.VERA_ADDR_L
            lda  cx16.r0+1
            sta  cx16.VERA_ADDR_M
            lda  cx16.r1
            sta  cx16.VERA_DATA0
            inc  cx16.VERA_ADDR_L
            lda  #%10000000
            and  cx16.VERA_DATA0
            ora  cx16.r1+1
            sta  cx16.VERA_DATA0
            rts
        }}
    }

    ; sprites have to be 32 byte aligned, so the lower 5 bits of spriteAddress are ignored
    sub set_address(ubyte spriteNum, ubyte spriteBank, uword spriteAddress)
    {

        uword offset = spriteNum as uword << 3
        uword addr = (spriteAddress >> 5) | ((spriteBank as uword & 1) << 11)
        set_addressEx(1, $fc00 + offset, addr)
    }
}
