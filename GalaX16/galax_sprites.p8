
sprites
{
    const uword sprite_data_addr = $0400

    ; sprites are loaded into VERA memory at $10000
    ; sprites are 16x16x4bpp, so 128 bytes per sprite
    const uword sprite_image_data_vera_addr_shifted = $800 ; $10000 >> 5
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
    const ubyte palette_offset = 2

    sub Init()
    {
        ; load logo sprites into VERA, palette is loaded right into registers at $1fa00+
        void diskio.vload_raw(iso:"GALAX16-256X64.BIN", 0, $C000)
        void diskio.vload_raw(iso:"GALAX16-256X64-PALETTE.BIN", 1, $FA00)
        
        ; load our sprites into VERA, the palettes are loaded right into the palette registers at $1fB00+
        void diskio.vload_raw(iso:"EXPLOSIONSMISC.BIN", 1, $0000)
        void diskio.vload_raw(iso:"EXPLOSIONSMISC.PAL", 1, $FB00)
        void diskio.vload_raw(iso:"REDSHIPS.BIN", 1, $2000)
        void diskio.vload_raw(iso:"REDSHIPS.PAL", 1, $FB20)
        void diskio.vload_raw(iso:"GREENSHIPS.BIN", 1, $4000)
        void diskio.vload_raw(iso:"GREENSHIPS.PAL", 1, $FB40)
        void diskio.vload_raw(iso:"BLUESHIPS.BIN", 1, $6000)
        void diskio.vload_raw(iso:"BLUESHIPS.PAL", 1, $FB60)

        void diskio.vload_raw(iso:"STARTILES.BIN", 0, $B800)
        void diskio.vload_raw(iso:"STARTILES.PAL", 1, $FBE0)

        ; enable sprites
        cx16.VERA_DC_VIDEO = cx16.VERA_DC_VIDEO | %01000000

        ; init sprite slots
        ResetSpriteSlots()

        Update()
    }
    
    sub ResetSpriteSlots()
    {
        cx16.r1 = sprite_image_data_vera_addr_shifted
        cx16.r1H |= mode
        cx16.r2L = collision_mask << 4 | zdepth_disabled << 2 | flips_none
        cx16.r2H = size_32 << 6 | size_32 << 4 | palette_offset 
        uword @zp curr_sprite_slot = sprite_data_addr;
        repeat 124
        {
            curr_sprite_slot[sprite_address_low] = cx16.r1L
            curr_sprite_slot[sprite_address_high_mode] = cx16.r1H
            pokew(curr_sprite_slot + sprite_position_x, -64 as uword)
            pokew(curr_sprite_slot + sprite_position_y, -64 as uword)
            curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] = cx16.r2L
            curr_sprite_slot[sprite_width_height_palette_offset] = cx16.r2H
            curr_sprite_slot += 8
        }

        ; put logo sprites in last 4 slots, disabled and positioned correctly.
        cx16.r1 = $600
        cx16.r1H |= bpp_8
        cx16.r2L = collision_mask << 4 | zdepth_disabled << 2 | flips_none
        cx16.r2H = size_64 << 6 | size_64 << 4 | 0
        cx16.r3 = 128 as uword
        repeat 4
        {
            curr_sprite_slot[sprite_address_low] = cx16.r1L
            curr_sprite_slot[sprite_address_high_mode] = cx16.r1H
            pokew(curr_sprite_slot + sprite_position_x, cx16.r3)
            pokew(curr_sprite_slot + sprite_position_y, 128 as uword)
            curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] = cx16.r2L
            curr_sprite_slot[sprite_width_height_palette_offset] = cx16.r2H
            curr_sprite_slot += 8
            cx16.r1 += $80
            cx16.r3 += 64 as uword
        }
    }

    sub SetPosAddrFlips(ubyte slot, uword newX, uword newY, ubyte index, ubyte flips)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)

        pokew(curr_sprite_slot + sprite_position_x, newX)
        pokew(curr_sprite_slot + sprite_position_y, newY)

        uword @zp addr = (sprite_image_data_vera_addr_shifted + (index as uword << 4)) ; calc sprite vera address, but already shifted down 5 (since we only need upper 11 bits)
        curr_sprite_slot[sprite_address_low] = lsb(addr)
        ubyte @zp curr_mode = curr_sprite_slot[sprite_address_high_mode] & %10000000
        curr_sprite_slot[sprite_address_high_mode] = msb(addr) | curr_mode

        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] &= %11111100
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] |= flips
    }
    
    sub SetAddress(ubyte slot, ubyte index)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        uword @zp addr = (sprite_image_data_vera_addr_shifted + (index as uword << 4)) ; calc sprite vera address, but already shifted down 5 (since we only need upper 11 bits)
        curr_sprite_slot[sprite_address_low] = lsb(addr)
        ubyte @zp curr_mode = curr_sprite_slot[sprite_address_high_mode] & %10000000
        curr_sprite_slot[sprite_address_high_mode] = msb(addr) | curr_mode
    }

    sub SetPosition(ubyte slot, uword newX, uword newY)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        pokew(curr_sprite_slot + sprite_position_x, newX)
        pokew(curr_sprite_slot + sprite_position_y, newY)
    }

    sub SetX(ubyte slot, uword newX)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        pokew(curr_sprite_slot + sprite_position_x, newX)
    }

    sub SetY(ubyte slot, uword newY)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        pokew(curr_sprite_slot + sprite_position_y, newY)
    }

    sub GetX(ubyte slot) -> word
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        return peekw(curr_sprite_slot + sprite_position_x) as word
    }

    sub GetY(ubyte slot) -> word
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        return peekw(curr_sprite_slot + sprite_position_y) as word
    }

    sub SetFlips(ubyte slot, ubyte flips)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] &= %11111100
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] |= flips
    }

    sub SetPaletteOffset(ubyte slot, ubyte offset)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        curr_sprite_slot[sprite_width_height_palette_offset] &= %11110000
        curr_sprite_slot[sprite_width_height_palette_offset] |= offset
    }

    sub SetZDepth(ubyte slot, ubyte zdepth)
    {
        uword @zp curr_sprite_slot = sprite_data_addr + (slot as uword << 3)
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] &= %11110011
        curr_sprite_slot[sprite_collision_mask_zdepth_VHFlips] |= (zdepth << 2)
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
            lda  #<p8c_sprite_data_addr
            ldy  #>p8c_sprite_data_addr
            sta  p8s_SetFlips.p8v_curr_sprite_slot
            sty  p8s_SetFlips.p8v_curr_sprite_slot+1

            ; loop over all 128 sprites and set their 8 bytes from memory

            ldx #8
_sprite_update_outer_loop
            ; inner loop from 0 to 7
            ldy #0
_sprite_update_inner_loop
            lda (p8s_SetFlips.p8v_curr_sprite_slot), y
            sta  cx16.VERA_DATA0
            iny
            cpy #128
            bne _sprite_update_inner_loop

            ; add 8 to curr_sprite_slot
            lda  p8s_SetFlips.p8v_curr_sprite_slot
            clc
            adc  #128
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
