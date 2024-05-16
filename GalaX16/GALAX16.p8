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

    const ubyte game_banks_start = 2

    sub start()
    {
        void cx16.screen_mode(8, false)

        txt.home()
        txt.print(iso:"\nLOADING...")

        Sounds.SetupZSMKit()

        InputHandler.Init()
        SpritePathTables.Init(game_banks_start);
        sprites.Init()

        ;txt.cls()
        txt.home()
        txt.print("galax16   \n")

        ubyte num_entities = 0
        const ubyte num_entities_static = 32
        SetupDemoEnitities(num_entities, num_entities_static)
        Sequencer.InitSequencer(num_entities_static)
        Sequencer.StartLevel(0)
        Entity.Begin()
        Entity.UpdateSprites(0, num_entities_static)
        Entity.End()
        ubyte rate = 0
        repeat
        {
            ;cx16.VERA_DC_BORDER = 8
            Entity.Begin()
            Entity.UpdateSprites(num_entities_static, num_entities)
            Entity.End()

            ;cx16.VERA_DC_BORDER = 2
            if (not InputHandler.IsPaused()); and (rate % 2) == 0)
            {
                Entity.Begin()
                num_entities = Sequencer.Update() - num_entities_static
                ubyte j
                for j in num_entities_static to (num_entities_static + num_entities)
                {
                    ;cx16.VERA_DC_BORDER = 2 + j % 1
                    if (Entity.UpdateEntity(j))
                    {
                        void Entity.UpdateEntity(j)
                    }
                }
                Entity.End()
            }
            ;cx16.VERA_DC_BORDER = 7
            rate++

            InputHandler.DoScan();

            ;cx16.VERA_DC_BORDER = 5
            zsmkit.zsm_fill_buffers()

            if (Sounds.GetBeat())
            {
                Sounds.ClearBeat()
            }

            if (Sounds.GetLoopChanged())
            {
                Sounds.ClearLoopChanged()
            }

            ;cx16.VERA_DC_BORDER = 0
            sys.waitvsync()
            ;cx16.VERA_DC_BORDER = 8
        }
    }

    sub SetupDemoEnitities(ubyte numShips, ubyte numStatic)
    {
        ubyte k
        Entity.Begin()
        for k in 0 to numStatic - 1
        {
            ubyte sprite_index
            if (k < len(GameData.sprite_indices))
            {
                sprite_index = GameData.sprite_indices[k]
            }
            else
            {
                sprite_index = SpritePathTables.GetSpriteOffset((k % 10) << 1)
            }
            Entity.Add(k, (k as uword * 16), 384, sprite_index, Entity.state_static, 0)
            if (Entity.UpdateEntity(k))
            {
                void Entity.UpdateEntity(k)
            }
        } 
        ubyte numUpdates = 0
        for k in numStatic to (numStatic + numShips) - 1
        {
            Entity.Add(k, 128, 0, ((k >> 2) % 10) << 1, Entity.state_onpath, (k % 2) * 5)
            Entity.SetNextState(k, Entity.state_onpath, (k % 2) * 5)
            repeat numUpdates
            {
                if (Entity.UpdateEntity(k))
                {
                    void Entity.UpdateEntity(k)
                }
            }
            numUpdates += 1
        }
        Entity.End()
    }
}
