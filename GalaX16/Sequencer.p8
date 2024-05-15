Sequencer 
{
    ; sequence rules
    ; must start with a repeat command
    ; must have at least one entity command, but can have up to 4

    const ubyte sequence_repeat = 0
    const ubyte sequence_entity = 1
    const ubyte sequence_end    = 2
    
    const ubyte sequence_command = 0
    
    ; for entity command
   
    const ubyte sequence_entity_id      = 1
    const ubyte sequence_entity_numalt  = 2      ; number of entities that take alt path
    
    ; data for position (note: these index into the positions array to get actual screen coords)
    const ubyte sequence_pos_x = 3
    const ubyte sequence_pos_y = 4
    
    ; data for path
    const ubyte sequence_path_index     = 5
    const ubyte sequence_path_altindex  = 6      ; if an entity takes an alt path then it doesn't go to formation
    
    ; data for next state
    const ubyte sequence_next_state         = 7
    const ubyte sequence_next_state_data    = 8
    const ubyte sequence_next_state_data2   = 9

    ; if next state is formation
    const ubyte sequence_formation_slot = 8     ; which formation slot (indexes into array of slot positions
    const ubyte sequence_formation_inc  = 9     ; when doing multiple loops, this increments the slot index per loop, must be at least 1
    
    ; for repeat command
    const ubyte sequence_repeat_count   = 1     ; repeat this many times
    const ubyte sequence_repeat_pace    = 2     ; number of updates between loops

    ; screen area is 512 x 400
    word[] positions = [
        -16, ;0
          0, ;1
         16, ;2
         32, ;3
         64, ;4
         96, ;5
        100, ;6
        128, ;7
        160, ;8
        192, ;9
        200, ;10
        224, ;11
        256, ;12
        288, ;13
        300, ;14
        320, ;15
        352, ;16
        384, ;17
        400, ;18
        416, ;19
        448, ;20
        480, ;21
        512  ;22
    ]

    ubyte[] sequence0 = [
        0,   6, 4,
        1,   0, 0,  9, 0,  6, 0,  Entity.state_formation, 0, 1,
        2
    ]

    ubyte[] sequence1 = [
        0,    6, 4,
        1,   16, 0,  9, 0,  6, 0,  Entity.state_formation, 6, 1,
        2
    ]

    ubyte[] sequence2 = [
        0,   8, 4,
        1,  12, 0,  15, 0,  7, 0,  Entity.state_formation, 12, 1,
        2
    ]

    ubyte[] sequence3 = [
        0,   8, 4,
        1,  14, 0,  15, 0,  7, 0,  Entity.state_formation, 20, 1,
        2
    ]

    ubyte[] sequence4 = [
        0,   10, 4,
        1,    4, 0,  9, 0,  6, 0,  Entity.state_formation, 28, 1,
        2
    ]

    ubyte[] sequence5 = [
        0,   10, 4,
        1,    6, 0, 15, 0,  7, 0,  Entity.state_formation, 38, 1,
        2
    ]

    uword[] sequences = [
        &sequence0, &sequence1, &sequence2, &sequence3, &sequence4, &sequence5
    ] 

    const ubyte level_set_sequence = 0
    const ubyte level_set_delay = 1

    ubyte[] level_set0 = [
        0, 120,
        1, 120,
        2, 120,
        3, 120,
        4, 120,
        5, 1,
        255, 255
    ]
    
    ubyte[] level_set1 = [
        1, 30,
        0, 1,
        255, 255
    ]
    
    uword[] levels = [
         &level_set0, &level_set1
    ]
    
    uword[] formation_positions_x = [
        158,
        178,
        198,
        218,
        238,
        258,
        278,
        298,
        318,
        338
    ]
    uword[] formation_positions_y = [
          0,
         20,
         40,
         60,
         80,
        100
    ]
    ubyte[] formation_slots = [
                       2, 0,  3, 0,  4, 0,  5, 0,  6, 0,  7, 0,                  ; slots 0-5
                       2, 1,  3, 1,  4, 1,  5, 1,  6, 1,  7, 1,                  ; slots 6-11
                1, 2,  2, 2,  3, 2,  4, 2,  5, 2,  6, 2,  7, 2,  8, 2,           ; slots 12-19
                1, 3,  2, 3,  3, 3,  4, 3,  5, 3,  6, 3,  7, 3,  8, 3,           ; slots 20-27
          0, 4, 1, 4,  2, 4,  3, 4,  4, 4,  5, 4,  6, 4,  7, 4,  8, 4,  9, 4,    ; slots 28-37
          0, 5, 1, 5,  2, 5,  3, 5,  4, 5,  5, 5,  6, 5,  7, 5,  8, 5,  9, 5     ; slots 38-47
    ]
    
    sub SetEntityFormationPosition(ubyte entityIndex, ubyte slotIndex, bool bIntoNextStateData)
    {
        Entity.SetPosition(entityIndex, formation_positions_x[formation_slots[slotIndex*2]], formation_positions_y[formation_slots[(slotIndex*2)+1]], bIntoNextStateData)
    }
    
    uword curr_level = 0
    ubyte level_set_curr_step = 0
    ubyte level_set_curr_delay = 0

    uword curr_sequence = 0
    ubyte sequence_curr_step = 0
    
    ubyte sequence_pace
    ubyte sequence_curr_pace
    ubyte sequence_num_repeats
    ubyte sequence_curr_repeat
    ubyte sequence_curr_entity_index
    ubyte[16] sequence_formation_slots

    ubyte sequencer_entity_index

    sub InitSequencer(ubyte entityIndex)
    {
        sequencer_entity_index = entityIndex
    }

    sub Update() -> ubyte
    {
        if (curr_sequence != 0)
        {
            if (sequence_curr_pace != 0)
            {
                sequence_curr_pace--
            }
            else
            {
                uword sequence_offset = &curr_sequence[sequence_curr_step]
                when sequence_offset[sequence_command]
                {
                    sequence_repeat -> {
                        sequence_pace = sequence_offset[sequence_repeat_pace]
                        sequence_curr_pace = 0
                        sequence_num_repeats = sequence_offset[sequence_repeat_count]
                        sequence_curr_repeat = 0
                        sequence_curr_entity_index = 0
                        sequence_curr_step += 3
                    }
                    sequence_entity -> { 
                        InitEntity(sequence_offset)
                        sequence_curr_entity_index++
                        sequence_curr_step += 10
                    }
                    sequence_end -> {
                        sequence_curr_step = 3  ; return to just after repeat command
                        sequence_curr_repeat++
                        if (sequence_curr_repeat >= sequence_num_repeats)
                        {
                            curr_sequence = 0   ; end sequence
                        }
                        sequence_curr_pace = sequence_pace
                    }
                }
            }
        }
        else if (curr_level != 0)
        {
            level_set_curr_delay--
            if (level_set_curr_delay <= 0)
            {
                level_set_curr_step++
                InitLevelStep()
            }
        }
        return sequencer_entity_index
    }

    sub InitEntity(uword entity_data)
    {
        uword xPos = positions[entity_data[sequence_pos_x]] as uword
        uword yPos = positions[entity_data[sequence_pos_y]] as uword

        Entity.Add(sequencer_entity_index, xPos, yPos, entity_data[sequence_entity_id], Entity.state_onpath, entity_data[sequence_path_index])
        Entity.SetNextState(sequencer_entity_index, entity_data[sequence_next_state], Entity.formation_state_init)
        if (entity_data[sequence_next_state] == Entity.state_formation)
        {
            if (sequence_curr_repeat == 0)
            {
                sequence_formation_slots[sequence_curr_entity_index] = entity_data[sequence_formation_slot]
            }
            else
            {
                sequence_formation_slots[sequence_curr_entity_index] = sequence_formation_slots[sequence_curr_entity_index - 1] + entity_data[sequence_formation_inc]
            }
            SetEntityFormationPosition(sequencer_entity_index, sequence_formation_slots[sequence_curr_entity_index], true)
        }
        sequencer_entity_index++;
    }

    sub InitLevelStep()
    {
        level_set_curr_delay = curr_level[level_set_curr_step * 2 + level_set_delay]
        if (level_set_curr_delay == 255)
        {
            curr_level = 0
        }
        else
        {
            curr_sequence = sequences[curr_level[level_set_curr_step * 2 + level_set_sequence]]
            sequence_curr_step = 0
            sequence_curr_entity_index = 0
        }
    }

    sub StartLevel(ubyte level)
    {
        curr_level = levels[level]
        level_set_curr_step = 0
        InitLevelStep()
    }
}