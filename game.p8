pico-8 cartridge // http://www.pico-8.com
version 27
__lua__

-- todo: have an end state
-- todo: move all wait checking functionality inside the game state
game_state = {
  is_player_turn = true,
  wait = 0,
  wait_time = 30,
  switch_turns = function(self)
    self.is_player_turn = not self.is_player_turn
    self.wait = 0
  end,
  update = function(self)
    if (not self.is_player_turn) then
      self.wait += 1
    end
  end,
  draw = function(self)
    print(self.wait, 10, 10, 2)
    if (not self.is_player_turn and self.wait > 0 and self.wait <= self.wait_time) then
      print("enemy is attacking", 30, 60, 2)
    end

    if (self.is_player_turn) then
      print("press z to attack", 30, 60, 2)
    end
  end
}

local types = {
  grass = "grass"
}

-- todo:
-- create attacks and make_attack function
-- may not need a make_attack function if they are all unique
-- each candy will have its unique table of attacks
candies = {}

razor_apple = {
  name = "razor apple",
  sprite = nil,
  hp = 100,
  attack = 100,
  defense = 100,
  element = types.grass
}

-- todo: create another candy and display the name in the draw function

function make_candy(candy, x, y, color, is_player)
  return {
    is_player = is_player,
    x = x,
    y = y,
    width = 16,
    height = 16,
    name = candy.name,
    sprite = candy.sprite,
    hp = candy.hp,
    attack = candy.attack,
    defense = candy.defense,
    element = candy.element,
    state = nil, -- maybe to be used for status effects?
    update = function(self)
      -- when you attack, damage the enemy
      if (self.is_player and game_state.is_player_turn and btnp(4)) then
        self:attack(enemy)
        game_state:switch_turns()
      end

      -- if it's not the player's turn and it's not the player
      -- self.wait x frames, and attack, then pass the turn
      if (not self.is_player) then
        if (game_state.wait > game_state.wait_time) then
          self:attack(player)
          game_state:switch_turns()
        end
      end
    end,
    attack = function(self, victim)
      victim.hp -= 20
      if (victim.hp < 0) victim.hp = 0
    end,
    draw = function(self)
      -- draw character
      rectfill(
        self.x,
        self.y,
        self.x + self.width,
        self.y + self.height,
        color
      )

      -- draw hp (we may move this to a ui object later)
      print("hp " .. self.hp, self.x, self.y - 8, color)
    end
  }
end

function _init()
  player = add(candies, make_candy(razor_apple, 10, 100, 8, true))
  enemy = add(candies, make_candy(razor_apple, 100, 10, 9, false))
end

function _update()
  game_state:update();
  for k, candy in pairs(candies) do
    candy:update()
  end
end

function _draw()
  cls()
  map()
  game_state:draw();
  for k, candy in pairs(candies) do
    candy:draw()
  end
end

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
