animations = {
  basic_attack = function(self)
    local target = self.opponent
    local x_offset = 0
    local y_offset = 0
    local animation_frame = 0

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
  bleed = function(self)
    local target = self.opponent
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
  end,
  poison = function(self)
    local target = self.opponent
    local starting_positions = {
      {target.x + 7, target.y + 10},
      {target.x - 3, target.y + 13},
      {target.x + 2, target.y + 17},
    }
    for i = 1, 3 do
      local x = starting_positions[i][1]
      local y = starting_positions[i][2]
      for i = 1, 15 do
        pal(8, 1)
        spr(16, x, y)
        pal()
        y += 1
        yield()
      end
    end
  end,
  rot = function(self)
    local target = self.opponent
    local starting_positions = {
      {target.x + 7, target.y + 10},
      {target.x - 3, target.y + 13},
      {target.x + 2, target.y + 17},
    }
    for i = 1, 3 do
      local x = starting_positions[i][1]
      local y = starting_positions[i][2]
      for i = 1, 15 do
        pal(8, 5)
        spr(16, x, y)
        pal()
        y += 1
        yield()
      end
    end
  end,
  heal = function(self)
    local target = self.candy
    local origin_x = target.x + 15
    local origin_y = target.y + 15
    local radius = 20
    local circles = {
      {angle = 1, color = 7},
      {angle = .96, color = 6},
      {angle = .92, color = 14},
      {angle = .88, color = 10},
    }
    local rotations = 0
    local max_rotations = 2
    sfx(35)
    while (rotations < (max_rotations * #circles)) do
      local rotated = false
      for i = 1, #circles do
        circles[i].angle -= 0.04
        if (circles[i].angle < 0) then
          circles[i].angle = 1
          rotated = true
        end
        local x = origin_x + radius * cos(circles[i].angle)
        local y = origin_y + radius * sin(circles[i].angle)
        circfill(x, y, 2, circles[i].color)
      end
      if (rotated) then rotations += 1 end
      yield()
    end
  end,
  slice = function(self)
    local target = self.opponent
    local x = target.x
    local y = target.y
    local sword_x1 = x + 15
    local sword_y1 = y + 10
    local sword_x2 = sword_x1 + 5
    local sword_y2 = sword_y1 - 10

    local sprite_x = sword_x1 - 12
    local sprite_y = sword_y1 - 12

    for i = 1, 25 do
      if (i == 6 or i == 16) then
        sfx(36)
      end

      if (i <= 5) then
        line(sword_x1, sword_y1, sword_x2, sword_y2, 7)
      elseif (i > 5 and i <= 7) then
        spr(196, sprite_x, sprite_y, 4, 4)
      elseif (i > 7 and i <= 9) then
        spr(200, sprite_x, sprite_y, 4, 4)
      elseif (i > 9 and i <= 15) then
        line(sword_x1, sword_y1, sword_x2, sword_y2, 7)
      elseif (i > 15 and i <= 17) then
        spr(196, sprite_x, sprite_y, 4, 4)
      elseif (i > 17 and i <= 19) then
        spr(200, sprite_x, sprite_y, 4, 4)
      elseif (i > 19 and i <= 25) then
        line(sword_x1, sword_y1, sword_x2, sword_y2, 7)
      end
      yield()
    end
  end,
  debuff = function(self)
    local target = self.opponent
    local start_x = target.x - 5
    local start_y = target.y - 5
    for i = 1, 3 do
      local x = start_x
      local y = start_y
      sfx(33)
      for i = 1, 15 do
        spr(49, x, y)
        y += 1
        yield()
      end
    end
  end,
  buff = function(self)
    local target = self.candy
    local start_x = target.x - 5
    local start_y = target.y - 5 + 15
    for i = 1, 3 do
      local x = start_x
      local y = start_y
      sfx(34)
      for i = 1, 15 do
        pal(13, 12)
        spr(49, x, y, 1, 1, false, true)
        pal()
        y -= 1
        yield()
      end
    end
  end,
  explosion = function(self)
    local target = self.opponent
    local circle_x = target.x + 15
    local circle_y = target.y + 15
    local radius = 12

    sfx(37)
    for i = 1, 15 do
      if (i <= 2) then
        -- black circle
        circfill(circle_x, circle_y, radius, 0)
      elseif (i > 2 and i <= 4) then
        -- white circle
        circfill(circle_x, circle_y, radius, 7)
      elseif (i > 4 and i <= 8) then
        -- blast
        spr(192, circle_x - radius, circle_y - radius, 4, 4)
      elseif (i > 9 and i <= 13) then
        -- smoke
        circfill(target.x + 5, target.y + 5, 5, 5)
        circfill(target.x + 15, target.y + 7, 5, 5)
        circfill(target.x + 20, target.y + 15, 5, 5)
        circfill(target.x + 7, target.y + 15, 5, 5)
        circfill(target.x + 20, target.y + 25, 5, 5)
        -- fire
        circfill(target.x + 6, target.y + 6, 5, 9)
        circfill(target.x + 17, target.y + 5, 5, 9)
        circfill(target.x + 15, target.y + 20, 5, 9)
      elseif (i > 13 and i <= 15) then
        -- smoke
        circfill(target.x + 7, target.y + 7, 5, 5)
        circfill(target.x + 12, target.y + 10, 5, 5)
        circfill(target.x + 20, target.y + 30, 5, 5)
      end
      yield()
    end
  end
}