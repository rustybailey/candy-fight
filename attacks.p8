function basic_attack_animation(victim)
  x_offset = 0
  y_offset = 0
  animation_frame = 0

  for i = 0, 38 do
    if (i == 15) animation_frame = 0

    -- display sprite in the middle top of the victim for 4 frames
    if (animation_frame <= 3) x_offset = ((victim.width - 1) / 2) - 3.5; y_offset = 0
    -- display sprite in the right middle of the victim for 4 frames
    if (animation_frame > 3 and animation_frame <= 6) x_offset = victim.width - 7; y_offset = ((victim.height - 1) / 2) - 3.5
    -- display sprite in the middle bottom of the victim for 4 frames
    if (animation_frame > 6 and animation_frame <= 9) x_offset = ((victim.width - 1) / 2) - 3.5; y_offset = victim.height - 7
    -- display sprite in the left middle of the victim for 4 frames
    if (animation_frame > 9 and animation_frame <= 12) x_offset = 0; y_offset = ((victim.height - 1) / 2) - 3.5
    -- display sprite in the middle of the victim for 4 frames
    if (animation_frame > 12) x_offset = ((victim.width - 1) / 2) - 3.5; y_offset = ((victim.height - 1) / 2) - 3.5

    animation_frame = animation_frame + 1

    spr(19, victim.x + x_offset, victim.y + y_offset)
    yield()
  end
end

function screen_shake_animation()
  x = 20
  travel = 1

  for i = 0, 30 do
    -- every 5 frames, alternate direction and reduce
    -- shake by 20%
    if (i % 5 == 0) x = x * -1 * travel; travel -= 0.2

    camera(x, 0)
    yield()
  end

  -- reset the camera back
  camera(0, 0)
end

-- attacks
punch = {
  name = "punch",
  power = 25,
  element = elements.normal,
  status_effect = nil,
  animation = basic_attack_animation
}

kick = {
  name = "kick",
  power = 20,
  element = elements.normal,
  status_effect = nil,
  animation = basic_attack_animation
}

rot_teeth = {
  name = "rot teeth",
  power = 25,
  element = elements.normal,
  status_effect = nil,
  animation = basic_attack_animation
}

-- @todo this should raise defense
caramelize = {
  name = "caramelize",
  power = 0,
  element = elements.normal,
  status_effect = nil,
  animation = basic_attack_animation
}

function make_attack(attack)
  return {
    name = attack.name,
    power = attack.power,
    element = attack.element,
    status_effect = attack.status_effect,
    animation = attack.animation,
    victim = nil,
    animation_loops = {},
    trigger = function(self, victim)
      add(self.animation_loops, cocreate(self.animation))
      if (victim.is_player) then
        -- if the victim is the player, add the screen shake
        add(self.animation_loops, cocreate(screen_shake_animation))
      end
      foreach(self.animation_loops, function(animation_loop)
        add(animations, animation_loop)
      end)
      self.victim = victim
    end,
    update = function(self)
    end,
    draw = function(self)
      foreach(self.animation_loops, function(animation_loop)
        if (animation_loop and costatus(animation_loop) != 'dead') then
          coresume(animation_loop, self.victim)
        else
          del(self.animation_loops, animation_loop)
          del(animations, animation_loop)
        end
      end)

      -- if there are no more animations running, handle victim
      -- clean up
      if (#self.animation_loops == 0 and self.victim) then
        self.victim.hp -= self.power
        if (self.victim.hp < 0) self.victim.hp = 0

        -- no longer attacking so unset the victim
        self.victim = nil
      end
    end
  }
end