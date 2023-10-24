%import textio
%import diskio
%import math
%import syslib
%import palette
%import zsmkit
%import sprites
%import joystick
%import SpritePathTables
%zeropage basicsafe

; "issues":
; - prog8 (or rather, 64tass) cannot "link" other assembly object files so we have to incbin a binary blob.
; - prog8 main has to be set to a fixed address (in this case $0830) to which the special zsmkit binary has been compiled as well.

main $0830
{

zsmkit_lib:
    ; this has to be the first statement to make sure it loads at the specified module address $0830
    %asmbinary "zsmkit-0830.bin"
    const ubyte zsmkit_bank = 1

    bool loopchanged = false
    bool beat = false
    uword loop_number = 0

    ; sprites are loaded into VERA memory at $8000
    const uword sprite_data_addr = $8000

    sub start()
    {

        txt.home()
        txt.print(iso:"\nGALAX16\n\n")

        ; init joystick, use keyboard one for now, need to detect joystick 1
        joystick.active_joystick = 1
        joystick.clear()

        ; load our sprites into VERA, the palette is loaded right into the palette registers at $fa00
        void diskio.vload_raw(iso:"GALSPRITES.PAL", 1, $fa00)
        void diskio.vload_raw(iso:"GALSPRITES.BIN", 0, sprite_data_addr)

        ; enable sprites
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01000000

        ; setup sprites and their starting position, direction, and frame
        const  ubyte  num_ships = 64
        word[num_ships] shipX
        word[num_ships] shipY
        ubyte[num_ships] pathIndex
        ubyte[num_ships] whichPath = 1
        ubyte k = 0
        word offsetX = 0
        word offsetY = 128
        ubyte q = 0
        byte[5] pathEntry
        for k in 0 to num_ships-1
        {
            if (k > 0 and k % 8 == 0)
            {
                offsetY = 128 - ((k >> 3) * 16)
                offsetX = (k >> 3) * 24
                q = 0
            }
            repeat 1
            {
                pathIndex[k] = q % 38
                SpritePathTables.GetPathEntry(whichPath[k], pathIndex[k], ((k>>3) % 9) << 1, &pathEntry)
                word tempXa = pathEntry[0] as word
                word tempYa = pathEntry[1] as word
                offsetX += tempXa
                offsetY += tempYa
                q++
            }
            shipX[k] = 10 + offsetX
            shipY[k] = 10 + offsetY
            ; sprites are 16x16, 8bpp, and between layer 0 and layer 1
            sprites.setup(k, %00000101, %00001000, 0)
            sprites.position(k, shipX[k] as uword, shipY[k] as uword)
            set_sprite_frame(k, pathEntry[3] as ubyte, 128)
            sprites.flips(k, pathEntry[4] as ubyte)
        }

        ; setup zsmkit
        zsmkit.zsm_init_engine(zsmkit_bank)
        ;zsmkit.zsm_setfile(0, iso:"TFV_PCM.ZSM")
        zsmkit.zsm_setfile(0, iso:"TFVRISESYNC.ZSM")
        ;zsmkit.zsm_setfile(0, iso:"SHOVEL_S.ZSM")
        cx16.rambank(2)
        uword next_free = zsmkit.zsm_loadpcm(0, $a000)

        ; load 2 zcm's into memory
        ubyte zcmbank = cx16.getrambank() + 1
        cx16.rambank(zcmbank)
        void diskio.load_raw(iso:"1.ZCM", $a000)

        ubyte zcmbank2 = cx16.getrambank() + 1
        cx16.rambank(zcmbank2)
        void diskio.load_raw(iso:"2.ZCM", $a000)

        cx16.rambank(zcmbank2)
        zsmkit.zcm_setmem(0, $a000)
        cx16.rambank(zcmbank)
        zsmkit.zcm_setmem(1, $a000)
        
        ; start the music playing
        zsmkit.zsm_play(0)
        zsmkit.zsm_setcb(0, &zsm_callback_handler)

        ; call zsm_tick from irq handler
        zsmkit.zsmkit_setisr()
        
        ; set back to kernel bank
        cx16.rambank(0)

        bool paused = false
        bool oldup = false
        bool olddown = false
        bool oldleft = false
        bool oldright = false
        bool oldstart = false
        bool oldselect = false
        bool oldfire = false
        bool oldfire_a = false
        bool oldfire_b = false
        bool oldfire_x = false
        bool oldfire_y = false
        bool oldfire_l = false
        bool oldfire_r = false
        ubyte repeatIndex = 0
        byte doShips = 0

        repeat
        {
            if (beat)
            {
                doShips = 4
                beat = false
            }

            ; only update sprites when not paused
            if (not paused)
            {
                repeatIndex++
                ubyte j = 0
                for j in 0 to num_ships-1
                {
                    ubyte shipIndex = ((j>>3) % 9) << 1
                    if doShips > 0
                    {
                        shipIndex++
                    }
                    SpritePathTables.GetPathEntry(whichPath[j], pathIndex[j], shipIndex, &pathEntry)

                    if repeatIndex >= 1
                    {
                        shipX[j] += pathEntry[0] as word
                        shipY[j] += pathEntry[1] as word
                    }
                    sprites.position(j, shipX[j] as uword, shipY[j] as uword)

                    set_sprite_frame(j, pathEntry[3] as ubyte, 128)
                    sprites.flips(j, pathEntry[4] as ubyte)

                    if (shipX[j] > 639) shipX[j] -= 656
                    if (shipX[j] < -16) shipX[j] += 656
                    if (shipY[j] > 479) shipY[j] -= 496
                    if (shipY[j] < -16) shipY[j] += 496

                    if repeatIndex >= 1
                    {
                        pathIndex[j]++
                        if (SpritePathTables.CheckEnd(whichPath[j], pathIndex[j]))
                        {
                            pathIndex[j] = 0
                            ;whichPath[j] = not whichPath[j]
                        }
                    }
                }
                if (repeatIndex >= 1)
                {
                    repeatIndex = 0
                    if (doShips > 0) doShips--
                }
            }

            ; handle pausing music when pressing enter
            joystick.scan()
            bool newup = joystick.up
            bool newdown = joystick.down
            bool newleft = joystick.left
            bool newright = joystick.right
            bool newstart = joystick.start
            bool newselect = joystick.select
            bool newfire = joystick.fire
            bool newfire_a = joystick.fire_a
            bool newfire_b = joystick.fire_b
            bool newfire_x = joystick.fire_x
            bool newfire_y = joystick.fire_y
            bool newfire_l = joystick.fire_l
            bool newfire_r = joystick.fire_r
            if (newstart != oldstart and newstart == true)
            {
                zsmkit.zcm_stop()
                if (paused)
                {
                    zsmkit.zsm_play(0)
                    paused = false
                    zsmkit.zcm_play(1, 8)
                }
                else
                {
                    zsmkit.zsm_stop(0)
                    paused = true
                    zsmkit.zcm_play(0, 8)
                }
            }
            if (newselect != oldselect and newselect == true)
            {
                txt.print("pressed select\n")
            }
            if (newup != oldup and newup == true)
            {
                zsmkit.zsm_close(1)
                zsmkit.zsm_setfile(1, iso:"UFO_16.ZSM")
                zsmkit.zsm_play(1)
                txt.print("pressed up\n")
            }
            if (newdown != olddown and newdown == true)
            {
                zsmkit.zsm_close(2)
                zsmkit.zsm_setfile(2, iso:"UFO_14.ZSM")
                zsmkit.zsm_play(2)
                txt.print("pressed down\n")
            }
            if (newleft != oldleft and newleft == true)
            {
                zsmkit.zsm_close(3)
                zsmkit.zsm_setfile(3, iso:"BOOM_15.ZSM")
                zsmkit.zsm_play(3)
                txt.print("pressed left\n")
            }
            if (newright != oldright and newright == true)
            {
                zsmkit.zsm_close(1)
                zsmkit.zsm_setfile(1, iso:"PEW_16.ZSM")
                zsmkit.zsm_play(1)
                txt.print("pressed right\n")
            }
            if (newfire_a != oldfire_a and newfire_a == true)
            {
                zsmkit.zsm_close(3)
                zsmkit.zsm_setfile(3, iso:"SWEEPDOWNL_15.ZSM")
                zsmkit.zsm_play(3)
                txt.print("pressed a\n")
            }
            if (newfire_b != oldfire_b and newfire_b == true)
            {
                zsmkit.zsm_close(3)
                zsmkit.zsm_setfile(3, iso:"SWEEPUP_15.ZSM")
                zsmkit.zsm_play(3)
                txt.print("pressed b\n")
            }
            if (newfire_l != oldfire_l and newfire_l == true)
            {
                zsmkit.zsm_close(1)
                zsmkit.zsm_setfile(1, iso:"WIBBLE_16.ZSM")
                zsmkit.zsm_play(1)
                txt.print("pressed ls\n")
            }
            if (newfire_r != oldfire_r and newfire_r == true)
            {
                zsmkit.zsm_close(2)
                zsmkit.zsm_setfile(2, iso:"UFO_14.ZSM")
                zsmkit.zsm_play(2)
                txt.print("pressed rs\n")
            }
            if (newfire_x != oldfire_x and newfire_x == true)
            {
                zsmkit.zsm_close(3)
                zsmkit.zsm_setfile(3, iso:"BOOM_15.ZSM")
                zsmkit.zsm_play(3)
                txt.print("pressed x\n")
            }
            if (newfire_y != oldfire_y and newfire_y == true)
            {
                zsmkit.zsm_close(1)
                zsmkit.zsm_setfile(1, iso:"PEW_16.ZSM")
                zsmkit.zsm_play(1)
                txt.print("pressed y\n")
            }
            oldup = newup
            olddown = newdown
            oldleft = newleft
            oldright = newright
            oldstart = newstart
            oldselect = newselect
            oldfire = newfire
            oldfire_a = newfire_a
            oldfire_b = newfire_b
            oldfire_x = newfire_x
            oldfire_y = newfire_y
            oldfire_l = newfire_l
            oldfire_r = newfire_r

            sys.waitvsync()

            ; update zsmkit streaming buffers
            zsmkit.zsm_fill_buffers()

            if loopchanged
            {
                loop_number++
                loopchanged = false
                txt.print(iso:"LOOP NUMBER: ")
                txt.print_uw(loop_number)
                txt.nl()
            }
        }
    }

    asmsub zsm_callback_handler(ubyte prio @X, ubyte type @Y, ubyte arg @A) {
        %asm {{
            cpy #1
            beq _loop
            cpy #2
            beq _sync
            rts
_loop:
            inc p8_loopchanged
            rts
_sync:
            inc p8_beat
            rts
        }}
    }


    ; select which sprite image to display
    sub set_sprite_frame(ubyte spriteNum, ubyte index, uword spriteSize)
    {
        ; calculate address of the sprite's memory from index and spriteSize
        sprites.set_address(spriteNum, 0, sprite_data_addr + (index as uword * spriteSize))
    }
}
