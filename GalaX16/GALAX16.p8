%import textio
%import diskio
%import math
%import syslib
%import palette
%import zsmkit
%import galax_sprites
%import joystick
%import InputHandler
%import SpritePathTables
%import Entity
%import Sequencer
%zeropage kernalsafe

main $0830
{
zsmkit_lib:
    ; this has to be the first statement to make sure it loads at the specified module address $0830
    %asmbinary "zsmkit-0830.bin"
    const ubyte zsmkit_bank = 1
    const ubyte game_banks_start = 2
    const ubyte zsmdata_bank_start = 3
    
    ; variables set in the zsmkit callback
    bool loopchanged = false
    bool beat = false

    sub start()
    {
        void cx16.screen_mode(8, false)

        txt.home()
        txt.print(iso:"\nLOADING...")

        SetupZSMKit()

        InputHandler.Init()
        SpritePathTables.Init(game_banks_start);
        sprites.Init()

        txt.cls()
        txt.home()
        txt.print(iso:"\nGALAX16")

        const ubyte num_entities = 64
        SetupDemoEnitities(num_entities)

        repeat
        {
            cx16.VERA_DC_BORDER = 8
            Entity.Begin()
            Entity.UpdateSprites(num_entities-1)
            Entity.End()

            cx16.VERA_DC_BORDER = 2
            if (not InputHandler.IsPaused() and temp == 0)
            {
                Entity.Begin()
                ubyte j = 0
                for j in 0 to num_entities-1
                {
                    cx16.VERA_DC_BORDER = 2 + j % 1
                    if (Entity.UpdateEntity(j))
                    {
                        void Entity.UpdateEntity(j)
                    }
                    cx16.VERA_DC_BORDER = 2
                }
                Entity.End()
            }
            cx16.VERA_DC_BORDER = 7

            InputHandler.DoScan();

            cx16.VERA_DC_BORDER = 5
            zsmkit.zsm_fill_buffers()

            if (beat)
            {
                beat = false
            }

            if (loopchanged)
            {
                loopchanged = false
            }

            cx16.VERA_DC_BORDER = 0
            sys.waitvsync()
        }
    }

    sub SetupDemoEnitities(ubyte num_ships)
    {
        ubyte k
        Entity.Begin()
        for k in 0 to num_ships-1
        {
            Entity.Add(k, 128, 0, ((k>>3) % 10) << 1, Entity.state_onpath, 0)
        }
        ubyte numUpdates = 0
        for k in 0 to num_ships-1
        {
            repeat numUpdates
            {
                if (Entity.UpdateEntity(k))
                {
                    void Entity.UpdateEntity(k)
                }
            }
            numUpdates+=2
        }
        Entity.End()
    }

    sub SetupZSMKit()
    {
        ; setup zsmkit
        zsmkit.zsm_init_engine(zsmkit_bank)
        cx16.rambank(zsmdata_bank_start)
        void diskio.load_raw(iso:"TFVRISESYNC.ZSM", $A000)
        ubyte zcmbank = cx16.getrambank() + 1
        cx16.rambank(zsmdata_bank_start)
        zsmkit.zsm_setmem(0, $A000)

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
        zsmkit.zsm_setatten(0, 40)
        zsmkit.zsm_play(0)
        zsmkit.zsm_setcb(0, &zsm_callback_handler)

        ; call zsm_tick from irq handler
        zsmkit.zsmkit_setisr()

        ; set back to kernel bank
        cx16.rambank(0)
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
