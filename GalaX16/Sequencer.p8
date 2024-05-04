Sequencer 
{
    const ubyte sequence_pace = 0
    const ubyte sequence_entity = 1
    const ubyte sequence_position = 2
    const ubyte sequence_path = 3
    const ubyte sequence_formation = 4
    const ubyte sequence_loop = 5
    
    const ubyte sequence_command = 0
    const ubyte sequence_data0 = 1
    const ubyte sequence_data1 = 2
    
    ; data for pace
    const ubyte sequence_pace_rate = 0
    
    ; data for entity
    const ubyte sequence_entity_id = 0
    const ubyte sequence_entity_numalt = 1
    
    ; data for position (note: these index into the positions array to get actual screen coords)
    const ubyte sequence_pos_x = 0
    const ubyte sequence_pos_y = 1
    
    ; data for path
    const ubyte sequence_path_index = 0
    const ubyte sequence_path_altindex = 1
    
    ; data for formation
    const ubyte sequence_formation_slot = 0
    const ubyte sequence_formation_inc = 0

    ; data for end
    const ubyte sequence_loop_index = 0
    const ubyte sequence_loop_repeat = 1

    word[] positions = [
        -16, ;0
          0, ;1
         16, ;2
         64, ;3
        128, ;4
        240, ;5
        320, ;6
        352, ;7
        416, ;8
        464, ;9
        480, ;10
        512, ;11
        576, ;12
        624, ;12
        640  ;13
    ]
    
    ubyte[] sequence0 = [
        0, 1, 0,
        1, 0, 0,
        2, 6, 0,
        3, 0, 0,
        4, 0, 1,
        5, 1, 8
    ]
    ubyte[] sequence1 = [
        0, 1, 0,
        1, 1, 0,
        2, 6, 0,
        3, 5, 0,
        4, 8, 1,
        5, 1, 8
    ]
    
    uword[] sequences = [
        &sequence0, &sequence1
    ] 

    const ubyte level_set_sequence = 0
    const ubyte level_set_delay = 1

    ubyte[] level_set0 = [
        0, 30,
        1, 0,
        255, 255
    ]
    
    ubyte[] level_set1 = [
        1, 30,
        0, 0,
        255, 255
    ]
    
    uword[] levels = [
         &level_set0, &level_set1
    ]
    
    uword curr_level = 0
    ubyte level_set_curr_step = 0
    ubyte level_set_curr_delay = 0

    uword curr_sequence = 0
    ubyte sequence_curr_pace = 0
    ubyte sequence_curr_step = 0
    ubyte sequence_repeat = 0

    sub Init()
    {
    }

    sub Update()
    {
    }

    sub StartLevel(ubyte level)
    {
        curr_level = levels[level]
        level_set_curr_step = 0
        curr_sequence = sequences[curr_level[level_set_curr_step * 2 + level_set_sequence]]
        level_set_curr_delay = curr_level[level_set_curr_step * 2 + level_set_delay]
        sequence_curr_step = 0
        
    }
}