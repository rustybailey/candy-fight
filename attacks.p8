function basic_attack_animation(victim)
  victim_center_x = flr(victim.width / 2) + victim.x
  victim_center_y = flr(victim.height / 2) + victim.y

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
    animation_loop = nil,
    trigger = function(self, victim)
      self.animation_loop = cocreate(self.animation)
      add(animations, self.animation_loop)
      self.victim = victim
    end,
    update = function(self)
    end,
    draw = function(self)
      if (self.animation_loop and costatus(self.animation_loop) != 'dead') then
        coresume(self.animation_loop, self.victim)
      elseif (self.animation_loop and self.victim) then
        -- apply the damage once the animation ends
        self.victim.hp -= self.power
        if (self.victim.hp < 0) self.victim.hp = 0

        -- no longer attacking so unset the victim
        self.victim = nil
        del(animations, self.animation_loop)
      end
    end
  }
end