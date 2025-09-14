Sounds 
{
    ubyte[255] zsmkit_lowram
    const ubyte zsmdata_bank_start = 3
    
    ; variables set in the zsmkit callback
    bool loopchanged = false
    bool beat = false

    struct SfxData {
        str name
        ubyte priority
        ubyte bank
        uword addr
    }

    ^^SfxData[] sfx_data = [
        ^^SfxData:[iso:"SPACEWARP10.ZSM", 1, 0, 0],
        ^^SfxData:[iso:"ENEMYSHOOT11.ZSM", 2, 0, 0],
        ^^SfxData:[iso:"ENEMYHIT12.ZSM", 3, 0, 0],
        ^^SfxData:[iso:"ENEMYDIVE14.ZSM", 5, 0, 0],
        ^^SfxData:[iso:"PLAYERSHOOT16.ZSM", 7, 0, 0],
        ^^SfxData:[iso:"BOOM_15.ZSM", 6, 0, 0],
        ^^SfxData:[iso:"PEW_16.ZSM", 7, 0, 0],
        ^^SfxData:[iso:"UFO_14.ZSM", 5, 0, 0],
        ^^SfxData:[iso:"UFO_16.ZSM", 7, 0, 0],
        ^^SfxData:[iso:"WIBBLE_16.ZSM", 7, 0, 0],
        ^^SfxData:[iso:"SWEEPDOWNL_15.ZSM", 6, 0, 0],
        ^^SfxData:[iso:"SWEEPUP_15.ZSM", 6, 0, 0],
        ^^SfxData:[iso:"SFX10.ZSM", 1, 0, 0],
        ^^SfxData:[iso:"SFX11.ZSM", 2, 0, 0],
        ^^SfxData:[iso:"SFX12.ZSM", 3, 0, 0],
        ^^SfxData:[iso:"SFX13.ZSM", 4, 0, 0]
    ]

    sub GetLoopChanged() -> bool
    {
        return loopchanged
    }
    
    sub ClearLoopChanged()
    {
        loopchanged = false;
    }

    sub GetBeat() -> bool
    {
        return beat
    }

    sub ClearBeat()
    {
        beat = false;
    }

    sub PlaySFX(ubyte index)
    {
        ^^SfxData sfx = sfx_data[index]
        zsmkit.zsm_setbank(sfx.priority, sfx.bank)
        zsmkit.zsm_setmem(sfx.priority, sfx.addr)
        zsmkit.zsm_play(sfx.priority)
    }

    sub SetupZSMKit()
    {
        ; load zsmkit in bank 1 and the music starting
        cx16.rambank(zsmkit.ZSMKitBank)
        void diskio.load_raw("zsmkit-a000.bin",$A000)
        ; setup zsmkit
        zsmkit.zsm_init_engine(&zsmkit_lowram)

        cx16.rambank(zsmdata_bank_start)
        void diskio.load_raw(iso:"TEST.ZSM", $A000)
        ubyte zcmbank = cx16.getrambank() + 1
        zsmkit.zsm_setbank(0, zsmdata_bank_start)
        zsmkit.zsm_setmem(0, $A000)

        ; load 2 zcm's into memory
        cx16.rambank(zcmbank)
        void diskio.load_raw(iso:"1.ZCM", $A000)
        ubyte zcmbank2 = cx16.getrambank() + 1
        cx16.rambank(zcmbank2)
        void diskio.load_raw(iso:"2.ZCM", $A000)
        ubyte sfx_bank = cx16.getrambank() + 1
        cx16.rambank(zcmbank2)
        zsmkit.zcm_setmem(0, $A000)
        cx16.rambank(zcmbank)
        zsmkit.zcm_setmem(1, $A000)

        ;txt.nl()
        cx16.rambank(sfx_bank)
        uword curr_addr = $A000
        ^^SfxData sfx
        for sfx in sfx_data
        {
            sfx.addr = curr_addr
            sfx.bank = cx16.getrambank()
            curr_addr = diskio.load_raw(sfx.name, curr_addr)
            ;txt.print(sfx.name)
            ;txt.spc()
            ;txt.print_ub(sfx.bank)
            ;txt.spc()
            ;txt.print_uwhex(sfx.addr,true)
            ;txt.nl()
        }

        ; start the music playing
        zsmkit.zsm_setatten(0, 15)
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