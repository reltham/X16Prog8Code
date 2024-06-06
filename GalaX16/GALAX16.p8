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

    const ubyte sequencer_entities_start = 32 
    const ubyte game_banks_start = 2
    ubyte num_entities = 0
    uword score = 0
    ubyte player_index = 0
    ubyte player_lives = 3
    ubyte player_died = 0
    
    sub start()
    {
        void cx16.screen_mode(8, false)

        txt.home()
        txt.print(iso:"\nLOADING...")

        Sounds.SetupZSMKit()

        InputHandler.Init()
        SpritePathTables.Init(game_banks_start);
        sprites.Init()

        txt.home()
        txt.print("galax16   \n")

        ubyte num_sequencer_entities = 0
        Sequencer.InitSequencer(sequencer_entities_start)
        Sequencer.StartLevel(0)
        Entity.Begin()
        Entity.InitEntitySlots()
        Entity.Add(num_entities, 2, 366, 18, Entity.state_player, 0)
        player_index = num_entities
        num_entities++
        Entity.SetBulletEntitiesStart(num_entities)
        Entity.End()
        bool spawn_player = false
        ubyte rate = 0
        repeat
        {
            Entity.Begin()
            Entity.UpdateSprites(0, sequencer_entities_start) ;num_entities + Entity.num_player_bullets)
            Entity.UpdateSprites(sequencer_entities_start, num_sequencer_entities)
            Entity.End()

            if (not InputHandler.IsPaused()); and (rate % 8) == 0)
            {
                Entity.Begin()

                num_sequencer_entities = Sequencer.Update() - sequencer_entities_start
                ubyte j
                for j in 0 to (num_entities + Entity.num_player_bullets) - 1
                {
                    if (Entity.UpdateEntity(j))
                    {
                        void Entity.UpdateEntity(j)
                    }
                }
                for j in num_entities + Entity.start_enemy_bullets to (num_entities + Entity.start_enemy_bullets + Entity.num_enemy_bullets) - 1
                {
                    if (Entity.UpdateEntity(j))
                    {
                        void Entity.UpdateEntity(j)
                    }
                }
                for j in sequencer_entities_start to sequencer_entities_start + num_sequencer_entities
                {
                    if (Entity.UpdateEntity(j))
                    {
                        void Entity.UpdateEntity(j)
                    }
                }
                Entity.End()
            }
            rate++

            InputHandler.DoScan();

            txt.home()
            txt.nl()
            txt.spc()
            txt.print_uw(score)
            txt.print("0")
            txt.spc()
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
                    Entity.Begin()
                    Entity.Add(player_index, 2, 366, 18, Entity.state_player, 0)
                    Entity.End()
                    Entity.enable_enemy_diving = true
                    spawn_player = false
                }
            }
            else
            {
                txt.home()
                txt.nl()
                txt.nl()
                txt.nl()
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
        score += GameData.scoreValues[shipIndex>>1]
    }
    
    sub PlayerDied()
    {
        player_died = 30
    }

    sub EnemiesCleared()
    {
        Sounds.PlaySFX(4)
        Entity.ResetFormationMotion()
        Entity.random_chance -= 10
        if (Entity.random_chance < 10) Entity.random_chance = 10
        Sequencer.InitSequencer(sequencer_entities_start)
        Sequencer.StartLevel(0)
    }
}
