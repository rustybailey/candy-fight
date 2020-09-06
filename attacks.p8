-- animations
function basic_attack_animation(target)
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
end

function screen_shake_animation()
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
end

-- post animations
function apply_damage(attack)
  bonus = attack.candy.attack_power - attack.target.defense_rating
  bonus_multiplier = 1 + (bonus / 100)
  -- don't allow an attack to give back health
  bonus_multiplier = max(bonus_multiplier, 0)

  -- always subtract whole numbers from the health
  attack.target.hp -= flr(attack.power * bonus_multiplier)
  -- don't let target hp fall below zero
  if (attack.target.hp < 0) attack.target.hp = 0
end

-- attacks
punch = {
  name = "punch",
  power = 10,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

kick = {
  name = "kick",
  power = 20,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

rot_teeth = {
  name = "rot teeth",
  power = 25,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

caramelize = {
  name = "caramelize",
  power = 0,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

pop = {
  name = "pop",
  power = 1,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

bang = {
  name = "bang",
  power = 5,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

boom = {
  name = "boom",
  power = 10,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

settle_down = {
  name = "settle down",
  power = 20,
  status_effect = nil,
  animation = basic_attack_animation,
  post_animation = apply_damage
}

function make_attack(candy, attack)
  return {
    candy = candy,
    name = attack.name,
    power = attack.power,
    status_effect = attack.status_effect,
    animation = attack.animation,
    target = nil,
    animation_loops = {},
    post_animation = attack.post_animation,
    trigger = function(self, target)
      -- if the attack has an animation, add it
      if (self.animation) add(self.animation_loops, cocreate(self.animation))
      if (target.is_player) then
        -- if the target is the player, add the screen shake
        add(self.animation_loops, cocreate(screen_shake_animation))
      end
      foreach(self.animation_loops, function(animation_loop)
        add(animations, animation_loop)
      end)
      self.target = target
    end,
    update = function(self)
    end,
    draw = function(self)
      foreach(self.animation_loops, function(animation_loop)
        if (animation_loop and costatus(animation_loop) != 'dead') then
          coresume(animation_loop, self.target)
        else
          del(self.animation_loops, animation_loop)
          del(animations, animation_loop)
        end
      end)

      if (#self.animation_loops == 0 and self.target and self.post_animation) then
        self:post_animation()
        -- no longer attacking so unset the target
        self.target = nil
      end
    end
  }
end