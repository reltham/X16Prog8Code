
sprites
{
    const uword sprite_data_addr = $B000

    ; sprites are loaded into VERA memory at $8000
    ; sprites are 16x16x4bpp, so 128 bytes per sprite
    const uword sprite_data_vera_addr = $8000
    const uword sprite_data_vera_addr_shifted = sprite_data_vera_addr >> 5
    const uword sprite_data_vera_addr_shifted2 = $800
    const uword sprite_size = 128
    
    const ubyte sprite_address_low = 0
    const ubyte sprite_address_high_mode = 1
    const ubyte sprite_position_x = 2
    const ubyte sprite_position_y = 4
    const ubyte sprite_collision_mask_zdepth_VHFlips = 6
    const ubyte sprite_width_height_palette_offset = 7
    
    const ubyte size_8 = 0
    const ubyte size_16 = 1
    const ubyte size_32 = 2
    const ubyte size_64 = 3
    const ubyte bpp_4 = 0
    const ubyte bpp_8 = 128
    const ubyte zdepth_disabled = 0
    const ubyte zdepth_back = 1
    const ubyte zdepth_middle = 2
    const ubyte zdepth_front = 3
    const ubyte flips_none = 0
    const ubyte flips_H = 1
    const ubyte flips_V = 2
    const ubyte flips_both = 3

    ; current sprites default setup
    const ubyte mode = bpp_4
    const ubyte collision_mask = 0
    const ubyte zdepth = zdepth_middle
    const ubyte VHFlips = flips_none
    const ubyte palette_offset = 2

    sub Init()
    {
        ; load our sprites into VERA, the palette is loaded right into the palette registers at $fa00
        void diskio.vload_raw(iso:"GALSPRITES.PAL", 1, $fa00)
        void diskio.vload_raw(iso:"GALSPRITES.BIN", 0, sprite_data_vera_addr)
        void diskio.vload_raw(iso:"EXPLOSIONSMISC.BIN", 1, $0000)
        void diskio.vload_raw(iso:"EXPLOSIONSMISC.PAL", 1, $fa20)
        void diskio.vload_raw(iso:"REDSHIPS.BIN", 1, $2000)
        void diskio.vload_raw(iso:"REDSHIPS.PAL", 1, $fa40)
        void diskio.vload_raw(iso:"GREENSHIPS.BIN", 1, $4000)
        void diskio.vload_raw(iso:"GREENSHIPS.PAL", 1, $fa60)
        void diskio.vload_raw(iso:"BLUESHIPS.BIN", 1, $6000)
        void diskio.vload_raw(iso:"BLUESHIPS.PAL", 1, $fa80)

        ; enable sprites
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01000000

        ; init sprite slots
        cx16.r1 = sprite_data_vera_addr_shifted2
        cx16.r1H |= mode
        cx16.r2L = collision_mask << 4 | zdepth << 2 | VHFlips
        ;cx16.r2H = size_16 << 6 | size_16 << 4 | palette_offset 
        cx16.r2H = size_32 << 6 | size_32 << 4 | palette_offset 
        uword @zp curr_sprite_slot = sprite_data_addr;
        repeat 128
        {
            curr_sprite_slot[sprite_address_low] = cx16.r1L
            curr_sprite_slot[sprite_address_high_mode] = cx16.r1H
            pokew(curr_sprite_slot + sprite_position_x, -64 as uword)
            pokew(curr_sprite_slot + sprite_position_y, -64 as uword)
            curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] = cx16.r2L
            curr_sprite_slot[sprite_width_height_palette_offset] = cx16.r2H
            curr_sprite_slot += 8
        }
        Update()
    }

    sub SetPosAddrFlips(ubyte slot, uword newX, uword newY, ubyte index, ubyte flips)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);

        pokew(curr_sprite_slot + sprite_position_x, newX)
        pokew(curr_sprite_slot + sprite_position_y, newY)

        uword addr = (sprite_data_vera_addr_shifted2 + (index as uword << 4)) ; calc sprite vera address, but already shifted down 5 (since we only need upper 11 bits)
        curr_sprite_slot[sprite_address_low] = lsb(addr)
        ubyte curr_mode = curr_sprite_slot[sprite_address_high_mode] & %10000000
        curr_sprite_slot[sprite_address_high_mode] = msb(addr) | curr_mode

        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] &= %11111100
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] |= flips
    }
    
    sub SetAddress(ubyte slot, ubyte index)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        uword addr = (sprite_data_vera_addr_shifted2 + (index as uword << 4)) ; calc sprite vera address, but already shifted down 5 (since we only need upper 11 bits)
        curr_sprite_slot[sprite_address_low] = lsb(addr)
        ubyte curr_mode = curr_sprite_slot[sprite_address_high_mode] & %10000000
        curr_sprite_slot[sprite_address_high_mode] = msb(addr) | curr_mode
    }

    sub SetPosition(ubyte slot, uword newX, uword newY)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        pokew(curr_sprite_slot + sprite_position_x, newX)
        pokew(curr_sprite_slot + sprite_position_y, newY)
    }

    sub SetX(ubyte slot, uword newX)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        pokew(curr_sprite_slot + sprite_position_x, newX)
    }

    sub SetY(ubyte slot, uword newY)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        pokew(curr_sprite_slot + sprite_position_y, newY)
    }

    sub GetX(ubyte slot) -> word
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        return peekw(curr_sprite_slot + sprite_position_x) as word
    }

    sub GetY(ubyte slot) -> word
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        return peekw(curr_sprite_slot + sprite_position_y) as word
    }

    sub SetFlips(ubyte slot, ubyte flips)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] &= %11111100
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] |= flips
    }

    sub SetPaletteOffset(ubyte slot, ubyte offset)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3);
        curr_sprite_slot[sprite_width_height_palette_offset] &= %11110000
        curr_sprite_slot[sprite_width_height_palette_offset] |= offset
    }

    asmsub Update() clobbers (A, X, Y)
    {
        %asm {{
            ; setup our address in vera with auto increment of 1
            stz  cx16.VERA_CTRL
            lda  #%00010001
            sta  cx16.VERA_ADDR_H
            lda  #<$fc00
            sta  cx16.VERA_ADDR_L
            lda  #>$fc00
            sta  cx16.VERA_ADDR_M

            ; set up our memory read address
            lda  #<$b000
            ldy  #>$b000
            sta  p8s_SetFlips.p8v_curr_sprite_slot
            sty  p8s_SetFlips.p8v_curr_sprite_slot+1

            ; loop over all 128 sprites and set their 8 bytes from memory

            ldx 128
_sprite_update_outer_loop
            ; inner loop from 0 to 7
            ldy #0
_sprite_update_inner_loop
            lda (p8s_SetFlips.p8v_curr_sprite_slot), y
            sta  cx16.VERA_DATA0
            iny
            cpy #8
            bne _sprite_update_inner_loop

            ; add 8 to curr_sprite_slot
            lda  p8s_SetFlips.p8v_curr_sprite_slot
            clc
            adc  #8
            sta  p8s_SetFlips.p8v_curr_sprite_slot
            bcc  +
            inc  p8s_SetFlips.p8v_curr_sprite_slot+1
+
            dex
            cpx #0
            bne _sprite_update_outer_loop

            rts
        }}
    }
}
