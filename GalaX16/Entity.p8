Entity
{
    const uword entities_addr = $A000

    ; entities are 32 bytes each
    const ubyte entity_sprite_slot = 0
    const ubyte entity_type = 1
    const ubyte entity_type_data = 2

    ; if the type is enemy
    const ubyte entity_ship_index = 2

    const ubyte entity_state = 3
    const ubyte entity_sub_state = 4
    const ubyte entity_state_data = 5 ; state data size varies by type, max of 20 bytes

    ; next state defaults to none (0) meaning the entity terminates at end of path
    const ubyte entity_state_next_state = 25        ; this state will be set when the state the entity is on ends
    const ubyte entity_state_next_sub_state = 26    ;
    const ubyte entity_state_next_state_data = 27   ; state data size varies by type, max 5 bytes

    const ubyte type_none = 0
    const ubyte type_enemy = 1
    const ubyte type_player = 2
    const ubyte type_static = 3
    const ubyte type_player_bullet = 4
    const ubyte type_enemy_bullet = 5
    const ubyte type_power_up = 6
    
    const ubyte state_none = 0
    const ubyte state_fly_in = 1            ; enemy flying in (on path or fly to)
    const ubyte state_formation = 2         ; enemy in formation 
    const ubyte state_diving = 3            ; enemy diving
    const ubyte state_fly_by = 4            ; enemy fly in and out 

    const ubyte sub_state_none = 0
    const ubyte sub_state_on_path = 1
    const ubyte sub_state_fly_to = 2
    const ubyte sub_state_move = 3
    const ubyte sub_state_follow_player = 4
    const ubyte sub_state_start_explosion = 5
    const ubyte sub_state_exploding = 6
    const ubyte sub_state_formation_init = 7

    ; when sub_state is on_path state data is as follows
    const ubyte entity_state_path = 5
    const ubyte entity_state_path_offset = 6
    const ubyte entity_state_path_repeat = 7
    const ubyte entity_state_path_return_index = 8
    const ubyte entity_state_path_return = 9 ; 16 bytes to hold path indices/offsets for gosub/return stuff (can only nest 8 deep)

    ubyte num_active_enemies = 0
    ubyte num_player_bullets = 0
    ubyte num_enemy_bullets = 0
    const ubyte max_player_bullets = 2
    const ubyte start_enemy_bullets = 8
    const ubyte max_enemy_bullets = 4
    ubyte[16] bullet_entity_index = 0

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

    ubyte[128] FreeIndices
    ubyte[128] UsedIndices
    ubyte @zp NextFree

    sub ResetLists()
    {
        ubyte i
        ubyte j = 127
        for i in 0 to 127
        {
            FreeIndices[i] = j
            j--
            UsedIndices[i] = 0
        }
        NextFree = 127
    }

    sub GetIndex() -> ubyte
    {
        if (NextFree < 128)
        {
            ubyte @zp result = FreeIndices[NextFree] 
            UsedIndices[FreeIndices[NextFree]] = 1
            FreeIndices[NextFree] = 255
            NextFree--
            return result
        }
        return 255
    }
    
    sub ReleaseIndex(ubyte index)
    {
        if (index < 128 and NextFree < 127)
        {
            if (UsedIndices[index] == 1)
            {
                NextFree++
                FreeIndices[NextFree] = index
                UsedIndices[index] = 0
            }
        }
    }

    sub Update()
    {
        bool @zp bFirst = true
        ubyte @zp i
        for i in 0 to 127
        {
            if (UsedIndices[i] != 0)
            {
                if (UpdateEntity(i, bFirst))
                {
                    void UpdateEntity(i, false)
                }
                bFirst = false
            }
        }
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
        if (bullet < max_player_bullets and num_player_bullets > 0)
        {
            uword @zp curr_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
            curr_bullet_entity[entity_type] = type_none
            curr_bullet_entity[entity_state] = state_none
            ReleaseIndex(bullet_entity_index[bullet])
            sprites.SetY(curr_bullet_entity[entity_sprite_slot], -33 as uword)
            if (bullet < num_player_bullets - 1)
            {
                ubyte @zp i
                for i in bullet to num_player_bullets - 2
                {
                    bullet_entity_index[i] = bullet_entity_index[i + 1]
                    curr_bullet_entity = entities_addr + (bullet_entity_index[i] as uword << 5)
                    curr_bullet_entity[entity_state_data] = i
                }
            }
            num_player_bullets--
        }
    }

    sub RemoveEnemyBullet(ubyte bullet)
    {
        if (bullet < (start_enemy_bullets + max_enemy_bullets) and num_enemy_bullets > 0)
        {
            uword @zp curr_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
            curr_bullet_entity[entity_type] = type_none
            curr_bullet_entity[entity_state] = state_none
            ReleaseIndex(bullet_entity_index[bullet])
            sprites.SetY(curr_bullet_entity[entity_sprite_slot], -33 as uword)
            if (bullet < start_enemy_bullets + num_enemy_bullets - 1)
            {
                ubyte @zp i
                for i in bullet to start_enemy_bullets + num_enemy_bullets - 2
                {
                    bullet_entity_index[i] = bullet_entity_index[i + 1]
                    curr_bullet_entity = entities_addr + (bullet_entity_index[i] as uword << 5)
                    curr_bullet_entity[entity_state_data] = i
                }
            }
            num_enemy_bullets--
        }
    }

    sub CheckPlayerBulletHits(uword test_entity_x, uword test_entity_y) -> bool
    {
        if (num_player_bullets > 0)
        {
            ubyte @zp bullet
            for bullet in 0 to num_player_bullets-1
            {
                uword @zp this_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
                uword @zp bullet_y = sprites.GetY(this_bullet_entity[entity_sprite_slot]) as uword
                uword @zp dy = math.diffw(bullet_y, test_entity_y)
                if (dy < 14)
                {
                    uword @zp bullet_x = sprites.GetX(this_bullet_entity[entity_sprite_slot]) as uword
                    uword @zp dx = math.diffw(bullet_x, test_entity_x)
                    if (dx < 18)
                    {
                        RemovePlayerBullet(bullet)
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
        uword @zp test_enemy_y = sprites.GetY(curr_enemy_entity[entity_sprite_slot]) as uword

        uword @zp curr_player_entity = entities_addr + (playerEntityIndex as uword << 5)
        uword @zp test_player_y = sprites.GetY(curr_player_entity[entity_sprite_slot]) as uword

        uword @zp dy = math.diffw(test_enemy_y, test_player_y)
        if (dy < 24)
        {
            uword @zp test_enemy_x = sprites.GetX(curr_enemy_entity[entity_sprite_slot]) as uword
            uword @zp test_player_x = sprites.GetX(curr_player_entity[entity_sprite_slot]) as uword
            uword @zp dx = math.diffw(test_enemy_x, test_player_x)
            if (dx < 25)
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
            ubyte @zp bullet
            for bullet in start_enemy_bullets to start_enemy_bullets + num_enemy_bullets - 1
            {
                uword @zp this_bullet_entity = entities_addr + (bullet_entity_index[bullet] as uword << 5)
                uword @zp bullet_x = sprites.GetX(this_bullet_entity[entity_sprite_slot]) as uword
                uword @zp dx = math.diffw(bullet_x, test_entity_x)
                if (dx < 18)
                {
                    uword @zp bullet_y = sprites.GetY(this_bullet_entity[entity_sprite_slot]) as uword
                    uword @zp dy = math.diffw(bullet_y, test_entity_y)
                    if (dy < 13)
                    {
                        RemoveEnemyBullet(bullet)
                        return true
                    }
                }
            }
        }
        return false
    }
    
    sub AddPlayerBullet()
    {
        if (num_player_bullets < max_player_bullets)
        {
            Sounds.PlaySFX(4)
            GameData.Begin()
            Add(GetIndex(), InputHandler.player_offset, 340, type_player_bullet, GameData.player_bullet, state_none, sub_state_none, 0)
            GameData.End()
        }
    }

    sub AddEnemyBullet(uword enemy_x, uword enemy_y, ubyte dx)
    {
        if (num_enemy_bullets < max_enemy_bullets)
        {
            Sounds.PlaySFX(1)
            GameData.Begin()
            Add(GetIndex(), enemy_x, enemy_y + 16, type_enemy_bullet, GameData.enemy_bullet, state_none, sub_state_none, dx)
            GameData.End()
        }
    }

    sub Add(ubyte entityIndex, uword xPos, uword yPos, ubyte type, ubyte typeData, ubyte state, ubyte subState, ubyte stateData)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)

        curr_entity[entity_type] = type
        curr_entity[entity_type_data] = typeData
        if (type == type_enemy)
        {
            sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.GetShipSpriteOffset(typeData))
            sprites.SetPaletteOffset(curr_entity[entity_sprite_slot], GameData.GetShipSpritePalette(typeData))
            sprites.SetZDepth(curr_entity[entity_sprite_slot], sprites.zdepth_front)
            num_active_enemies++
        }
        else
        {
            sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.sprite_indices[typeData])
            sprites.SetPaletteOffset(curr_entity[entity_sprite_slot], GameData.sprite_palettes[typeData])
            sprites.SetZDepth(curr_entity[entity_sprite_slot], sprites.zdepth_middle)
            sprites.SetFlips(curr_entity[entity_sprite_slot], sprites.flips_none)
        }
        curr_entity[entity_state] = state
        curr_entity[entity_sub_state] = subState
        curr_entity[entity_state_data] = stateData
        curr_entity[entity_state_data + 1] = 0
        curr_entity[entity_state_data + 2] = 0
        ubyte @zp i
        for i in 3 to 19
        {
            curr_entity[entity_state_data + i] = -1
        }
        curr_entity[entity_state_next_state] = 0
        curr_entity[entity_state_next_sub_state] = 0
        curr_entity[entity_state_next_state_data] = 0
        for i in 1 to 4
        {
            curr_entity[entity_state_next_state_data + i] = 0
        }

        if (type == type_player_bullet and num_player_bullets < max_player_bullets)
        {
            bullet_entity_index[num_player_bullets] = entityIndex
            ; these are offset because the bullet image is in the middle of the sprite image
            xPos += 6
            yPos -= 4
            curr_entity[entity_state_data] = num_player_bullets
            curr_entity[entity_state_data + 1] = stateData
            num_player_bullets++
        }
        if (type == type_enemy_bullet and num_enemy_bullets < max_enemy_bullets)
        {
            ubyte bullet_index = start_enemy_bullets + num_enemy_bullets
            bullet_entity_index[bullet_index] = entityIndex
            ; these are offset because the bullet image is in the middle of the sprite image
            xPos += 6
            yPos -= 4
            curr_entity[entity_state_data] = bullet_index
            curr_entity[entity_state_data + 1] = stateData
            num_enemy_bullets++
        }

        sprites.SetPosition(curr_entity[entity_sprite_slot], xPos as uword, yPos as uword)
    }

    sub SetNextState(ubyte entityIndex, ubyte nextState, ubyte nextSubState, ubyte nextStateData)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)
        curr_entity[entity_state_next_state] = nextState
        curr_entity[entity_state_next_sub_state] = nextSubState
        curr_entity[entity_state_next_state_data] = nextStateData
    }

    sub SetPosition(ubyte entityIndex, uword xPos, uword yPos)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)
        pokew(curr_entity + entity_state_next_state_data + 1, xPos)
        pokew(curr_entity + entity_state_next_state_data + 3, yPos)
    }

    sub UpdateSpriteSlot(ubyte entityIndex, word xPos, word yPos, ubyte spriteIndex, ubyte spriteFlips)
    {
        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)

        word @zp xPosA = sprites.GetX(curr_entity[entity_sprite_slot]) + xPos
        word @zp yPosA = sprites.GetY(curr_entity[entity_sprite_slot]) + yPos

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

    sub UpdateEntity(ubyte entityIndex, bool bFirstTimePerFrame) -> bool
    {
        if (enable_formation_moving == true and bFirstTimePerFrame == true)
        {
            if (formation_offset_update == 0)
            {
                if (curr_formation_x_offset > 60) formation_direction_x = -1
                if (curr_formation_x_offset < -60) formation_direction_x = 1
                curr_formation_x_offset += formation_direction_x
    
                if (curr_formation_y_offset > 10) formation_direction_y = -1
                if (curr_formation_y_offset < -5) formation_direction_y = 1
                curr_formation_y_offset += formation_direction_y
                formation_offset_update = 2
            }
            else
            {
                formation_offset_update--
            } 
        }

        uword @zp curr_entity = entities_addr + (entityIndex as uword << 5)

        if (curr_entity[entity_type] == type_static)
        {
            return false
        }
        else if (curr_entity[entity_type] == type_player and curr_entity[entity_sub_state] == sub_state_none)
        {
            sprites.SetX(curr_entity[entity_sprite_slot], InputHandler.player_offset)
            bool kill_player = false
            if (enemy_diving == true)
            {
                if (CheckEnemyPlayerHit(entityIndex) == true)
                {
                    uword @zp diving_enemy_entity = entities_addr + (enemy_diving_index as uword << 5)
                    diving_enemy_entity[entity_sub_state] = sub_state_start_explosion
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
                curr_entity[entity_sub_state] = sub_state_start_explosion
                main.PlayerDied()
                enable_enemy_diving = false
                return true
            }
            return false
        }
        else if (curr_entity[entity_type] == type_player_bullet)
        {
            word @zp curr_player_bullet_x = sprites.GetX(curr_entity[entity_sprite_slot])
            word @zp curr_player_bullet_y = sprites.GetY(curr_entity[entity_sprite_slot])
            curr_player_bullet_y -= 8
            curr_player_bullet_x += curr_entity[entity_state_data + 1] as byte
            sprites.SetPosition(curr_entity[entity_sprite_slot], curr_player_bullet_x as uword, curr_player_bullet_y as uword)
            if (curr_player_bullet_y < -32)
            {
                RemovePlayerBullet(curr_entity[entity_state_data])
            }
            return false
        }
        else if (curr_entity[entity_type] == type_enemy_bullet)
        {
            word @zp curr_bullet_x = sprites.GetX(curr_entity[entity_sprite_slot])
            word @zp curr_bullet_y = sprites.GetY(curr_entity[entity_sprite_slot])
            curr_bullet_y += 4
            curr_bullet_x += curr_entity[entity_state_data + 1] as byte
            sprites.SetPosition(curr_entity[entity_sprite_slot], curr_bullet_x as uword, curr_bullet_y as uword)
            if (curr_bullet_y > 400)
            {
                RemoveEnemyBullet(curr_entity[entity_state_data])
            }
            return false
        }
        else if (curr_entity[entity_sub_state] == sub_state_start_explosion)
        {
            Sounds.PlaySFX(2)
            sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.sprite_indices[GameData.enemy_explosion_start])
            sprites.SetPaletteOffset(curr_entity[entity_sprite_slot], GameData.sprite_palettes[GameData.enemy_explosion_start])
            curr_entity[entity_type_data] = -1
            curr_entity[entity_sub_state] = sub_state_exploding
            curr_entity[entity_state_data] = 1
            return false
        }
        else if (curr_entity[entity_sub_state] == sub_state_exploding)
        {
            if (curr_entity[entity_state_data] < 5)
            {
                sprites.SetAddress(curr_entity[entity_sprite_slot], GameData.sprite_indices[GameData.enemy_explosion_start] + curr_entity[entity_state_data])
                curr_entity[entity_state_data]++
            }
            else
            {
                sprites.SetY(curr_entity[entity_sprite_slot], -33 as uword)
                if (curr_entity[entity_type] == type_enemy)
                {
                    num_active_enemies--
                    if (num_active_enemies == 0 and enable_formation_moving == true)
                    {
                        main.EnemiesCleared()
                    }
                }
                curr_entity[entity_type] = type_none
                curr_entity[entity_state] = state_none
                curr_entity[entity_sub_state] = sub_state_none
                ReleaseIndex(entityIndex)
            }
            return false
        }
        else if (curr_entity[entity_state] == state_formation)
        {
            if (curr_entity[entity_sub_state] == sub_state_formation_init)
            {
                word curr_x = sprites.GetX(curr_entity[entity_sprite_slot])
                word curr_y = sprites.GetY(curr_entity[entity_sprite_slot])
                word target_x = peekw(curr_entity + entity_state_data + 1) as word + curr_formation_x_offset
                word target_y = peekw(curr_entity + entity_state_data + 3) as word + curr_formation_y_offset
                word diff_x = (target_x - curr_x)
                word diff_y = (target_y - curr_y)
                if (diff_y > -130)
                {
                    curr_entity[entity_state_data + 5] = (diff_x / 16) as ubyte
                    curr_entity[entity_state_data + 6] = (diff_y / 16) as ubyte
                    curr_entity[entity_state_data + 7] = 16
                }
                else
                {
                    curr_entity[entity_state_data + 5] = (diff_x / 24) as ubyte
                    curr_entity[entity_state_data + 6] = (diff_y / 24) as ubyte
                    curr_entity[entity_state_data + 7] = 24
                }
                ubyte direction = 23 - ((math.direction_sc(0, 0, curr_entity[entity_state_data + 5] as byte, curr_entity[entity_state_data + 6] as byte) + 18) % 24)

                ; set sprite image index and flips
                uword sprite_info = GameData.GetSpriteRotationInfo(curr_entity[entity_ship_index], direction)
                sprites.SetAddress(curr_entity[entity_sprite_slot], msb(sprite_info))
                sprites.SetFlips(curr_entity[entity_sprite_slot], lsb(sprite_info))

                ; do first step
                curr_x += curr_entity[entity_state_data + 5] as byte
                curr_y += curr_entity[entity_state_data + 6] as byte
                sprites.SetPosition(curr_entity[entity_sprite_slot], curr_x as uword, curr_y as uword)

                curr_entity[entity_sub_state] = sub_state_fly_to
            }
            else if (curr_entity[entity_sub_state] == sub_state_fly_to)
            {
                curr_x = sprites.GetX(curr_entity[entity_sprite_slot])
                curr_y = sprites.GetY(curr_entity[entity_sprite_slot])
                curr_x += curr_entity[entity_state_data + 5] as byte
                curr_y += curr_entity[entity_state_data + 6] as byte
                curr_entity[entity_state_data + 7]--
                if (curr_entity[entity_state_data + 7] == 0)
                {
                    curr_x = peekw(curr_entity + entity_state_data + 1) as word + curr_formation_x_offset
                    curr_y = peekw(curr_entity + entity_state_data + 3) as word + curr_formation_y_offset
                    curr_entity[entity_sub_state] = sub_state_none
                    sprite_info = GameData.GetSpriteRotationInfo(curr_entity[entity_ship_index], 0)
                    sprites.SetAddress(curr_entity[entity_sprite_slot], msb(sprite_info))
                    sprites.SetFlips(curr_entity[entity_sprite_slot], lsb(sprite_info))
                    sprites.SetZDepth(curr_entity[entity_sprite_slot], sprites.zdepth_middle)
                }
                sprites.SetPosition(curr_entity[entity_sprite_slot], curr_x as uword, curr_y as uword)
            }
            else if (curr_entity[entity_sub_state] == sub_state_none)
            {
                if (formation_offset_update == 2)
                {        
                    target_x = peekw(curr_entity + entity_state_data + 1) as word 
                    target_y = peekw(curr_entity + entity_state_data + 3) as word
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
                            ubyte saved_formation_slot = curr_entity[entity_state_data]

                            curr_entity[entity_state] = state_diving 
                            curr_entity[entity_sub_state] = sub_state_on_path
                            curr_entity[entity_state_data] = random_value >> 2
                            curr_entity[entity_state_data + 1] = 0
                            curr_entity[entity_state_data + 2] = 0
                            for i in 3 to 19
                            {
                                curr_entity[entity_state_data + i] = -1
                            }
                            SetNextState(entityIndex, state_formation, sub_state_formation_init, saved_formation_slot)
                            Sequencer.SetEntityFormationPosition(entityIndex, saved_formation_slot)
                            enemy_diving_index = entityIndex
                            enemy_diving = true
                            enemy_bullet_fired = 30
                            Sounds.PlaySFX(3)
                            sprites.SetZDepth(curr_entity[entity_sprite_slot], sprites.zdepth_front)
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
                curr_entity[entity_sub_state] = sub_state_start_explosion
                main.ScoreHit(curr_entity[entity_ship_index])
                if (entityIndex == enemy_diving_index)
                {
                    enemy_diving = false
                }
            }
            return false
        }
        else if (curr_entity[entity_sub_state] == sub_state_on_path)
        {
            byte[7] pathEntry
            SpritePathTables.GetPathEntry(curr_entity[entity_state_path], curr_entity[entity_state_path_offset], curr_entity[entity_ship_index], &pathEntry)

            if (pathEntry[0] == 0)
            {
                if (pathEntry[1] == 0)
                {
                    curr_entity[entity_state] = curr_entity[entity_state_next_state]
                    curr_entity[entity_sub_state] = curr_entity[entity_state_next_sub_state]
                    curr_entity[entity_state_data] = curr_entity[entity_state_next_state_data]
                    if (curr_entity[entity_state_next_state] != state_none)
                    {
                        ubyte i
                        for i in 1 to 4
                        {
                            curr_entity[entity_state_data + i] = curr_entity[entity_state_next_state_data + i]
                        }
                        ;curr_entity[entity_state_data + 5] = -1
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
                enemy_bullet_fired = 15
                if (num_enemy_bullets > 0)
                {
                    enemy_bullet_fired = num_enemy_bullets << 5
                }
                AddEnemyBullet(test_x, test_y, pathEntry[2] as ubyte)
            }
            else if (enemy_bullet_fired > 0)
            {
                enemy_bullet_fired--
            }
            if (CheckPlayerBulletHits(test_x, test_y))
            {
                curr_entity[entity_sub_state] = sub_state_start_explosion
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
        ubyte @zp entity_index
        for entity_index in 0 to 127
        {
            curr_entity[entity_sprite_slot] = entity_index
            curr_entity[entity_type] = type_none
            curr_entity[entity_state] = state_none
            curr_entity += 32
        }
    }
}