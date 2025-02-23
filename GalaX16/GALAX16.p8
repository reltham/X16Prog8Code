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

main
{
    const ubyte game_data_ram_bank = 2
    uword score = 0
    ubyte player_index = 0
    ubyte player_lives = 3
    ubyte player_died = 0
    bool paused = false

    sub start()
    {
        void cx16.screen_mode(8, false)
        ;cx16.VERA_DC_BORDER = 11
        txt.home()
        txt.print(iso:"\nLOADING...")

        Sounds.SetupZSMKit()

        InputHandler.Init()
        GameData.Begin()
        SpritePathTables.Init()
        sprites.Init()
        GameData.End()

        txt.home()
        txt.print("          \n")

        ; display logo
        GameData.Begin()
        sprites.SetPosition(124, 128 as uword, 128 as uword)
        sprites.SetPosition(125, 192 as uword, 128 as uword)
        sprites.SetPosition(126, 256 as uword, 128 as uword)
        sprites.SetPosition(127, 320 as uword, 128 as uword)
        GameData.End()
        txt.plot(26,25)
        txt.print(iso:"PRESS START!")

        ; wait for start press
        repeat
        {
            GameData.Begin()
            sprites.Update()
            GameData.End()
            InputHandler.DoScan()
            if (InputHandler.pressed_start == true)
            {
                InputHandler.pressed_start = false;
                ; hide logo
                GameData.Begin()
                sprites.SetPosition(124, -64 as uword, -64 as uword)
                sprites.SetPosition(125, -64 as uword, -64 as uword)
                sprites.SetPosition(126, -64 as uword, -64 as uword)
                sprites.SetPosition(127, -64 as uword, -64 as uword)
                sprites.Update()
                GameData.End()
                txt.plot(26,25)
                txt.print(iso:"            ")
                break;
            }
            sys.waitvsync()
        }

        ; start the game
        Sequencer.InitSequencer()
        Sequencer.StartLevel(0)
        GameData.Begin()
        Entity.InitEntitySlots()
        Entity.ResetLists()
        player_index = Entity.GetIndex()
        Entity.Add(player_index, 2, 362, Entity.type_player, GameData.player_ship, Entity.state_none, Entity.sub_state_none, 0)
        GameData.End()
        zsmkit.zsm_play(0)
        bool spawn_player = false
        ubyte rate = 0
        InputHandler.pressed_start = false;
        repeat
        {
            GameData.Begin()
            sprites.Update()
            GameData.End()

            if (paused == false and (rate % 1) == 0)
            {
                GameData.Begin()
                Sequencer.Update()
                Entity.Update()
                GameData.End()
            }
            rate++

            InputHandler.DoScan()
            if (InputHandler.pressed_start == true)
            {
                InputHandler.pressed_start = false;
                zsmkit.zcm_stop()
                if (paused)
                {
                    zsmkit.zsm_play(0)
                    paused = false
                    zsmkit.zcm_play(1, 8)
                }
                else
                {
                    zsmkit.zsm_stop(0)
                    paused = true
                    zsmkit.zcm_play(0, 8)
                }
            }
            if (InputHandler.newleft == true)
            {
                Entity.player_offset -= 4
                if (Entity.player_offset < 4)
                {
                    Entity.player_offset = 4
                }
            }
            if (InputHandler.newright == true)
            {
                Entity.player_offset += 4
                if (Entity.player_offset > 476)
                {
                    Entity.player_offset = 476
                }
            }


            txt.home()
            txt.print_uw(score)
            txt.print("0")
            txt.plot(0, 49)
            txt.print("lives ")
            txt.print_ub(player_lives)
            
            if (player_lives > 0)
            {
                if (InputHandler.fire_bullet == true and player_died == 0 and spawn_player == false)
                {
                    InputHandler.fire_bullet = false
                    Entity.AddPlayerBullet()
                }

                if (player_died > 0)
                {
                    player_died--
                    if (player_died == 1)
                    {
                        if (player_lives > 0)
                        {
                            player_lives--
                        }
                        if (player_lives > 0)
                        {
                            spawn_player = true
                        }
                    }
                }

                if (spawn_player == true and Entity.enemy_diving == false)
                {
                    GameData.Begin()
                    player_index = Entity.GetIndex()
                    Entity.Add(player_index, 2, 362, Entity.type_player, GameData.player_ship, Entity.state_none, Entity.sub_state_none, 0)
                    GameData.End()
                    Entity.enable_enemy_diving = true
                    spawn_player = false
                }
            }
            else
            {
                txt.plot(28,25)
                txt.print("game over")
            }

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
    }
    
    sub PlayerDied()
    {
        player_died = 30
    }

    sub EnemiesCleared()
    {
        Sounds.PlaySFX(0)
        Entity.ResetFormationMotion()
        Entity.random_chance -= 10
        if (Entity.random_chance < 10)
        {
            Entity.random_chance = 10
        }
        Sequencer.InitSequencer()
        Sequencer.StartLevel(0)
    }
}
