%import textio
%import diskio
%import math
%import syslib
%import palette
%import zsmkit
%import galax_sprites
%import joystick
%import InputHandler
%import SpritePathTables
%import Entity
%import Sequencer
%import Sounds
%import GameData
%zeropage kernalsafe

; memory map
; $0400 - $07FF ->     1K - sprite register RAM copy, 128 sprites, 8 bytes each
; $0800 - $6FFF -> ~26.5k - game code + BSS
; $7000 - $8EFF ->  ~7.9k - paths (currently only using about 4k, but many more paths needed)
; $8F00 - $9EFF ->     8k - entities array, 128 entities, 32 bytes each
;
; zsmkit is in bank 1
; gamedata is in bank 2
; music/sfx are in banks 3+

main
{
    const ubyte gamestate_title = 1
    const ubyte gamestate_init = 2
    const ubyte gamestate_starting = 3
    const ubyte gamestate_ingame = 4
    const ubyte gamestate_paused = 5
    const ubyte gamestate_player_died = 6
    const ubyte gamestate_game_over = 7

    const ubyte game_data_ram_bank = 2
    ubyte current_gamestate = gamestate_title
    uword score = 0
    uword extra_life_tracker = 0
    ubyte player_index = 0
    ubyte player_lives = 3
    ubyte player_died = 0
    ubyte game_over = 0
    ubyte start_countdown = 0
    bool was_diving = false
    bool start_the_level = false
    ubyte level = 0

    sub start()
    {
        void cx16.screen_mode(8, false)
        ;cx16.VERA_DC_BORDER = 11
        txt.home()
        txt.print(iso:"\nLOADING...")

        Sounds.SetupZSMKit()
        InputHandler.Init()
        SpritePathTables.Init()
        sprites.Init()

        txt.home()
        txt.print("\n          ")

        bool spawn_player = false
        InputHandler.pressed_start = false
        repeat
        {
            when current_gamestate
            {
                gamestate_title -> {
                    ; display logo
                    sprites.SetZDepth(124, sprites.zdepth_back)
                    sprites.SetZDepth(125, sprites.zdepth_back)
                    sprites.SetZDepth(126, sprites.zdepth_back)
                    sprites.SetZDepth(127, sprites.zdepth_back)
                    txt.plot(26,25)
                    txt.print(iso:"PRESS START!")

                    ; wait for start press
                    InputHandler.DoScan()
                    if (InputHandler.pressed_start == true)
                    {
                        InputHandler.pressed_start = false;
                        current_gamestate = gamestate_init
                    }
                }
                gamestate_init -> {
                    ; hide logo
                    sprites.SetZDepth(124, sprites.zdepth_disabled)
                    sprites.SetZDepth(125, sprites.zdepth_disabled)
                    sprites.SetZDepth(126, sprites.zdepth_disabled)
                    sprites.SetZDepth(127, sprites.zdepth_disabled)
                    txt.plot(26,25)
                    txt.print(iso:"            ")

                    level = 0
                    player_lives = 3
                    score = 0

                    ; clear old score
                    txt.home()
                    txt.print("        ")

                    ; start the game
                    start_the_level = true
                    sprites.ResetSpriteSlots()
                    Entity.InitEntitySlots()
                    Entity.ResetLists()
                    start_countdown = 90
                    zsmkit.zsm_play(0)
                    Sounds.PlaySFX(0)
                    current_gamestate = gamestate_starting
                }
                gamestate_starting -> {
                    if (Entity.enemy_diving == false and Entity.num_enemy_bullets == 0)
                    {
                        if (start_countdown == 90)
                        {
                            txt.plot(28,25)
                            txt.print("get ready!")
                            player_index = Entity.GetIndex()
                            Entity.Add(player_index, 248, 399, Entity.type_player, GameData.player_ship, Entity.state_none, Entity.sub_state_none, 0)
                            Entity.player_offset = 248
                        }
                        if (start_countdown < 38)
                        {
                            Entity.UpdateEntityYPosition(player_index, 362 + start_countdown)
                        }
                        if (start_countdown == 1)
                        {
                            txt.plot(28,25)
                            txt.print("          ")
                        }
                        start_countdown--
                        if (start_countdown == 0)
                        {
                            if (was_diving == true)
                            {
                                was_diving = false
                                Entity.enable_enemy_diving = true
                            }
                            if (start_the_level == true)
                            {
                                start_the_level = false
                                Sequencer.StartLevel(level)
                            }
                            current_gamestate = gamestate_ingame
                        }
                    }
                    Sequencer.Update()
                    Entity.Update()
                }
                gamestate_ingame -> {
                    Sequencer.Update()
                    Entity.Update()

                    InputHandler.DoScan()
                    if (InputHandler.pressed_start == true)
                    {
                        InputHandler.pressed_start = false;
                        zsmkit.zsm_stop(0)
                        zsmkit.zcm_stop()
                        zsmkit.zcm_play(0, 8)
                        current_gamestate = gamestate_paused
                    }
                    if (InputHandler.oldleft == true)
                    {
                        Entity.player_offset -= 4
                        if (Entity.player_offset < 4)
                        {
                            Entity.player_offset = 4
                        }
                    }
                    if (InputHandler.oldright == true)
                    {
                        Entity.player_offset += 4
                        if (Entity.player_offset > 476)
                        {
                            Entity.player_offset = 476
                        }
                    }
                    if (InputHandler.fire_bullet == true and spawn_player == false)
                    {
                        InputHandler.fire_bullet = false
                        Entity.AddPlayerBullet()
                    }
                }
                gamestate_paused -> {
                    InputHandler.DoScan()
                    if (InputHandler.pressed_start == true)
                    {
                        InputHandler.pressed_start = false;
                        zsmkit.zcm_stop()
                        zsmkit.zcm_play(1, 8)
                        zsmkit.zsm_play(0)
                        current_gamestate = gamestate_ingame
                    }
                }
                gamestate_player_died -> {
                    if (player_lives > 0)
                    {
                        player_lives--
                    }
                    if (player_lives > 0)
                    {
                        start_countdown = 90
                        current_gamestate = gamestate_starting
                    }
                    else
                    {
                        game_over = 180
                        was_diving = false
                        current_gamestate = gamestate_game_over
                    }
                }
                gamestate_game_over -> {
                    if (game_over == 180)
                    {
                        txt.plot(28,25)
                        txt.print("game over")
                        zsmkit.zsm_stop(0)
                        zsmkit.zsm_rewind(0)
                    }
                    Sequencer.Update()
                    Entity.Update()
                    game_over--
                    if (game_over == 0)
                    {
                        txt.plot(28,25)
                        txt.print("         ")
                        sprites.ResetSpriteSlots()
                        current_gamestate = gamestate_title
                    }
                }
            }

            sprites.Update()

            txt.home()
            txt.print_uw(score)
            txt.print("0")
            txt.plot(0, 49)
            txt.print("lives ")
            txt.print_ub(player_lives)
            txt.plot(55, 49)
            txt.print("level ")
            txt.print_ub(level)

            if (Sounds.GetBeat())
            {
                Sounds.ClearBeat()
            }

            if (Sounds.GetLoopChanged())
            {
                Sounds.ClearLoopChanged()
            }

            sys.waitvsync()
        }
    }
    
    sub ScoreHit(ubyte shipIndex)
    {
        score += GameData.scoreValues[shipIndex]
        extra_life_tracker += GameData.scoreValues[shipIndex]
        if (extra_life_tracker > 5000)
        {
            extra_life_tracker -= 5000
            player_lives++
        }
    }
    
    sub PlayerDied()
    {
        if (Entity.enable_enemy_diving == true)
        {
            was_diving = true
        }
        current_gamestate = gamestate_player_died
    }

    sub EnemiesCleared()
    {
        Sounds.PlaySFX(0)
        Entity.ResetFormationMotion()
        Entity.random_chance -= 10
        if (Entity.random_chance < 150)
        {
            Entity.random_chance = 150
        }
        level++
        Sequencer.StartLevel(level)
    }
}
