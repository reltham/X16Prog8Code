Sounds 
{
    ubyte[255] zsmkit_lowram
    const ubyte zsmdata_bank_start = 3
    
    ; variables set in the zsmkit callback
    bool loopchanged = false
    bool beat = false

    const ubyte num_sfx = 16
    ubyte[num_sfx] sfx_banks
    uword[num_sfx] sfx_addr
    str[num_sfx] sfx_names = [
        iso:"SPACEWARP10.ZSM",
        iso:"ENEMYSHOOT11.ZSM", 
        iso:"ENEMYHIT12.ZSM",
        iso:"ENEMYDIVE14.ZSM",
        iso:"PLAYERSHOOT16.ZSM",
        iso:"BOOM_15.ZSM",
        iso:"PEW_16.ZSM",
        iso:"UFO_14.ZSM",
        iso:"UFO_16.ZSM",
        iso:"WIBBLE_16.ZSM",
        iso:"SWEEPDOWNL_15.ZSM",
        iso:"SWEEPUP_15.ZSM",
        iso:"SFX10.ZSM",
        iso:"SFX11.ZSM",
        iso:"SFX12.ZSM",
        iso:"SFX13.ZSM"
    ]
    ubyte[num_sfx] sfx_priorities = [
        1,
        2,
        3,
        5,
        7,
        6,
        7,
        5,
        7,
        7,
        6,
        6,
        1,
        2,
        3,
        4
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
        zsmkit.zsm_setbank(sfx_priorities[index], sfx_banks[index])
        zsmkit.zsm_setmem(sfx_priorities[index], sfx_addr[index])
        zsmkit.zsm_play(sfx_priorities[index])
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
        ubyte i = 0
        for i in 0 to num_sfx-1
        {
            sfx_addr[i] = curr_addr
            curr_addr = diskio.load_raw(sfx_names[i], curr_addr)
            sfx_banks[i] = cx16.getrambank()
            ;txt.print(sfx_names[i])
            ;txt.spc()
            ;txt.print_ub(sfx_banks[i])
            ;txt.spc()
            ;txt.print_uwhex(curr_addr,true)
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