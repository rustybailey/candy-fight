animations = {
  basic_attack = function(target)
    x_offset = 0
    y_offset = 0
    animation_frame = 0

    for i = 0, 20 do
      if (i == 0) sfx(1)
      if (i == 10) animation_frame = 0

      -- display sprite in the middle top of the target for 4 frames
      if (animation_frame <= 2) x_offset = ((target.width - 1) / 2) - 3.5; y_offset = 0
      -- display sprite in the right middle of the target for 4 frames
      if (animation_frame > 2 and animation_frame <= 4) x_offset = target.width - 7; y_offset = ((target.height - 1) / 2) - 3.5
      -- display sprite in the middle bottom of the target for 4 frames
      if (animation_frame > 4 and animation_frame <= 6) x_offset = ((target.width - 1) / 2) - 3.5; y_offset = target.height - 7
      -- display sprite in the left middle of the target for 4 frames
      if (animation_frame > 6 and animation_frame <= 8) x_offset = 0; y_offset = ((target.height - 1) / 2) - 3.5
      -- display sprite in the middle of the target for 4 frames
      if (animation_frame > 8) x_offset = ((target.width - 1) / 2) - 3.5; y_offset = ((target.height - 1) / 2) - 3.5

      animation_frame = animation_frame + 1

      spr(19, target.x + x_offset, target.y + y_offset)
      yield()
    end
  end,
  screen_shake = function()
    x = 20
    travel = 1

    for i = 0, 15 do
      -- every 3 frames, alternate direction and reduce
      -- shake by 20%
      if (i % 3 == 0) x = x * -1 * travel; travel -= 0.2

      camera(x, 0)
      yield()
    end

    -- reset the camera back
    camera(0, 0)
  end,
  bleed = function(target)
    local starting_positions = {
      {target.x + 7, target.y + 10},
      {target.x - 3, target.y + 13},
      {target.x + 2, target.y + 17},
    }
    for i = 1, 3 do
      local x = starting_positions[i][1]
      local y = starting_positions[i][2]
      for i = 1, 15 do
        spr(16, x, y)
        y += 1
        yield()
      end
    end
  end
}