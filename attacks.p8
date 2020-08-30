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
  status_effect = nil
}

rot_teeth = {
  name = "rot teeth",
  power = 25,
  element = elements.normal,
  status_effect = nil
}

-- @todo this should raise defense
caramelize = {
  name = "caramelize",
  power = 0,
  element = elements.normal,
  status_effect = nil
}