
joystick
{
    ubyte active_joystick   ; 0-4 where 0 = the 'keyboard' joystick
    bool up
    bool down
    bool left
    bool right
    bool start
    bool select
    bool fire
    bool fire_a
    bool fire_b
    bool fire_x
    bool fire_y
    bool fire_l
    bool fire_r

    sub scan()
    {
       ;   .A, byte 0:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
       ;               SNES | B | Y |SEL|STA|UP |DN |LT |RT |

       ;   .X, byte 1:      | 7 | 6 | 5 | 4 | 3 | 2 | 1 | 0 |
       ;               SNES | A | X | L | R | 1 | 1 | 1 | 1 |

        ; bits are 0 when a button is down/pressed
        cx16.r1, void = cx16.joystick_get(active_joystick)
        ;txt.print_uw(cx16.r1)
        ;txt.print("\n")
        fire_b = lsb(cx16.r1) & %10000000 == 0
        fire_y = lsb(cx16.r1) & %01000000 == 0
        select = lsb(cx16.r1) & %00100000 == 0
        start  = lsb(cx16.r1) & %00010000 == 0
        up =     lsb(cx16.r1) & %00001000 == 0
        down =   lsb(cx16.r1) & %00000100 == 0
        left =   lsb(cx16.r1) & %00000010 == 0
        right =  lsb(cx16.r1) & %00000001 == 0
        fire_a = msb(cx16.r1) & %10000000 == 0
        fire_x = msb(cx16.r1) & %01000000 == 0
        fire_l = msb(cx16.r1) & %00100000 == 0
        fire_r = msb(cx16.r1) & %00010000 == 0
        ; true for any of the fire buttons being down/pressed
        fire   = cx16.r1 & %1111000011000000 != %1111000011000000
    }

    sub clear()
    {
        fire = false
        fire_a = false
        fire_b = false
        fire_x = false
        fire_y = false
        fire_l = false
        fire_r = false
        start = false
        select = false
        left = false
        right = false
        up = false
        down = false
    }
}
