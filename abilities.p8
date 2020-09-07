effects = {
  damage = function(ability)
    bonus = ability.candy.attack_power - ability.target.defense_rating
    bonus_multiplier = 1 + (bonus / 100)
    -- don't allow an attack ability to give back health
    bonus_multiplier = max(bonus_multiplier, 0)

    -- always subtract whole numbers from the health
    ability.target.hp -= flr(ability.power * bonus_multiplier)
    -- don't let target hp fall below zero
    if (ability.target.hp < 0) ability.target.hp = 0
  end,
  apply_statuses = function(ability)
    if (ability.status_effects != nil and #ability.status_effects > 0) then
      foreach(ability.status_effects, function(status_effect)
        status_effect_ability = make_ability(ability.candy, status_effect)
        add(ability.target.status_effects, status_effect_ability)
        -- @todo this doesn't feel great here
        current_scene:add(status_effect_ability)
      end)
    end
  end
}

status_effects = {
  rot = {
    name = "rot",
    power = 10,
    duration = 5,
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  }
}

abilities = {
  punch = {
    name = "punch",
    power = 10,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  kick = {
    name = "kick",
    power = 20,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  rot_teeth = {
    name = "rot teeth",
    power = nil,
    status_effects = {
      -- status effect rot with modified values
      merge_tables(
        status_effects.rot,
        {
          power = 5,
          duration = 3
        }
      )
    },
    animation = animations.basic_attack,
    effects = {
      effects.apply_statuses
    }
  },
  caramelize = {
    name = "caramelize",
    power = 0,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  pop = {
    name = "pop",
    power = 1,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  bang = {
    name = "bang",
    power = 5,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  boom = {
    name = "boom",
    power = 10,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
    }
  },
  settle_down = {
    name = "settle down",
    power = 20,
    status_effects = {},
    animation = animations.basic_attack,
    effects = {
      effects.damage
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
    target = nil,
    animation_loops = {},
    effects = ability.effects,
    trigger = function(self, target)
      -- if the ability has duration, subtract from it
      if (self.duration != nil and self.duration > 0) self.duration -= 1
      -- if the ability has an animation, add it
      if (self.animation) add(self.animation_loops, cocreate(self.animation))
      if (target.is_player) then
        -- if the target is the player, add the screen shake
        add(self.animation_loops, cocreate(animations.screen_shake))
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

      -- if all animations have run and there is a target, clean up
      if (#self.animation_loops == 0 and self.target) then
        if (self.effects != nil and #self.effects > 0) then
          foreach(self.effects, function(effect)
            effect(self)
          end)
        end
        -- no longer using ability so unset the target
        self.target = nil
      end
    end
  }
end