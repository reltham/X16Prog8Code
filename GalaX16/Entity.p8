Entity
{
    const uword entities_addr = $A000

    ; entities are 32 bytes each
    const ubyte entity_sprite_slot = 0
    ;const ubyte entity_   1-5 free
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

    ubyte bullet_entities_start = 0
    ubyte num_active_enemies = 0
    ubyte num_player_bullets = 0
    ubyte num_enemy_bullets = 0
    const ubyte start_enemy_bullets =2
    uword[12] bullet_x = 0
    uword[12] bullet_y = 0
    ubyte[12] bullet_entity_index = 0

    bool enable_formation_moving = false
    byte formation_offset_update = 0
    word curr_formation_x_offset = 0
    byte curr_formation_y_offset = 0
    byte formation_direction_x = 1
    byte formation_direction_y = 1
    
    bool enable_enemy_diving = false
    bool enemy_diving = false
    ubyte enemy_diving_index = 0
    ubyte enemy_diving_formation_slot = 0
    ubyte enemy_bullet_fired = 0
    
    ; this changes each time you clear a level to make it more likely an enemy will dive 
    ubyte random_chance = 250

    sub SetBulletEntitiesStart(ubyte newStart)
    {
        bullet_entities_start = newStart
    }

    sub ResetFormationMotion()
    {
        enable_formation_moving = false
        formation_offset_update = 0
        curr_formation_x_offset = 0
        curr_formation_y_offset = 0
        formation_direction_x = 1
        formation_direction_y = 1
        enable_enemy_diving = false
    }
    
    sub RemovePlayerBullet(ubyte bullet)
    {
        if (bullet == 0 and num_player_bullets > 1)
        {
            uword @zp this_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
            uword @zp next_bullet_entity = entities_addr + (bullet_entity_index[bullet+1] as uword << 5)
            ubyte i
            for i in 1 to 31
            {
                this_bullet_entity[i] = next_bullet_entity[i]
            }
            this_bullet_entity[entity_state_data] = bullet
            sprites.SetPosition(this_bullet_entity[entity_sprite_slot], sprites.GetX(next_bullet_entity[entity_sprite_slot]) as uword, sprites.GetY(next_bullet_entity[entity_sprite_slot]) as uword)
            next_bullet_entity[entity_state] = state_none
            sprites.SetY(next_bullet_entity[entity_sprite_slot], -33 as uword)
            bullet_x[bullet] = bullet_x[bullet+1]
            bullet_y[bullet] = bullet_y[bullet+1]
        }
        else
        {
            uword @zp curr_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
            curr_bullet_entity[entity_state] = state_none
            sprites.SetY(curr_bullet_entity[entity_sprite_slot], -33 as uword)
        }
    }

    sub RemoveEnemyBullet(ubyte bullet)
    {
        if (bullet == start_enemy_bullets and num_enemy_bullets > 1)
        {
            uword @zp this_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
            uword @zp next_bullet_entity = entities_addr + (bullet_entity_index[bullet+1] as uword << 5)
            ubyte i
            for i in 1 to 31
            {
                this_bullet_entity[i] = next_bullet_entity[i]
            }
            this_bullet_entity[entity_state_data] = bullet
            sprites.SetPosition(this_bullet_entity[entity_sprite_slot], sprites.GetX(next_bullet_entity[entity_sprite_slot]) as uword, sprites.GetY(next_bullet_entity[entity_sprite_slot]) as uword)
            next_bullet_entity[entity_state] = state_none
            sprites.SetY(next_bullet_entity[entity_sprite_slot], -33 as uword)
            bullet_x[bullet] = bullet_x[bullet+1]
            bullet_y[bullet] = bullet_y[bullet+1]
        }
        else
        {
            uword @zp curr_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
            curr_bullet_entity[entity_state] = state_none
            sprites.SetY(curr_bullet_entity[entity_sprite_slot], -33 as uword)
        }
    }

    sub CheckPlayerBulletHits(uword test_entity_x, uword test_entity_y) -> bool
    {
        if (num_player_bullets > 0)
        {
            ubyte bullet
            for bullet in 0 to num_player_bullets-1
            {
                uword dx = math.diffw(bullet_x[bullet], test_entity_x)
                if (dx < 12)
                {
                    uword dy = math.diffw(bullet_y[bullet], test_entity_y)
                    if (dy < 16)
                    {
                        RemovePlayerBullet(bullet)
                        num_player_bullets--
                        return true
                    }
                }
            }
        }
        return false
    }
    
    sub CheckEnemyPlayerHit(ubyte playerEntityIndex) -> bool
    {
        uword @zp curr_enemy_entity = entities_addr + (enemy_diving_index as uword << 5)
        uword test_enemy_y = sprites.GetY(curr_enemy_entity[entity_sprite_slot]) as uword

        uword @zp curr_player_entity = entities_addr + (playerEntityIndex as uword << 5)
        uword test_player_y = sprites.GetY(curr_player_entity[entity_sprite_slot]) as uword

        uword dy = math.diffw(test_enemy_y, test_player_y)
        if (dy < 16)
        {
            uword test_enemy_x = sprites.GetX(curr_enemy_entity[entity_sprite_slot]) as uword + 8
            uword test_player_x = sprites.GetX(curr_player_entity[entity_sprite_slot]) as uword + 8
            uword dx = math.diffw(test_enemy_x, test_player_x)
            if (dx <= 8)
            {
                return true
            }
        }
        return false
    }
    
    sub CheckEnemyBulletHit(uword test_entity_x, uword test_entity_y) -> bool
    {
        if (num_enemy_bullets > 0)
        {
            ubyte bullet
            for bullet in start_enemy_bullets to start_enemy_bullets + num_enemy_bullets - 1
            {
                uword dx = math.diffw(bullet_x[bullet], test_entity_x)
                if (dx < 12)
                {
                    uword dy = math.diffw(bullet_y[bullet], test_entity_y)
                    if (dy < 16)
                    {
                        RemoveEnemyBullet(bullet)
                        num_enemy_bullets--
                        return true
                    }
                }
            }
        }
        return false
    }
    
    sub AddPlayerBullet()
    {
        if (num_player_bullets < 2)
        {
            Sounds.PlaySFX(4)
            GameData.Begin()
            Add(bullet_entities_start + num_player_bullets, InputHandler.player_offset, 350, GameData.player_bullet, state_player_bullet, 0)
            GameData.End()
        }
    }

    sub AddEnemyBullet(uword enemy_x, uword enemy_y, ubyte dx)
    {
        if (num_enemy_bullets < 2)
        {
            Sounds.PlaySFX(1)
            GameData.Begin()
            Add(bullet_entities_start + start_enemy_bullets + num_enemy_bullets, enemy_x - 4, enemy_y + 8, GameData.enemy_bullet, state_enemy_bullet, dx)
            GameData.End()
        }
    }

    sub Add(ubyte entityIndex, uword xPos, uword yPos, ubyte shipIndex, ubyte state, ubyte stateData)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)

        sprites.SetPosition(curr_entity[entity_sprite_slot], xPos as uword, yPos as uword)

        if (state == state_onpath or state == state_formation) ; or state == state_player)
        {
            sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.GetShipSpriteOffset(shipIndex))
            sprites.SetPaletteOffset(curr_entity[entity_sprite_slot], GameData.GetShipSpritePalette(shipIndex))
            curr_entity[entity_ship_index] = shipIndex
            if (state != state_player)
            {
                num_active_enemies++
            }
        }
        else
        {
            sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.sprite_indices[shipIndex])
            sprites.SetPaletteOffset(curr_entity[entity_sprite_slot], GameData.sprite_palettes[shipIndex])
            curr_entity[entity_ship_index] = -1
        }
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

        if (state == state_player_bullet and num_player_bullets < 2)
        {
            bullet_entity_index[num_player_bullets] = entityIndex
            ; these are offset because the bullet image is in the middle of the sprite image
            bullet_x[num_player_bullets] = xPos + 6
            bullet_y[num_player_bullets] = yPos - 4
            curr_entity[entity_state_data] = num_player_bullets
            num_player_bullets++
        }
        if (state == state_enemy_bullet and num_enemy_bullets < 2)
        {
            ubyte bullet_index = start_enemy_bullets + num_enemy_bullets
            bullet_entity_index[bullet_index] = entityIndex
            ; these are offset because the bullet image is in the middle of the sprite image
            bullet_x[bullet_index] = xPos + 6
            bullet_y[bullet_index] = yPos - 4
            curr_entity[entity_state_data] = bullet_index
            curr_entity[entity_state_data + 1] = stateData
            num_enemy_bullets++
        }
    }

    sub SetNextState(ubyte entityIndex, ubyte nextState, ubyte nextStateData, ubyte nextStateData2)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)
        curr_entity[entity_state_next_state] = nextState
        curr_entity[entity_state_next_state_data] = nextStateData
        curr_entity[entity_state_next_state_data + 1] = nextStateData2
    }

    sub SetPosition(ubyte entityIndex, uword xPos, uword yPos)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)
        pokew(curr_entity + entity_state_next_state_data + 2, xPos)
        pokew(curr_entity + entity_state_next_state_data + 4, yPos)
    }

    sub UpdateSpriteSlot(ubyte entityIndex, word xPos, word yPos, ubyte spriteIndex, ubyte spriteFlips)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)

        word xPosA = sprites.GetX(curr_entity[entity_sprite_slot]) + xPos
        word yPosA = sprites.GetY(curr_entity[entity_sprite_slot]) + yPos

        ; wrap on screen edges (but allow sprites to move off edges before wrapping)
        if (msb(xPosA) != 0)
        {
            if (xPosA > 511) xPosA -= 544
            else if (xPosA < -32) xPosA += 544
        }
        if (msb(yPosA) != 0)
        {
            if (yPosA > 399) yPosA -= 432
            else if (yPosA < -326) yPosA += 432
        }

        sprites.SetPosAddrFlips(curr_entity[entity_sprite_slot], xPosA as uword, yPosA as uword, spriteIndex, spriteFlips) 
    }

    sub UpdateEntity(ubyte entityIndex) -> bool
    {
        if (enable_formation_moving == true and entityIndex == 32)
        {
            if (formation_offset_update == 0)
            {
                if (curr_formation_x_offset > 64) formation_direction_x = -1
                if (curr_formation_x_offset < -64) formation_direction_x = 1
                curr_formation_x_offset += formation_direction_x
    
                if (curr_formation_y_offset > 20) formation_direction_y = -1
                if (curr_formation_y_offset < -10) formation_direction_y = 1
                curr_formation_y_offset += formation_direction_y
                formation_offset_update = 2
            }
            else
            {
                formation_offset_update--
            } 
        }

        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)

        if (curr_entity[entity_state] == state_static)
        {
            return false
        }
        else if (curr_entity[entity_state] == state_player)
        {
            sprites.SetX(curr_entity[entity_sprite_slot], InputHandler.player_offset)
            bool kill_player = false
            if (enemy_diving == true)
            {
                if (CheckEnemyPlayerHit(entityIndex) == true)
                {
                    uword @zp diving_enemy_entity = entities_addr + (enemy_diving_index as uword << 5)
                    diving_enemy_entity[entity_state] = state_start_explosion
                    diving_enemy_entity[entity_state_data + 1] = 1
                    enemy_diving = false
                    kill_player = true
                }
            }
            if (kill_player == false and num_enemy_bullets > 0)
            {
                uword player_x = sprites.GetX(curr_entity[entity_sprite_slot]) as uword
                uword player_y = sprites.GetY(curr_entity[entity_sprite_slot]) as uword
                if (CheckEnemyBulletHit(player_x, player_y) == true)
                {
                    kill_player = true
                }
            }
            if (kill_player == true)
            {
                curr_entity[entity_state] = state_start_explosion
                curr_entity[entity_state_data + 1] = 0
                main.PlayerDied()
                enable_enemy_diving = false
                return true
            }
            return false
        }
        else if (curr_entity[entity_state] == state_start_explosion)
        {
            Sounds.PlaySFX(2)
            sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.sprite_indices[GameData.enemy_explosion_start])
            sprites.SetPaletteOffset(curr_entity[entity_sprite_slot], GameData.sprite_palettes[GameData.enemy_explosion_start])
            curr_entity[entity_ship_index] = -1
            curr_entity[entity_state] = state_explosion
            curr_entity[entity_state_data] = 1
            return false
        }
        else if (curr_entity[entity_state] == state_explosion)
        {
            if (curr_entity[entity_state_data] < 5)
            {
                sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.sprite_indices[GameData.enemy_explosion_start] + curr_entity[entity_state_data])
                curr_entity[entity_state_data]++
            }
            else
            {
                sprites.SetY(curr_entity[entity_sprite_slot], -33 as uword)
                curr_entity[entity_state] = state_none
                if (curr_entity[entity_state_data + 1] > 0)
                {
                    num_active_enemies--
                    if (num_active_enemies == 0 and enable_formation_moving == true)
                    {
                        main.EnemiesCleared()
                    }
                }
            }
            return false
        }
        else if (curr_entity[entity_state] == state_player_bullet)
        {
            word curr_player_bullet_y = sprites.GetY(curr_entity[entity_sprite_slot])
            curr_player_bullet_y -= 8
            sprites.SetY(curr_entity[entity_sprite_slot], curr_player_bullet_y as uword)
            bullet_y[curr_entity[entity_state_data]] = curr_player_bullet_y as uword
            if (curr_player_bullet_y < -32)
            {
                RemovePlayerBullet(curr_entity[entity_state_data])
                num_player_bullets--
            }
            return false
        }
        else if (curr_entity[entity_state] == state_enemy_bullet)
        {
            word curr_bullet_x = sprites.GetX(curr_entity[entity_sprite_slot])
            word curr_bullet_y = sprites.GetY(curr_entity[entity_sprite_slot])
            curr_bullet_y += 4
            curr_bullet_x += curr_entity[entity_state_data + 1] as byte
            sprites.SetPosition(curr_entity[entity_sprite_slot], curr_bullet_x as uword, curr_bullet_y as uword)
            bullet_x[curr_entity[entity_state_data]] = curr_bullet_x as uword
            bullet_y[curr_entity[entity_state_data]] = curr_bullet_y as uword
            if (curr_bullet_y > 400)
            {
                RemoveEnemyBullet(curr_entity[entity_state_data])
                num_enemy_bullets--
            }
            return false
        }
        else if (curr_entity[entity_state] == state_formation)
        {
            if (curr_entity[entity_state_data] == formation_state_init)
            {
                word curr_x = sprites.GetX(curr_entity[entity_sprite_slot])
                word curr_y = sprites.GetY(curr_entity[entity_sprite_slot])
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
                uword sprite_info = GameData.GetSpriteRotationInfo(curr_entity[entity_ship_index], direction)
                sprites.SetAddress(curr_entity[entity_sprite_slot], msb(sprite_info))
                sprites.SetFlips(curr_entity[entity_sprite_slot], lsb(sprite_info))

                ; do first step
                curr_x += curr_entity[entity_state_data + 6] as byte
                curr_y += curr_entity[entity_state_data + 7] as byte
                sprites.SetPosition(curr_entity[entity_sprite_slot], curr_x as uword, curr_y as uword)

                curr_entity[entity_state_data] = formation_state_fly_to
            }
            else if (curr_entity[entity_state_data] == formation_state_fly_to)
            {
                curr_x = sprites.GetX(curr_entity[entity_sprite_slot])
                curr_y = sprites.GetY(curr_entity[entity_sprite_slot])
                curr_x += curr_entity[entity_state_data + 6] as byte
                curr_y += curr_entity[entity_state_data + 7] as byte
                curr_entity[entity_state_data + 8]--
                if (curr_entity[entity_state_data + 8] == 0)
                {
                    curr_x = peekw(curr_entity + entity_state_data + 2) as word 
                    curr_y = peekw(curr_entity + entity_state_data + 4) as word
                    curr_entity[entity_state_data] = formation_state_in_slot
                }
                sprites.SetPosition(curr_entity[entity_sprite_slot], curr_x as uword, curr_y as uword)
                sprite_info = GameData.GetSpriteRotationInfo(curr_entity[entity_ship_index], 0)
                sprites.SetAddress(curr_entity[entity_sprite_slot], msb(sprite_info))
                sprites.SetFlips(curr_entity[entity_sprite_slot], lsb(sprite_info))
            }
            else if (curr_entity[entity_state_data] == formation_state_in_slot)
            {
                if (formation_offset_update == 2)
                {        
                    target_x = peekw(curr_entity + entity_state_data + 2) as word 
                    target_y = peekw(curr_entity + entity_state_data + 4) as word
                    curr_x = target_x + curr_formation_x_offset
                    curr_y = target_y + curr_formation_y_offset
                    sprites.SetPosition(curr_entity[entity_sprite_slot], curr_x as uword, curr_y as uword)
                }
                if (enable_enemy_diving == true)
                {
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
                            Sequencer.SetEntityFormationPosition(entityIndex, saved_formation_slot)
                            enemy_diving_index = entityIndex
                            enemy_diving = true
                            enemy_bullet_fired = 30
                            Sounds.PlaySFX(3)
                            return true
                        }
                    }
                }
                if (entityIndex == enemy_diving_index)
                {
                    enemy_diving = false
                }
            }

            uword test_x = sprites.GetX(curr_entity[entity_sprite_slot]) as uword + 8
            uword test_y = sprites.GetY(curr_entity[entity_sprite_slot]) as uword
            if (CheckPlayerBulletHits(test_x, test_y))
            {
                curr_entity[entity_state] = state_start_explosion
                curr_entity[entity_state_data + 1] = 1
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
            SpritePathTables.GetPathEntry(curr_entity[entity_state_path], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)

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
                }
                else
                {
                    ; return from gosub
                    if (curr_entity[entity_state_path_return_index] != -1)
                    {
                        ubyte stackOffset = entity_state_path_return + (curr_entity[entity_state_path_return_index] * 2)
                        curr_entity[entity_state_path] = curr_entity[stackOffset]
                        curr_entity[stackOffset] = -1
                        curr_entity[entity_state_path_offset] = curr_entity[stackOffset + 1]
                        curr_entity[stackOffset + 1] = -1
                        curr_entity[entity_state_path_return_index]--
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

                ; store the return info
                ubyte stackOffsetx = entity_state_path_return + (curr_entity[entity_state_path_return_index] * 2)
                curr_entity[stackOffsetx] = curr_entity[entity_state_path]
                curr_entity[stackOffsetx + 1] = curr_entity[entity_state_path_offset] + 1
                ; set new path
                curr_entity[entity_state_path] = newPath
                curr_entity[entity_state_path_offset] = 0

                return true
            }

            UpdateSpriteSlot(entityIndex, pathEntry[2] as word, pathEntry[3] as word, pathEntry[5] as ubyte, pathEntry[6] as ubyte)

            if (curr_entity[entity_state_path_repeat] == 0)
            {
                curr_entity[entity_state_path_repeat] = pathEntry[1] as ubyte
            }
            curr_entity[entity_state_path_repeat]--
            if (curr_entity[entity_state_path_repeat] == 0)
            {
                curr_entity[entity_state_path_offset]++
            }

            test_x = sprites.GetX(curr_entity[entity_sprite_slot]) as uword + 8
            test_y = sprites.GetY(curr_entity[entity_sprite_slot]) as uword
            if (enemy_diving == true and entityIndex == enemy_diving_index and enemy_bullet_fired == 0 and test_y < 320 and test_y > 120)
            {
                enemy_bullet_fired = 10
                if (num_enemy_bullets > 0)
                {
                    enemy_bullet_fired += 180
                }
                AddEnemyBullet(test_x, test_y, pathEntry[2] as ubyte)
            }
            else if (enemy_bullet_fired > 0)
            {
                enemy_bullet_fired--
            }
            if (CheckPlayerBulletHits(test_x, test_y))
            {
                curr_entity[entity_state] = state_start_explosion
                curr_entity[entity_state_data + 1] = 1
                main.ScoreHit(curr_entity[entity_ship_index])
                if (entityIndex == enemy_diving_index)
                {
                    enemy_diving = false
                }
            }
        }
        return false
    }

    sub InitEntitySlots()
    {
        uword @zp curr_entity = entities_addr
        ubyte entity_index
        for entity_index in 0 to 127
        {
            curr_entity[entity_sprite_slot] = entity_index
            curr_entity[entity_state] = state_none
            curr_entity += 32
        }
    }
}