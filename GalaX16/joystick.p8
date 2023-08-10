
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
        ; bits are 0 when a button is down/pressed
        cx16.r1 = cx16.joystick_get2(active_joystick)
        fire_a = lsb(cx16.r1) & %10000000 == 0
        fire_x = lsb(cx16.r1) & %01000000 == 0
        select = lsb(cx16.r1) & %00100000 == 0
        start  = lsb(cx16.r1) & %00010000 == 0
        up =     lsb(cx16.r1) & %00001000 == 0
        down =   lsb(cx16.r1) & %00000100 == 0
        left =   lsb(cx16.r1) & %00000010 == 0
        right =  lsb(cx16.r1) & %00000001 == 0
        fire_b = msb(cx16.r1) & %10000000 == 0
        fire_y = msb(cx16.r1) & %01000000 == 0
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
