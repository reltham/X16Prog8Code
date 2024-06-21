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

main $0830
{
zsmkit_lib:
    ; this has to be the first statement to make sure it loads at the specified module address $0830
    %asmbinary "zsmkit-0830.bin"

    const ubyte game_data_ram_bank = 2
    uword score = 0
    ubyte player_index = 0
    ubyte player_lives = 3
    ubyte player_died = 0
    
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

        Sequencer.InitSequencer()
        Sequencer.StartLevel(0)
        GameData.Begin()
        Entity.InitEntitySlots()
        Entity.ResetLists()
        player_index = Entity.GetIndex()
        Entity.Add(player_index, 2, 362, Entity.type_player, GameData.player_ship, Entity.state_none, Entity.sub_state_none, 0)
        GameData.End()
        bool spawn_player = false
        ubyte rate = 0
        repeat
        {
            GameData.Begin()
            sprites.Update()
            GameData.End()

            if (not InputHandler.IsPaused() and (rate % 1) == 0)
            {
                GameData.Begin()
                Sequencer.Update()
                Entity.Update()
                GameData.End()
            }
            rate++

            InputHandler.DoScan()

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

            zsmkit.zsm_fill_buffers()

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
