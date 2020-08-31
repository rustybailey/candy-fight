-- attacks
punch = {
  name = "punch",
  power = 25,
  element = elements.normal,
  status_effect = nil,
  animation = function(victim)
    for i = 1, 10 do
      spr(19, victim.x + rnd(10), victim.y + rnd(10))
      yield()
    end
  end
}

kick = {
  name = "kick",
  power = 20,
  element = elements.normal,
  status_effect = nil,
  animation = function(victim)
  end
}

rot_teeth = {
  name = "rot teeth",
  power = 25,
  element = elements.normal,
  status_effect = nil,
  animation = function(victim)
  end
}

-- @todo this should raise defense
caramelize = {
  name = "caramelize",
  power = 0,
  element = elements.normal,
  status_effect = nil,
  animation = function(victim)
  end
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
      end
    end
  }
end