%import textio
%import diskio
%import math
%import syslib
%zeropage basicsafe

main $0830 {

zsmkit_lib:
    ; this has to be the first statement to make sure it loads at the specified module address $0830
    %asmbinary "zsmkit-0830.bin"

    romsub $0830 = init_engine(ubyte bank @A) clobbers(A, X, Y)
    romsub $0833 = zsm_tick() clobbers(A, X, Y)

    romsub $0836 = zsm_play(ubyte prio @X) clobbers(A, X, Y)
    romsub $0839 = zsm_stop(ubyte prio @X) clobbers(A, X, Y)
    romsub $083c = zsm_rewind(ubyte prio @X) clobbers(A, X, Y)
    romsub $083f = zsm_close(ubyte prio @X) clobbers(A, X, Y)
    romsub $0842 = zsm_fill_buffers() clobbers(A, X, Y)
    romsub $0845 = zsm_setlfs(ubyte prio @X, ubyte lfn_sa @A, ubyte device @Y) clobbers(A, X, Y)
    romsub $0848 = zsm_setfile(ubyte prio @X, str filename @AY) clobbers(A, X, Y)
    romsub $084b = zsm_setmem(ubyte prio @X, uword data_ptr @AY) clobbers(A, X, Y)
    romsub $084e = zsm_setatten(ubyte prio @X, ubyte value @A) clobbers(A, X, Y)

    const ubyte zsmkit_bank = 1

    sub start() {

        txt.chrout(19)      ; HOME
        txt.print("\nsprite test\n\n")

        ; load our sprites into VERA
        void diskio.vload("birdsprites.bin", 0, $a000)

        ; enable sprites
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01000000

        ; setup bird sprites and their starting position, direction, and frame
        const  ubyte  num_birds = 128
        uword[num_birds] birdX
        uword[num_birds] birdY
        bool[num_birds] xDir
        bool[num_birds] yDir
        ubyte[num_birds] birdFrame
        ubyte k = 0
        for k in 0 to num_birds-1
        {
            birdX[k] = 10 + (math.rndw() % 610)
            birdY[k] = 10 + (math.rndw() % 450)
            xDir[k] = (math.rnd() > 120)
            yDir[k] = (math.rnd() > 120)
            birdFrame[k] = math.rnd() % 8
            ; bird sprites are 16x16, 8bpp, and between layer 0 and layer 1
            sprite.setup(k, %00000101, %00011000, 0)
            sprite.position(k, birdX[k], birdY[k])
            sprite.flips(k, xDir[k])
            set_sprite_frame(k, birdFrame[k])
        }

        ; setup zsmkit and start the music playing
        init_engine(zsmkit_bank)
        zsm_setfile(0, iso:"TFV.ZSM")
        zsm_play(0)
        ; call zsm_tick from irq handler
        sys.set_irq(&zsm_tick, true)

        bool paused = false
        uword oldjoy = $ffff

        repeat
        {
            ; only update bird sprites when not paused
            if (not paused)
            {
                ubyte j = 0
                for j in 0 to num_birds-1
                {
                    ; write the current frame and position to the sprite registers
                    set_sprite_frame(j, birdFrame[j])
                    sprite.position(j, birdX[j], birdY[j])

                    ; update bird position and handle fliping on X as needed
                    if (xDir[j]) birdX[j]++ else birdX[j]--
                    if (yDir[j]) birdY[j]++ else birdY[j]--
                    if (birdX[j] > 620 or birdX[j] < 10)
                    {
                        xDir[j] = not xDir[j]
                        sprite.flips(j, xDir[j])
                    }
                    if (birdY[j] > 460 or birdY[j] < 10)
                    {
                        yDir[j] = not yDir[j]
                    }

                    ; next frame and wrap from 7 back to 0
                    birdFrame[j]++
                    birdFrame[j] %= 8
                }
            }

            ; handle pausing music when pressing enter
            uword newjoy = cx16.joystick_get2(0)
            if (newjoy != oldjoy and (newjoy & $10) == 0)
            {
                if (paused)
                {
                    zsm_play(0)
                    paused = false
                }
                else
                {
                    zsm_stop(0)
                    paused = true
                }
                zsm_close(1)
                zsm_setfile(1, iso:"PAUSE.ZSM")
                zsm_play(1)
            }
            oldjoy = newjoy

            sys.waitvsync()

            ; update zsmkit streaming buffers
            zsm_fill_buffers()
        }
    }

    ; select which sprite image to display using sprite 1 (second sprite)
    sub set_sprite_frame(ubyte spriteNum, ubyte index) {

        ; sprites are in VERA memory at $a000
        const uword sprite_data_addr = $a000
        ; each sprite is 256 bytes so incrementing the upper byte of the uword advances to the next sprite image
        sprite.set_address(spriteNum, 0, sprite_data_addr + mkword(index, 0))
    }
}

sprite {

    ; widthHeight = (width << 2) | (height)
    ;  width and height are o to 3 for 0 = 8, 1 = 16, 2 = 32, 3 = 64.
    ; modeZDepthVHFlips = (mode << 4) | (zDepth << 2) | (vFlip << 1) | hFlip
    ;  mode is 0 = 4bpp and 1 = 8bpp
    ;  zDepth is 0 to 3, 0 = disabled, 1 = behind layer0, 2 = between layer0 and layer1, 3 = in front of layer1
    ;  vFlip and hFlip are 0 = not flipped, 1 = flipped
    ; collisionMaskPaletteOffset
    ;  paletteOffset lower 4 bits
    ;  collisionMask upper 4 bits
    sub setup(ubyte spriteNum, ubyte widthHeight, ubyte modeZDepthVHFlip, ubyte collisionMaskPaletteOffset) {

        uword offset = spriteNum as uword << 3
        ubyte temp1 = (widthHeight << 4) | (collisionMaskPaletteOffset & $0F)
        ubyte temp2 = (collisionMaskPaletteOffset & $F0) | (modeZDepthVHFlip & $0F)
        ubyte temp3 = ((modeZDepthVHFlip & $F0) << 3) | (cx16.vpeek(1, $fc01 + offset) & $7F)
        cx16.vpoke(1, $fc01 + offset, temp3)
        cx16.vpoke(1, $fc06 + offset, temp2)
        cx16.vpoke(1, $fc07 + offset, temp1)
    }

    sub flips(ubyte spriteNum, ubyte VHFlips) {

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
    sub position(ubyte spriteNum, uword xPos, uword yPos) {

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
    sub set_address(ubyte spriteNum, ubyte spriteBank, uword spriteAddress) {

        uword offset = spriteNum as uword << 3
        uword addr = (spriteAddress >> 5) | ((spriteBank as uword & 1) << 11)
        set_addressEx(1, $fc00 + offset, addr)
    }
}
