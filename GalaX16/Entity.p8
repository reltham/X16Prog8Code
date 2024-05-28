Entity
{
    ; entities are 32 bytes each
    const ubyte entity_x = 0
    const ubyte entity_y = 2
    const ubyte entity_sprite_index = 4
    const ubyte entity_sprite_setup = 5
    const ubyte entity_ship_index = 6
    const ubyte entity_state = 7
    const ubyte entity_state_data = 8 ; state data size varies by type, max of 12 bytes

    ; when state is static state data is not used

    ; when state is onpath state data is as follows
    const ubyte entity_state_path = 8
    const ubyte entity_state_path_offset = 9
    const ubyte entity_state_path_repeat = 10
    const ubyte entity_state_path_return_index = 11
    const ubyte entity_state_path_return = 12 ; 8 bytes to hold path indices/offsets for gosub/return stuff (can only nest 4 deep)

    ; when state is formation state data is as follows
    const ubyte entity_state_formation_state = 8

    ; next state defaults to none (0) meaning the entity terminates at end of path
    const ubyte entity_state_next_state = 20        ; this state will be set when the path the entity is on ends
    const ubyte entity_state_next_state_data = 21   ; state data size varies by type, max of 11 bytes


    const ubyte state_none = 0
    const ubyte state_player = 1
    const ubyte state_static = 2
    const ubyte state_onpath = 3
    const ubyte state_formation = 4
    const ubyte state_player_bullet = 5
    const ubyte state_enemy_bullet = 6
    const ubyte state_start_explosion = 7
    const ubyte state_explosion = 8

    const ubyte formation_state_init = 1
    const ubyte formation_state_fly_to = 2
    const ubyte formation_state_in_slot = 3
    
    ; only the first 4 ships have formation anims
    ubyte[] ship_sprite_formation_anims = [  0,  1,
                                            16, 17,
                                            48, 49,
                                            80, 81 ]


    const ubyte entities_bank = 2
    const uword entities = $a000

    ubyte num_active_enemies = 0
    ubyte num_bullets = 0
    uword[12] bullet_x = 0
    uword[12] bullet_y = 0
    ubyte[12] bullet_entity_index = 0

    bool enable_formation_moving = false
    byte formation_offset_update = 0
    word curr_formation_x_offset = 0
    byte curr_formation_y_offset = 0
    byte formation_direction_x = 1
    byte formation_direction_y = 1
    
    bool enemy_diving = false
    ubyte enemy_diving_index = 0
    ubyte enemy_diving_formation_slot = 0
    
    ; this changes each time you clear a level to make it more likely an enemy will dive 
    ubyte random_chance = 250

    sub ResetFormationMotion()
    {
        enable_formation_moving = false
        formation_offset_update = 0
        curr_formation_x_offset = 0
        curr_formation_y_offset = 0
        formation_direction_x = 1
        formation_direction_y = 1
    }
    
    sub CheckBulletHits(uword test_entity_x, uword test_entity_y) -> bool
    {
        if (num_bullets > 0)
        {
            ubyte bullet
            for bullet in 0 to num_bullets-1
            {
                uword dx = math.diffw(bullet_x[bullet], test_entity_x)
                if (dx < 12)
                {
                    uword dy = math.diffw(bullet_y[bullet], test_entity_y)
                    if (dy < 16)
                    {
                        uword @zp curr_bullet_entity = entities + (bullet_entity_index[bullet] as uword << 5)
                        curr_bullet_entity[entity_state] = state_none
                        pokew(curr_bullet_entity + entity_y, -16 as uword)
                        UpdateSprites(bullet_entity_index[bullet], 1)
                        num_bullets--
                        return true
                    }
                }
            }
        }
        return false
    }
    
    sub AddPlayerBullet(ubyte num_entities)
    {
        if (num_bullets < 1)
        {
            Sounds.PlaySFX(3)
            Begin()
            Add(num_entities + num_bullets, InputHandler.player_offset, 350, GameData.sprite_indices[GameData.player_bullet], state_player_bullet, 0)
            End()
        }
    }

    sub Begin()
    {
        cx16.rambank(entities_bank)
    }

    sub End()
    {
        cx16.rambank(0)
    }

    sub Add(ubyte entityIndex, uword xPos, uword yPos, ubyte shipIndex, ubyte state, ubyte stateData)
    {
        uword @zp curr_entity = entities + (entityIndex as uword << 5)
        pokew(curr_entity + entity_x, xPos as uword)
        pokew(curr_entity + entity_y, yPos as uword)
        if (state == state_onpath or state == state_formation or state == state_player)
        {
            curr_entity[entity_sprite_index] = SpritePathTables.GetSpriteOffset(shipIndex)
            curr_entity[entity_ship_index] = shipIndex
            if (state != state_player)
            {
                num_active_enemies++
            }
        }
        else
        {
            curr_entity[entity_sprite_index] = shipIndex
            curr_entity[entity_ship_index] = -1
        }
        curr_entity[entity_sprite_setup] = 0
        curr_entity[entity_state] = state
        curr_entity[entity_state_data] = stateData
        curr_entity[entity_state_data + 1] = 0
        curr_entity[entity_state_data + 2] = 0
        ubyte i
        for i in 3 to 11
        {
            curr_entity[entity_state_data + i] = -1
        }
        curr_entity[entity_state_next_state] = 0
        curr_entity[entity_state_next_state_data] = 0
        for i in 1 to 10
        {
            curr_entity[entity_state_next_state_data + i] = -1
        }

        if (state == state_player_bullet and num_bullets < 16)
        {
            bullet_entity_index[num_bullets] = entityIndex
            ; these are offset because the bullet image is in the middle of the sprite image
            bullet_x[num_bullets] = xPos + 6
            bullet_y[num_bullets] = yPos - 4
            curr_entity[entity_state_data] = num_bullets
            num_bullets++
        }

        ; move sprite off screen, first update will put it where it goes
        sprites.position(entityIndex, 0, -17 as uword)
        ; sprites are 16x16, 8bpp, and between layer 0 and layer 1
        sprites.setup(entityIndex, %00000101, %00001000, 0)
    }

    sub SetNextState(ubyte entityIndex, ubyte nextState, ubyte nextStateData, ubyte nextStateData2)
    {
        uword @zp curr_entity = entities + (entityIndex as uword << 5)
        curr_entity[entity_state_next_state] = nextState
        curr_entity[entity_state_next_state_data] = nextStateData
        curr_entity[entity_state_next_state_data + 1] = nextStateData2
    }

    sub SetPosition(ubyte entityIndex, uword xPos, uword yPos, bool bIntoNextStateData)
    {
        uword @zp curr_entity = entities + (entityIndex as uword << 5)
        if (bIntoNextStateData == true)
        {
            pokew(curr_entity + entity_state_next_state_data + 2, xPos)
            pokew(curr_entity + entity_state_next_state_data + 4, yPos)
        }
        else
        {
            pokew(curr_entity + entity_x, xPos)
            pokew(curr_entity + entity_y, yPos)
        }
    }

    sub UpdatePosition(ubyte entityIndex, word xPos, word yPos)
    {
        uword @zp curr_entity = entities + (entityIndex as uword << 5)
        
        word xPosA = peekw(curr_entity + entity_x) + xPos
        word yPosA = peekw(curr_entity + entity_y) + yPos

        ; wrap on screen edges (but allow sprites to move off edges before wrapping)
        if (msb(xPosA) != 0)
        {
            if (xPosA > 511) xPosA -= 528
            else if (xPosA < -16) xPosA += 528
        }
        if (msb(yPosA) != 0)
        {
            if (yPosA > 399) yPosA -= 416
            else if (yPosA < -16) yPosA += 416
        }

        pokew(curr_entity + entity_x, xPosA as uword)
        pokew(curr_entity + entity_y, yPosA as uword)
    }

    sub UpdateEntity(ubyte entityIndex) -> bool
    {
        if (enable_formation_moving == true and entityIndex == 32)
        {
            if (formation_offset_update == 0)
            {
                if (curr_formation_x_offset > 128) formation_direction_x = -1
                if (curr_formation_x_offset < -128) formation_direction_x = 1
                curr_formation_x_offset += formation_direction_x
    
                if (curr_formation_y_offset > 32) formation_direction_y = -1
                if (curr_formation_y_offset < -16) formation_direction_y = 1
                curr_formation_y_offset += formation_direction_y
                formation_offset_update = 2
            }
            else
            {
                formation_offset_update--
            } 
        }

        uword @zp curr_entity = entities + (entityIndex as uword << 5)

        if (curr_entity[entity_state] == state_static)
        {
            return false
        }
        else if (curr_entity[entity_state] == state_player)
        {
            pokew(curr_entity + entity_x, InputHandler.player_offset)
            return false
        }
        else if (curr_entity[entity_state] == state_start_explosion)
        {
            Sounds.PlaySFX(2)
            curr_entity[entity_sprite_index] = GameData.sprite_indices[GameData.enemy_explosion_start]
            curr_entity[entity_ship_index] = -1
            curr_entity[entity_state] = state_explosion
            curr_entity[entity_state_data] = 0
            return false
        }
        else if (curr_entity[entity_state] == state_explosion)
        {
            if (curr_entity[entity_state_data] < 2)
            {
                curr_entity[entity_sprite_index]++
                curr_entity[entity_state_data]++
            }
            else
            {
                pokew(curr_entity + entity_y, -17 as uword)
                curr_entity[entity_state] = state_none
                num_active_enemies--
                if (num_active_enemies == 0)
                {
                    main.EnemiesCleared()
                }
            }
            return false
        }
        else if (curr_entity[entity_state] == state_player_bullet)
        {
            word curr_bullet_y = peekw(curr_entity + entity_y) as word
            curr_bullet_y -= 8
            pokew(curr_entity + entity_y, curr_bullet_y as uword)
            bullet_y[curr_entity[entity_state_data]] = curr_bullet_y as uword
            if (curr_bullet_y < -16)
            {
                curr_entity[entity_state] = state_none
                pokew(curr_entity + entity_y, -16 as uword)
                UpdateSprites(entityIndex, 1)
                num_bullets--
            }
            return false
        }
        else if (curr_entity[entity_state] == state_formation)
        {
            if (curr_entity[entity_state_data] == formation_state_init)
            {
                word curr_x = peekw(curr_entity + entity_x) as word
                word curr_y = peekw(curr_entity + entity_y) as word
                word target_x = peekw(curr_entity + entity_state_data + 2) as word + curr_formation_x_offset
                word target_y = peekw(curr_entity + entity_state_data + 4) as word + curr_formation_y_offset
                word diff_x = (target_x - curr_x)
                word diff_y = (target_y - curr_y)
                if (diff_y > -130)
                {
                    curr_entity[entity_state_data + 6] = (diff_x / 16) as ubyte
                    curr_entity[entity_state_data + 7] = (diff_y / 16) as ubyte
                    curr_entity[entity_state_data + 8] = 16
                }
                else
                {
                    curr_entity[entity_state_data + 6] = (diff_x / 24) as ubyte
                    curr_entity[entity_state_data + 7] = (diff_y / 24) as ubyte
                    curr_entity[entity_state_data + 8] = 24
                }
                ubyte direction = 24 - ((math.direction_sc(0, 0, curr_entity[entity_state_data + 6] as byte, curr_entity[entity_state_data + 7] as byte) + 18) % 24)

                ; set sprite image index and flips
                uword sprite_info = SpritePathTables.GetSpriteRotationInfo(curr_entity[entity_ship_index], direction)
                curr_entity[entity_sprite_index] = msb(sprite_info)
                curr_entity[entity_sprite_setup] = lsb(sprite_info)

                ; do first step
                curr_x += curr_entity[entity_state_data + 6] as byte
                curr_y += curr_entity[entity_state_data + 7] as byte
                pokew(curr_entity + entity_x, curr_x as uword)
                pokew(curr_entity + entity_y, curr_y as uword)
                
                curr_entity[entity_state_data] = formation_state_fly_to
            }
            else if (curr_entity[entity_state_data] == formation_state_fly_to)
            {
                curr_x = peekw(curr_entity + entity_x) as word
                curr_y = peekw(curr_entity + entity_y) as word
                curr_x += curr_entity[entity_state_data + 6] as byte
                curr_y += curr_entity[entity_state_data + 7] as byte
                curr_entity[entity_state_data + 8]--
                if (curr_entity[entity_state_data + 8] == 0)
                {
                    curr_x = peekw(curr_entity + entity_state_data + 2) as word 
                    curr_y = peekw(curr_entity + entity_state_data + 4) as word
                    curr_entity[entity_state_data] = formation_state_in_slot
                }
                pokew(curr_entity + entity_x, curr_x as uword)
                pokew(curr_entity + entity_y, curr_y as uword)
                sprite_info = SpritePathTables.GetSpriteRotationInfo(curr_entity[entity_ship_index], 0)
                curr_entity[entity_sprite_index] = msb(sprite_info)
                curr_entity[entity_sprite_setup] = lsb(sprite_info)
            }
            else if (curr_entity[entity_state_data] == formation_state_in_slot)
            {
                if (formation_offset_update == 2)
                {        
                    target_x = peekw(curr_entity + entity_state_data + 2) as word 
                    target_y = peekw(curr_entity + entity_state_data + 4) as word
                    curr_x = target_x + curr_formation_x_offset
                    curr_y = target_y + curr_formation_y_offset
                    pokew(curr_entity + entity_x, curr_x as uword)
                    pokew(curr_entity + entity_y, curr_y as uword)
                    
                    ubyte random_value = math.rnd()
                    if (enemy_diving == false and random_value > random_chance)
                    {
                        random_value = math.rnd()
                        if (random_value < 16)
                        {
                            ubyte saved_formation_slot = curr_entity[entity_state_data + 1]

                            curr_entity[entity_state] = state_onpath
                            curr_entity[entity_state_data] = random_value >> 2
                            curr_entity[entity_state_data + 1] = 0
                            curr_entity[entity_state_data + 2] = 0
                            for i in 3 to 23
                            {
                                curr_entity[entity_state_data + i] = -1
                            }
                            SetNextState(entityIndex, state_formation, formation_state_init, saved_formation_slot)
                            Sequencer.SetEntityFormationPosition(entityIndex, saved_formation_slot, true)
                            enemy_diving_index = entityIndex
                            enemy_diving = true
                            Sounds.PlaySFX(6)
                            return true
                        }
                    }
                    else if (entityIndex == enemy_diving_index)
                    {
                        enemy_diving = false
                    }
                }
            }

            uword test_x = peekw(curr_entity + entity_x) + 8
            uword test_y = peekw(curr_entity + entity_y)
            if (CheckBulletHits(test_x, test_y))
            {
                curr_entity[entity_state] = state_start_explosion
                main.ScoreHit(curr_entity[entity_ship_index])
                if (entityIndex == enemy_diving_index)
                {
                    enemy_diving = false
                }
            }
            return false
        }
        else if (curr_entity[entity_state] == state_onpath)
        {
            byte[7] pathEntry
            ;cx16.VERA_DC_BORDER = 4
            SpritePathTables.GetPathEntry(curr_entity[entity_state_path], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)
            ;cx16.VERA_DC_BORDER = 2

            if (pathEntry[0] == 0)
            {
                if (pathEntry[1] == 0)
                {
                    curr_entity[entity_state] = curr_entity[entity_state_next_state]
                    curr_entity[entity_state_data] = curr_entity[entity_state_next_state_data]
                    curr_entity[entity_state_data + 1] = curr_entity[entity_state_next_state_data + 1]
                    if (curr_entity[entity_state_next_state] != state_none)
                    {
                        ubyte i
                        for i in 2 to 10
                        {
                            curr_entity[entity_state_data + i] = curr_entity[entity_state_next_state_data + i]
                        }
                        curr_entity[entity_state_data + 11] = -1
                    }
                    ;curr_entity[entity_state_path_offset] = 0
                }
                else
                {
                    ; return from gosub
                    if (curr_entity[entity_state_path_return_index] != -1)
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
                        ;curr_entity[entity_state_path_repeat] = 0
                    }
                }
                return true
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
                ubyte newPath = pathEntry[1] as ubyte
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

                return true
            }

            UpdatePosition(entityIndex, pathEntry[2] as word, pathEntry[3] as word)
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

            test_x = peekw(curr_entity + entity_x) + 8
            test_y = peekw(curr_entity + entity_y)
            if (CheckBulletHits(test_x, test_y))
            {
                curr_entity[entity_state] = state_start_explosion
                main.ScoreHit(curr_entity[entity_ship_index])
                if (entityIndex == enemy_diving_index)
                {
                    enemy_diving = false
                }
            }
        }
        return false
    }
    
    sub UpdateSprites(ubyte startIndex, ubyte numSprites)
    {
        uword @zp curr_entity = entities + (startIndex as uword << 5)

        cx16.r0 = $fc00 + (startIndex as uword * 8)
        repeat numSprites
        {
            cx16.r1 = ($400 + (curr_entity[entity_sprite_index] as uword * 4)) ; calc sprite vera address, but already shifted down 5 (since we only need upper 11 bits) 
            cx16.r2 = peekw(curr_entity + entity_x)
            cx16.r3 = peekw(curr_entity + entity_y)
            sprites.updateEx(curr_entity[entity_sprite_setup])
            curr_entity += 32
            cx16.r0 += 8
        }
    }
}