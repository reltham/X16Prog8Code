InputHandler
{
    bool oldup = false
    bool olddown = false
    bool oldleft = false
    bool oldright = false
    bool oldstart = false
    bool oldselect = false
    bool oldfire = false
    bool oldfire_a = false
    bool oldfire_b = false
    bool oldfire_x = false
    bool oldfire_y = false
    bool oldfire_l = false
    bool oldfire_r = false

    bool fire_bullet = false
    bool pressed_start = false
    bool pressed_select = false

    sub Init()
    {
        ; init joystick (0 = keyboard)
        joystick.active_joystick = 1
        joystick.clear()
    }

    sub DoScan()
    {
        joystick.scan()
        bool newup = joystick.up
        bool newdown = joystick.down
        bool newleft = joystick.left
        bool newright = joystick.right
        bool newstart = joystick.start
        bool newselect = joystick.select
        bool newfire = joystick.fire
        bool newfire_a = joystick.fire_a
        bool newfire_b = joystick.fire_b
        bool newfire_x = joystick.fire_x
        bool newfire_y = joystick.fire_y
        bool newfire_l = joystick.fire_l
        bool newfire_r = joystick.fire_r
        if (newstart != oldstart and newstart == true)
        {
            pressed_start = true
        }
        if (newselect != oldselect and newselect == true)
        {
            pressed_select = true
        }
        /*
        if (newup != oldup and newup == true)
        {
        }
        if (newdown != olddown and newdown == true)
        {
        }
        if (newleft != oldleft and newleft == true)
        {
        }
        if (newright != oldright and newright == true)
        {
        }
        */
        if (newfire_a != oldfire_a and newfire_a == true)
        {
            fire_bullet = true
        }
        if (newfire_b != oldfire_b and newfire_b == true)
        {
            Sounds.PlaySFX(9)
        }
        if (newfire_l != oldfire_l and newfire_l == true)
        {
            Sounds.PlaySFX(10)
        }
        if (newfire_r != oldfire_r and newfire_r == true)
        {
            Sounds.PlaySFX(0)
        }
        if (newfire_x != oldfire_x and newfire_x == true)
        {
            Sounds.PlaySFX(7)
        }
        if (newfire_y != oldfire_y and newfire_y == true)
        {
            Sounds.PlaySFX(8)
        }
        oldup = newup
        olddown = newdown
        oldleft = newleft
        oldright = newright
        oldstart = newstart
        oldselect = newselect
        oldfire = newfire
        oldfire_a = newfire_a
        oldfire_b = newfire_b
        oldfire_x = newfire_x
        oldfire_y = newfire_y
        oldfire_l = newfire_l
        oldfire_r = newfire_r
    }
}