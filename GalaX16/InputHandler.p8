InputHandler
{
    bool paused = false
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

    sub Init()
    {
        ; init joystick (0 = keyboard)
        joystick.active_joystick = 1
        joystick.clear()
    }
    
    sub IsPaused() -> bool
    {
        return paused
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
        if (newselect != oldselect and newselect == true)
        {
            txt.print("pressed select\n")
        }
        if (newup != oldup and newup == true)
        {
            zsmkit.zsm_close(1)
            zsmkit.zsm_setfile(1, iso:"UFO_16.ZSM")
            zsmkit.zsm_play(1)
            txt.print("pressed up\n")
        }
        if (newdown != olddown and newdown == true)
        {
            zsmkit.zsm_close(2)
            zsmkit.zsm_setfile(2, iso:"UFO_14.ZSM")
            zsmkit.zsm_play(2)
            txt.print("pressed down\n")
        }
        if (newleft != oldleft and newleft == true)
        {
            zsmkit.zsm_close(3)
            zsmkit.zsm_setfile(3, iso:"BOOM_15.ZSM")
            zsmkit.zsm_play(3)
            txt.print("pressed left\n")
        }
        if (newright != oldright and newright == true)
        {
            zsmkit.zsm_close(1)
            zsmkit.zsm_setfile(1, iso:"PEW_16.ZSM")
            zsmkit.zsm_play(1)
            txt.print("pressed right\n")
        }
        if (newfire_a != oldfire_a and newfire_a == true)
        {
            zsmkit.zsm_close(3)
            zsmkit.zsm_setfile(3, iso:"SWEEPDOWNL_15.ZSM")
            zsmkit.zsm_play(3)
            txt.print("pressed a\n")
        }
        if (newfire_b != oldfire_b and newfire_b == true)
        {
            zsmkit.zsm_close(3)
            zsmkit.zsm_setfile(3, iso:"SWEEPUP_15.ZSM")
            zsmkit.zsm_play(3)
            txt.print("pressed b\n")
        }
        if (newfire_l != oldfire_l and newfire_l == true)
        {
            zsmkit.zsm_close(1)
            zsmkit.zsm_setfile(1, iso:"WIBBLE_16.ZSM")
            zsmkit.zsm_play(1)
            txt.print("pressed ls\n")
        }
        if (newfire_r != oldfire_r and newfire_r == true)
        {
            zsmkit.zsm_close(2)
            zsmkit.zsm_setfile(2, iso:"UFO_14.ZSM")
            zsmkit.zsm_play(2)
            txt.print("pressed rs\n")
        }
        if (newfire_x != oldfire_x and newfire_x == true)
        {
            zsmkit.zsm_close(3)
            zsmkit.zsm_setfile(3, iso:"BOOM_15.ZSM")
            zsmkit.zsm_play(3)
            txt.print("pressed x\n")
        }
        if (newfire_y != oldfire_y and newfire_y == true)
        {
            zsmkit.zsm_close(1)
            zsmkit.zsm_setfile(1, iso:"PEW_16.ZSM")
            zsmkit.zsm_play(1)
            txt.print("pressed y\n")
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