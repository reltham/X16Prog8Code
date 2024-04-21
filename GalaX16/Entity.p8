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
    const ubyte entities_bank = 2
    const ubyte entity_x = 0
    const ubyte entity_y = 2
    const ubyte entity_sprite_index = 4
    const ubyte entity_sprite_setup = 5
    const ubyte entity_state = 6
    const ubyte entity_state_data = 7
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

    sub Add(ubyte entity_index, uword xPos, uword yPos, ubyte sprite_index, ubyte sprite_setup, ubyte state, ubyte state_data)
    {
        uword curr_entity = entities + (entity_index as uword << 3)
        pokew(curr_entity + entity_x, xPos as uword)
        pokew(curr_entity + entity_y, yPos as uword)
        curr_entity[entity_sprite_index] = sprite_index
        curr_entity[entity_sprite_setup] = sprite_setup
        curr_entity[entity_state] = state
        curr_entity[entity_state_data] = state_data
    }
    
    sub SetSpriteIndex(ubyte entity_index, ubyte sprite_index)
    {
        uword curr_entity = entities + (entity_index as uword << 3)
        curr_entity[entity_sprite_index] = sprite_index
    }

    sub SetSpriteSetup(ubyte entity_index, ubyte sprite_setup)
    {
        uword curr_entity = entities + (entity_index as uword << 3)
        curr_entity[entity_sprite_setup] = sprite_setup
    }

    sub UpdatePosition(ubyte entity_index, word xPos, word yPos)
    {
        uword curr_entity = entities + (entity_index as uword << 3)
        
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
        uword curr_entity = entities + (entity_index as uword << 3)
        curr_entity[entity_state] = state
        curr_entity[entity_state_data] = state_data
    }
    
    sub UpdateSprite(ubyte entity_index)
    {
        uword curr_entity = entities + (entity_index as uword << 3)

        ; sprites are 16x16, 8bpp, and between layer 0 and layer 1
        sprites.setup(entity_index, %00000101, %00001000, 0)
        uword xPos = peekw(curr_entity + entity_x)
        uword yPos = peekw(curr_entity + entity_y)
        sprites.position(entity_index, xPos, yPos)
        sprites.set_address(entity_index, 0, sprite_data_addr + (curr_entity[entity_sprite_index] as uword * sprite_size))
        sprites.flips(entity_index, curr_entity[entity_sprite_setup])
    }
}