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
    const ubyte entity_state_path_return = 12 ; 4 bytes to hold path indices/offsets for gosub/return stuff (can only nest 2 deep)

    const ubyte entities_bank = 2
    const uword entities = $a000

    const ubyte state_static = 0
    const ubyte state_formation = 1
    const ubyte state_onpath = 2

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
        curr_entity[entity_ship_index] = ship_index
        curr_entity[entity_state] = state
        curr_entity[entity_state_data] = state_data
        curr_entity[entity_state_data + 1] = 0
        curr_entity[entity_state_data + 2] = 0
        curr_entity[entity_state_data + 3] = -1
        curr_entity[entity_state_data + 4] = -1
        curr_entity[entity_state_data + 5] = -1
        curr_entity[entity_state_data + 6] = -1
        curr_entity[entity_state_data + 7] = -1
        
        ; sprites are 16x16, 8bpp, and between layer 0 and layer 1
        sprites.setup(entity_index, %00000101, %00001000, 0)
    }

    sub UpdatePosition(ubyte entity_index, word xPos, word yPos)
    {
        uword curr_entity = entities + (entity_index as uword << 4)
        
        word xPosA = peekw(curr_entity + entity_x) + xPos
        word yPosA = peekw(curr_entity + entity_y) + yPos

        ; wrap on screen edges (but allow sprites to move off edges before wrapping)
        if (xPosA > 639) xPosA -= 656
        else if (xPosA < -16) xPosA += 656
        if (yPosA > 479) yPosA -= 496
        else if (yPosA < -16) yPosA += 496

        pokew(curr_entity + entity_x, xPosA as uword)
        pokew(curr_entity + entity_y, yPosA as uword)
    }

    sub UpdateEntity(ubyte entity_index)
    {
        uword curr_entity = entities + (entity_index as uword << 4)

        if (curr_entity[entity_state] == state_onpath)
        {
            byte[7] pathEntry
            cx16.VERA_DC_BORDER = 4
            SpritePathTables.GetPathEntry(curr_entity[entity_state_path], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)
            cx16.VERA_DC_BORDER = 2 + entity_index % 2
            
            if (pathEntry[0] == 0)
            {
                if (pathEntry[1] == 0)
                {
                    curr_entity[entity_state_path_offset] = 0
                }
                else if (pathEntry[1] == 1)
                {
                    ; return from gosub
                    if (curr_entity[entity_state_path_return_index] == -1)
                    {
                        return
                    }
                    else
                    {
                        /*
                        ubyte currPath = curr_entity[entity_state_path]
                        ubyte currPathOffset = curr_entity[entity_state_path_offset]
                        ubyte returnPath = curr_entity[entity_state_path_return + (curr_entity[entity_state_path_return_index] * 2)]
                        ubyte returnPathOffset = curr_entity[entity_state_path_return + (curr_entity[entity_state_path_return_index] * 2) + 1]
                        End()
                        txt.print(iso:"R: ")
                        txt.print_ub(currPath)
                        txt.print(iso:", ")
                        txt.print_ub(currPathOffset)
                        txt.print(iso:" -> ")
                        txt.print_ub(returnPath)
                        txt.print(iso:", ")
                        txt.print_ub(returnPathOffset)
                        txt.nl()
                        Begin()
                        */                    
                        ubyte stackOffset = entity_state_path_return + (curr_entity[entity_state_path_return_index] * 2)
                        curr_entity[entity_state_path] = curr_entity[stackOffset]
                        curr_entity[stackOffset] = -1
                        curr_entity[entity_state_path_offset] = curr_entity[stackOffset + 1]
                        curr_entity[stackOffset + 1] = -1
                        curr_entity[entity_state_path_return_index]--
                        curr_entity[entity_state_path_repeat] = 0
                    }
                }
                cx16.VERA_DC_BORDER = 4
                SpritePathTables.GetPathEntry(curr_entity[entity_state_path], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)
                cx16.VERA_DC_BORDER = 2 + entity_index % 2
                if (pathEntry[0] == 0 and pathEntry[1] == 0)
                {
                    return
                }
            }
            else if (pathEntry[0] == 2)
            {
                ; gosub to path
                if (curr_entity[entity_state_path_return_index] == -1)
                {
                    curr_entity[entity_state_path_return_index] = 0
                }
                else
                {
                    curr_entity[entity_state_path_return_index]++
                }
                ubyte newPath = pathEntry[2] as ubyte
                /*
                if (pathEntry[1] == 1)
                {
                    ; pick one randomly from pathEntry[2], pathEntry[3], pathEntry[4]
                }
                */
                /*
                ubyte currPathx = curr_entity[entity_state_path]
                ubyte currPathOffsetx = curr_entity[entity_state_path_offset]
                End()
                txt.print(iso:"G: ")
                txt.print_ub(currPathx)
                txt.print(iso:", ")
                txt.print_ub(currPathOffsetx)
                txt.print(iso:" -> ")
                txt.print_ub(newPath)
                txt.print(iso:", 0")
                txt.nl()
                Begin()                    
                */

                ; store the return info
                ubyte stackOffsetx = entity_state_path_return + (curr_entity[entity_state_path_return_index] * 2)
                curr_entity[stackOffsetx] = curr_entity[entity_state_path]
                curr_entity[stackOffsetx + 1] = curr_entity[entity_state_path_offset] + 1
                ; set new path
                curr_entity[entity_state_path] = newPath
                curr_entity[entity_state_path_offset] = 0

                cx16.VERA_DC_BORDER = 4
                SpritePathTables.GetPathEntry(curr_entity[entity_state_path], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)
                cx16.VERA_DC_BORDER = 2 + entity_index % 2
            }

            UpdatePosition(entity_index, pathEntry[2] as word, pathEntry[3] as word)
            curr_entity[entity_sprite_index] = pathEntry[5] as ubyte
            curr_entity[entity_sprite_setup] = pathEntry[6] as ubyte
            
            if (curr_entity[entity_state_path_repeat] == 0)
            {
                curr_entity[entity_state_path_repeat] = pathEntry[1] as ubyte
            }
            curr_entity[entity_state_path_repeat]--
            if (curr_entity[entity_state_path_repeat] == 0)
            {
                curr_entity[entity_state_path_offset]++
            }
        }
    }
    
    sub UpdateSprite(ubyte entity_index)
    {
        uword curr_entity = entities + (entity_index as uword << 4)

        uword xPos = peekw(curr_entity + entity_x)
        uword yPos = peekw(curr_entity + entity_y)
        sprites.update(entity_index, curr_entity[entity_sprite_index], xPos, yPos, curr_entity[entity_sprite_setup])
    }
}