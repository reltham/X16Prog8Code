Sequencer 
{
    ; sequence rules
    ; must start with a pace
    ; must have entity/position/path in that order
    ; formation is optional, but must immediately follow path
    ; can have multiple entity sets 
    ; must end with loop, set to repeat 0 or 1 to not loop and just do one time
    ;
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
    const ubyte sequence_pace_rate = 0          ; number of updates between loops
    
    ; data for entity
    const ubyte sequence_entity_id = 0
    const ubyte sequence_entity_numalt = 1      ; number of entities that take alt path
    
    ; data for position (note: these index into the positions array to get actual screen coords)
    const ubyte sequence_pos_x = 0
    const ubyte sequence_pos_y = 1
    
    ; data for path
    const ubyte sequence_path_index = 0
    const ubyte sequence_path_altindex = 1      ; if an entity takes an alt path then it doesn't go to formation
    
    ; data for formation
    const ubyte sequence_formation_slot = 0     ; which formation slot (indexes into array of slot positions
    const ubyte sequence_formation_inc = 0      ; when doing multiple loops, this increments the slot index per loop, must be at least 1

    ; data for end
    const ubyte sequence_loop_index = 0         ; which sequence step to loop back to
    const ubyte sequence_loop_repeat = 1        ; number of time to loop

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
        0, 2, 0,
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
    
    uword[] formation_positions_x = [
         96,
        128,
        160,
        192,
        224,
        256,
        288,
        320,
        352,
        384
    ]
    uword[] formation_positions_y = [
          0,
         32,
         64,
         96,
        128,
        160
    ]
    ubyte[] formation_slots = [
                       2, 0,  3, 0,  4, 0,  5, 0,  6, 0,  7, 0,                  ; slots 0-5
                       2, 1,  3, 1,  4, 1,  5, 1,  6, 1,  7, 1,                  ; slots 6-11
                1, 2,  2, 2,  3, 2,  4, 2,  5, 2,  6, 2,  7, 2,  8, 2,           ; slots 12-19
                1, 3,  2, 3,  3, 3,  4, 3,  5, 3,  6, 3,  7, 3,  8, 3,           ; slots 20-27
          0, 4, 1, 4,  2, 4,  3, 5,  4, 4,  5, 4,  6, 4,  7, 4,  8, 4,  9, 4,    ; slots 28-37
          0, 5, 1, 5,  2, 5,  3, 6,  4, 5,  5, 5,  6, 5,  7, 5,  8, 5,  9, 5     ; slots 38-47
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
    ubyte sequence_curr_pace_rate = 0
    ubyte sequence_curr_entity_id = 0
    ubyte sequence_curr_entity_numalt = 0
    
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
        level_set_curr_delay = curr_level[level_set_curr_step * 2 + level_set_delay]
        curr_sequence = sequences[curr_level[level_set_curr_step * 2 + level_set_sequence]]
        sequence_curr_step = 0
        
    }
}