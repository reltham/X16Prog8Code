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
%import InputHandler
%zeropage kernalsafe

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
        void cx16.screen_mode(8, false)

        txt.home()
        txt.print(iso:"\nGALAX16")
        
        InputHandler.Init()
        SpritePathTables.Init(game_banks_start);

        sprites.Init()
        
        ; setup sprites and their starting position, direction, and frame
        const  ubyte  num_ships = 80
        ubyte k
        Entity.Begin()
        for k in 0 to num_ships-1
        {
            Entity.Add(k, 128, 0, ((k>>3) % 10) << 1, Entity.state_onpath, 5)
        }
        ubyte numUpdates = 0
        ubyte l = 0
        for k in 0 to num_ships-1
        {
            for l in 0 to numUpdates
            {
                if (Entity.UpdateEntity(k))
                {
                    void Entity.UpdateEntity(k)
                }
            }
            numUpdates+=2
        }
        Entity.End()

        ; setup zsmkit
        zsmkit.zsm_init_engine(zsmkit_bank)
        ;zsmkit.zsm_setfile(0, iso:"TFV_PCM.ZSM")
        ;zsmkit.zsm_setfile(0, iso:"TFVRISESYNC.ZSM")
        ;zsmkit.zsm_setfile(0, iso:"SHOVEL_S.ZSM")
        cx16.rambank(zsmdata_bank_start)
        ;void diskio.load_raw(iso:"TFVRISESYNC.ZSM", $A000)
        ubyte zcmbank = cx16.getrambank() + 1
        ;cx16.rambank(zsmdata_bank_start)
        ;zsmkit.zsm_setmem(0, $A000)
        ;void zsmkit.zsm_loadpcm(0, $a000)

        ; load 2 zcm's into memory
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
        ;zsmkit.zsm_setatten(0, 20)
        ;zsmkit.zsm_play(0)
        ;zsmkit.zsm_setcb(0, &zsm_callback_handler)

        ; call zsm_tick from irq handler
        ;zsmkit.zsmkit_setisr()
        
        ; set back to kernel bank
        cx16.rambank(0)

        byte doShips = 0

        ubyte j = 0
        repeat
        {
            cx16.VERA_DC_BORDER = 8
            Entity.Begin()
            Entity.UpdateSprites(num_ships-1)
            Entity.End()

            if (beat)
            {
                doShips = 4
                beat = false
            }

            cx16.VERA_DC_BORDER = 2
            ; only update sprites when not paused
            if (not InputHandler.IsPaused())
            {
                Entity.Begin()
                for j in 0 to num_ships-1
                {
                    cx16.VERA_DC_BORDER = 2 + j % 1
                    if (Entity.UpdateEntity(j))
                    {
                        void Entity.UpdateEntity(j)
                    }
                    cx16.VERA_DC_BORDER = 2
                }
                Entity.End()
                if (doShips > 0) doShips--
            }
            cx16.VERA_DC_BORDER = 7

            InputHandler.DoScan();

            cx16.VERA_DC_BORDER = 5
            ; update zsmkit streaming buffers
            ;zsmkit.zsm_fill_buffers()

            if (loopchanged)
            {
                loop_number++
                loopchanged = false
                txt.print(iso:"LOOP NUMBER: ")
                txt.print_uw(loop_number)
                txt.nl()
            }
            cx16.VERA_DC_BORDER = 0

            sys.waitvsync()
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
