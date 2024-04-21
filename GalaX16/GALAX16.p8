%import textio
%import diskio
%import math
%import syslib
%import palette
%import zsmkit
%import galax_sprites
%import joystick
%import SpritePathTables
%import Entity
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
    
    const ubyte game_banks_start = 2
    const ubyte zsmdata_bank_start = 3

    sub start()
    {
        void cx16.set_screen_mode(0)

        txt.home()
        txt.print(iso:"\nGALAX16\n\n")

        ; init joystick, use keyboard one for now, need to detect joystick 1
        joystick.active_joystick = 1
        joystick.clear()

        ; load our sprites into VERA, the palette is loaded right into the palette registers at $fa00
        void diskio.vload_raw(iso:"GALSPRITES.PAL", 1, $fa00)
        void diskio.vload_raw(iso:"GALSPRITES.BIN", 0, Entity.sprite_data_addr)

        ; enable sprites
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01000000
        
        ; setup sprites and their starting position, direction, and frame
        const  ubyte  num_ships = 128
        ubyte[num_ships] pathIndex
        ubyte[num_ships] whichPath = 1
        ubyte k = 0
        word offsetX = 0
        word offsetY = 128
        ubyte q = 0
        byte[5] pathEntry

        Entity.Begin()
        for k in 0 to num_ships-1
        {
            if (k > 0 and k % 16 == 0)
            {
                offsetY = 128 - ((k >> 4) * 16)
                offsetX = (k >> 4) * 24
                q = 0
            }
            pathIndex[k] = q % 38
            SpritePathTables.GetPathEntry(whichPath[k], pathIndex[k], ((k>>4) % 9) << 1, &pathEntry)
            offsetX += pathEntry[0] as word
            offsetY += pathEntry[1] as word
            q++

            Entity.Add(k, 10 + offsetX as uword, 10 + offsetY as uword, pathEntry[3] as ubyte, pathEntry[4] as ubyte, Entity.state_static, 0)
            Entity.UpdateSprite(k)
        }
        Entity.End()

        ; setup zsmkit
        zsmkit.zsm_init_engine(zsmkit_bank)
        ;zsmkit.zsm_setfile(0, iso:"TFV_PCM.ZSM")
        zsmkit.zsm_setfile(0, iso:"TFVRISESYNC.ZSM")
        ;zsmkit.zsm_setfile(0, iso:"SHOVEL_S.ZSM")
        cx16.rambank(zsmdata_bank_start)
        void zsmkit.zsm_loadpcm(0, $a000)

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
        zsmkit.zsm_setatten(0, 20)
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
                ubyte j = 0
                Entity.Begin()
                for j in 0 to num_ships-1
                {
                    ubyte shipIndex = ((j>>4) % 9) << 1
                    if (doShips > 0)
                    {
                        shipIndex++
                    }
                    SpritePathTables.GetPathEntry(whichPath[j], pathIndex[j], shipIndex, &pathEntry)

                    Entity.UpdatePosition(j, pathEntry[0] as word, pathEntry[1] as word)
                    Entity.SetSpriteIndex(j, pathEntry[3] as ubyte)
                    Entity.SetSpriteSetup(j, pathEntry[4] as ubyte)
                    Entity.UpdateSprite(j)

                    pathIndex[j]++
                    if (SpritePathTables.CheckEnd(whichPath[j], pathIndex[j]))
                    {
                        pathIndex[j] = 0
                        ;whichPath[j] = (not (whichPath[j] as bool)) as ubyte
                    }
                }
                Entity.End()
                if (doShips > 0) doShips--
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
            inc p8v_loopchanged
            rts
_sync:
            inc p8v_beat
            rts
        }}
    }
}
