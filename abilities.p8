effects = {
  damage = function(ability)
    bonus = ability.candy.attack_power - ability.opponent.defense_rating
    bonus_multiplier = 1 + (bonus / 100)
    -- don't allow an attack ability to give back health
    bonus_multiplier = max(bonus_multiplier, 0)

    -- always subtract whole numbers from the health
    damage = flr(ability.power * bonus_multiplier)
    ability.opponent.hp -= damage
    -- don't let opponent hp fall below zero
    if (ability.opponent.hp < 0) ability.opponent.hp = 0
    dialog:queue(ability.opponent.name.." was hit for "..damage.." damage")
  end,
  apply_statuses = function(ability)
    foreach(ability.status_effects, function(status_effect)
      status_effect_ability = make_ability(ability.candy, status_effect)
      add(ability.opponent.status_effects, status_effect_ability)
      -- @todo this doesn't feel great here
      current_scene:add(status_effect_ability)
      dialog:queue(ability.candy.name.." used "..ability.name)
      dialog:queue(ability.opponent.name.." was affected by "..status_effect.name)
    end)
  end,
  reduce_attack_power = function(ability)
    ability.opponent.attack_power *= (1 - (ability.power / 100))
    -- don't let attack power fall below 0
    ability.opponent.attack_power = max(ability.opponent.attack_power, 0)
  end,
  reduce_defense_rating = function(ability)
    ability.opponent.defense_rating *= (1 - (ability.power / 100))
    -- don't let defense rating fall below 0
    ability.opponent.defense_rating = max(ability.opponent.defense_rating, 0)
  end,
  heal = function(ability)
    ability.candy.hp += ability.power

    -- don't allow the heal to give more than max hp
    ability.candy.hp = min(ability.candy.hp, ability.candy.max_hp)
  end
}

status_effects = {
  bleed = {
    name = "bleed",
    power = 10,
    duration = 2,
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  rot = {
    name = "rot",
    power = 4,
    duration = 5,
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  }
}

abilities = {
  throw_razor = {
    name = "throw razor",
    power = nil,
    status_effects = {
      status_effects.bleed
    },
    animation = animations.basic_attack,
    effects = {
      effects.apply_statuses
    }
  },
  bash = {
    name = "bash",
    power = 14,
    status_effects = {},
    animation = nil,
    effects = {
      effects.damage
    }
  },
  rot_teeth = {
    name = "rot teeth",
    power = nil,
    status_effects = {
      status_effects.rot
    },
    animation = animations.basic_attack,
    effects = {
      effects.apply_statuses
    }
  },
  caramelize = {
    name = "caramelize",
    power = 10,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.reduce_attack_power
    }
  },
  pop = {
    name = "pop",
    power = 5,
    status_effects = nil,
    animation = animations.basic_attack,
    effects = {
      effects.damage,
      effects.reduce_defense_rating
    }
  },
  acid_spit = {
    name = "acid spit",
    power = nil,
    status_effects = {
      status_effects.bleed
    },
    animation = animations.basic_attack,
    effects = {
      effects.apply_statuses
    }
  },
  boom = {
    name = "boom",
    power = 20,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  settle_down = {
    name = "settle down",
    power = 10,
    status_effects = nil,
    animation = animations.basic_attack,
    effects = {
      effects.attack,
      effects.reduce_attack_power
    }
  }
}

function make_ability(candy, ability)
  return {
    candy = candy,
    name = ability.name,
    power = ability.power,
    status_effects = ability.status_effects,
    duration = ability.duration,
    animation = ability.animation,
    opponent = nil,
    animation_loops = {},
    effects = ability.effects,
    was_triggered = false,
    trigger = function(self, opponent)
      -- if the ability has duration, subtract from it
      if (self.duration != nil and self.duration > 0) self.duration -= 1
      -- if the ability has an animation, add it
      if (self.animation) add(self.animation_loops, cocreate(self.animation))
      if (opponent.is_player) then
        -- if the opponent is the player, add the screen shake
        add(self.animation_loops, cocreate(animations.screen_shake))
      end
      foreach(self.animation_loops, function(animation_loop)
        add(animations, animation_loop)
      end)
      self.opponent = opponent
      self.was_triggered = true
    end,
    update = function(self)
    end,
    draw = function(self)
      foreach(self.animation_loops, function(animation_loop)
        if (animation_loop and costatus(animation_loop) != 'dead') then
          coresume(animation_loop, self.opponent)
        else
          del(self.animation_loops, animation_loop)
          del(animations, animation_loop)
        end
      end)

      -- if all animations have run, clean up
      if (self.was_triggered and #self.animation_loops == 0) then
        if (self.effects != nil and #self.effects > 0) then
          foreach(self.effects, function(effect)
            effect(self)
          end)
        end
        -- no longer using ability so unset the opponent
        self.opponent = nil
        self.was_triggered = false
      end
    end
  }
end