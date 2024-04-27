; Entity stuff

; entity data
; 0 position x (word)
; 1 
; 2 position y (word)
; 3
; 4 sprite index
; 5 collision mask | z depths | flips
; 6 state = static, formation, onpath
; 7 state data: path index, formation slot


Entity
{
    const ubyte entity_x = 0
    const ubyte entity_y = 2
    const ubyte entity_sprite_index = 4
    const ubyte entity_sprite_setup = 5
    const ubyte entity_ship_index = 6
    const ubyte entity_state = 7
    const ubyte entity_state_data = 8 ; state data is up to 8 bytes

    ; when state is static state data is not used

    ; when state is formation state data is as follows
    const ubyte entity_state_formation_slot = 8
    
    ; when state is onpath state data is as follows
    const ubyte entity_state_path = 8
    const ubyte entity_state_path_offset = 9
    const ubyte entity_state_path_repeat = 10
    const ubyte entity_state_path_return_index = 11
    const ubyte entity_state_path_return = 12 ; 4 bytes to hold path indices for gosub/return stuff (can only nest 4 deep)
    
    const ubyte entities_bank = 2
    const uword entities = $a000
    
    const ubyte state_static = 0
    const ubyte state_formation = 1
    const ubyte state_onpath = 2
    
    ; sprites are loaded into VERA memory at $8000
    ; sprites are 16x16x4bpp, so 128 bytes per sprite
    const uword sprite_data_addr = $8000
    const uword sprite_size = 128
    
    sub Begin()
    {
        cx16.rambank(entities_bank)
    }

    sub End()
    {
        cx16.rambank(0)
    }

    sub Add(ubyte entity_index, uword xPos, uword yPos, ubyte ship_index, ubyte state, ubyte state_data)
    {
        uword curr_entity = entities + (entity_index as uword << 4)
        pokew(curr_entity + entity_x, xPos as uword)
        pokew(curr_entity + entity_y, yPos as uword)
        curr_entity[entity_sprite_index] = 0
        curr_entity[entity_sprite_setup] = 0
        curr_entity[entity_state] = state
        curr_entity[entity_state_data] = state_data
        curr_entity[entity_state_data + 1] = 0
        curr_entity[entity_state_data + 2] = 0
        curr_entity[entity_ship_index] = ship_index
    }

    sub SetSpriteIndex(ubyte entity_index, ubyte sprite_index)
    {
        uword curr_entity = entities + (entity_index as uword << 4)
        curr_entity[entity_sprite_index] = sprite_index
    }

    sub SetSpriteSetup(ubyte entity_index, ubyte sprite_setup)
    {
        uword curr_entity = entities + (entity_index as uword << 4)
        curr_entity[entity_sprite_setup] = sprite_setup
    }

    sub UpdatePosition(ubyte entity_index, word xPos, word yPos)
    {
        uword curr_entity = entities + (entity_index as uword << 4)
        
        word xPosA = peekw(curr_entity + entity_x) + xPos
        word yPosA = peekw(curr_entity + entity_y) + yPos

        ; wrap on screen edges (but allow sprites to move off edges before wrapping)
        if (xPosA > 639) xPosA -= 656
        if (xPosA < -16) xPosA += 656
        if (yPosA > 479) yPosA -= 496
        if (yPosA < -16) yPosA += 496

        pokew(curr_entity + entity_x, xPosA as uword)
        pokew(curr_entity + entity_y, yPosA as uword)
    }
    
    sub SetState(ubyte entity_index, ubyte state, ubyte state_data)
    {
        uword curr_entity = entities + (entity_index as uword << 4)
        curr_entity[entity_state] = state
        curr_entity[entity_state_data] = state_data
    }
    
    sub UpdateEntity(ubyte entity_index)
    {
        uword curr_entity = entities + (entity_index as uword << 4)

        if (curr_entity[entity_state] == state_onpath)
        {
            byte[5] pathEntry
            SpritePathTables.GetPathEntry(curr_entity[entity_state_data], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)
            UpdatePosition(entity_index, pathEntry[0] as word, pathEntry[1] as word)
            curr_entity[entity_sprite_index] = pathEntry[3] as ubyte
            curr_entity[entity_sprite_setup] = pathEntry[4] as ubyte
            
            if (curr_entity[entity_state_path_repeat] == 0)
            {
                curr_entity[entity_state_path_repeat] = pathEntry[2] as ubyte
            }
            curr_entity[entity_state_path_repeat]--
            if (curr_entity[entity_state_path_repeat] == 0)
            {
                curr_entity[entity_state_path_offset]++

                if (SpritePathTables.CheckEnd(curr_entity[entity_state_data], curr_entity[entity_state_path_offset]))
                {
                    curr_entity[entity_state_path_offset] = 0
                }
            }
        }
    }
    
    sub UpdateSprite(ubyte entity_index)
    {
        uword curr_entity = entities + (entity_index as uword << 4)

        ; sprites are 16x16, 8bpp, and between layer 0 and layer 1
        sprites.setup(entity_index, %00000101, %00001000, 0)
        uword xPos = peekw(curr_entity + entity_x)
        uword yPos = peekw(curr_entity + entity_y)
        sprites.position(entity_index, xPos, yPos)
        sprites.set_address(entity_index, 0, sprite_data_addr + (curr_entity[entity_sprite_index] as uword * sprite_size))
        sprites.flips(entity_index, curr_entity[entity_sprite_setup])
    }
}