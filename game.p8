pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

-- a game object should always have an update and draw function
game_objects = {}

-- @todo change these to be more themed towards candies
elements = {
  -- this a neutral type that applies no weaknesses or resistances
  normal = "normal",
  grass = "grass"
}

animations = {}

#include attacks.p8
#include candies.p8

-- @todo have an end state
game_state = {
  is_player_turn = true,
  listen_for_turn_switch = false,
  switch_turns = function(self)
    self.listen_for_turn_switch = true
  end,
  update = function(self)
    if (self.listen_for_turn_switch) then
      if (#animations == 0) then
        self.is_player_turn = not self.is_player_turn
        self.listen_for_turn_switch = false
        menu:toggle(self.is_player_turn)
      end
    end
  end,
  draw = function(self)
    if (menu.is_visible) then
      print("press z to attack", 30, 43, 2)
    end
  end
}

dialog = {
  x = 7,
  y = 95,
  color = 7,
  current_message = nil,
  message = nil,
  animation_loop = nil,
  trigger = function(self, message)
    self.message = message
    self.animation_loop = cocreate(self.animate_text)
    add(animations, self.animation_loop)
  end,
  animate_text = function(self)
    for i = 1, #self.message + 1 do
      self.current_message = sub(self.message, 1, i)
      yield()
    end
  end,
  update = function(self)
    -- @todo when you press a button before the animation finishes
    -- it should automatically complete the message

    -- @todo when the message completes, require a button press to continue
    -- @todo possibly show a blinking cursor at the end of a completed message
    -- @todo deal with line wraps for long messages

    if (self.animation_loop and costatus(self.animation_loop) != 'dead') then
      coresume(self.animation_loop, self)
    elseif (self.animation_loop and self.current_message) then
      if (btnp(4)) then
        self.current_message = nil
        del(animations, self.animation_loop)
      end
    end
  end,
  draw = function(self)
    if (self.current_message) then
      print(self.current_message, self.x, self.y, self.color)
    end

    if (self.message and self.current_message == self.message) then
      -- @todo make it blink
      -- @todo use a down arrow sprite instead of square
      -- draw end cursor
      local top_left_x = self.x + (#self.message * 4) + 2
      local top_left_y = self.y + 2
      rectfill(
        top_left_x,
        top_left_y,
        top_left_x + 2,
        top_left_y + 2,
        self.color
      )
    end
  end
}

menu = {
  x = 76,
  y = 95,
  current_selection = 1,
  max_attacks = 4,
  is_visible = true,
  toggle = function(self, should_show)
    self.is_visible = should_show
  end,
  update = function(self)
    if not self.is_visible then return end

    -- up
    if btnp(2) then
      self.current_selection -= 1
      if (self.current_selection < 1) then
        self.current_selection = self.max_attacks
      end
    end

    -- down
    if btnp(3) then
      self.current_selection += 1
      if (self.current_selection > self.max_attacks) then
        self.current_selection = 1
      end
    end
  end,
  draw = function(self)
    if not self.is_visible then return end

    -- display attack names
    local attack_display_y = self.y
    for k, attack in pairs(player.attacks) do
      local attack_color = k == self.current_selection and 12 or 7
      print(attack.name, self.x, attack_display_y, attack_color)
      attack_display_y += 7
    end

    -- draw cursor
    if (game_state.is_player_turn) then
      local cursor_y = self.y - 1 + (7 * (self.current_selection - 1))
      spr(15, self.x - 11, cursor_y)
    end

    -- draw divider
    local divider_sprites = {1, 5, 5, 5, 3}
    local x_offset = 12
    local y_offset = 7
    for key,sprite in pairs(divider_sprites) do
      spr(sprite, self.x - x_offset, self.y - y_offset)
      y_offset -= 8
    end
  end
}

-- @todo create another candy and display the name in the draw function
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
    attacks = candy.attacks,
    state = nil, -- maybe to be used for status effects?
    update = function(self)
      -- when you attack, damage the enemy
      if (self.is_player and game_state.is_player_turn and #animations == 0 and btnp(4)) then
        self:selected_attack(enemy)
        game_state:switch_turns()
        menu:toggle(false)
      end

      -- if it's not the player's turn, it's not the player, and no animations are happening
      if (not self.is_player and not game_state.is_player_turn and #animations == 0) then
        self:random_attack(player)
        game_state:switch_turns()
      end
    end,
    random_attack = function(self, victim)
      local random_attack = self.attacks[flr(rnd(4)) + 1]
      self:attack(victim, random_attack)
    end,
    selected_attack = function(self, victim)
      local selected_attack = self.attacks[menu.current_selection]
      self:attack(victim, selected_attack)
    end,
    attack = function(self, victim, selected_attack)
      selected_attack:trigger(victim)
      dialog:trigger(self.name .. " used " .. selected_attack.name)
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
  add(game_objects, game_state)
  player = add(game_objects, make_candy(razor_apple, 10, 68, 8, true))
  enemy = add(game_objects, make_candy(razor_apple, 100, 13, 9, false))
  add(game_objects, menu)
  add(game_objects, dialog)

  for k, attack in pairs(player.attacks) do
    add(game_objects, attack)
  end

  for k, attack in pairs(enemy.attacks) do
    add(game_objects, attack)
  end
end

function _update()
  for k, game_object in pairs(game_objects) do
    game_object:update()
  end
end

function _draw()
  cls()
  map()
  for k, game_object in pairs(game_objects) do
    game_object:draw()
  end
end

__gfx__
0000000000cccccccccccc00c60000000000006cc60000000000006ccccccccc00000000c6000000000000000000006c000000000006c6000006c60000000000
000000000c666666666666c0c60000000000006cc60000000000006c6666666600000000c6000000000000000000006c000000000006c6000006c60000000700
00700700c66000000000066cc60000000000006cc60000000000006c0000000000000000c6000000000000000000006c000000000006c6000006c60000000c70
00077000c60000000000006cc60000000000006cc60000000000006c0000000000000000c6066666666666666666606c666666660006c6000006c60000000cc7
00077000c60000000000006cc60000000000006cc60000000000006c0000000000000000c66cccccccccccccccccc66ccccccccc0006c6000006c60000000cc0
00700700c60000000000006cc66000000000066cc60000000000006c0000000000000000ccc666666666666666666ccc6666c6660006c6000006c60000000c00
00000000c60000000000006c0c666666666666c0c60000000000006c0000000066666666c6600000000000000000066c0006c6000006c6006666c66600000000
00000000c60000000000006c00cccccccccccc00c60000000000006c00000000ccccccccc6000000000000000000006c0006c6000006c600cccccccc00000000
00000000c6cccccccccccc6c00000500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000cc666666666666cc00555755000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c66000000000066c00577775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c60000000000006c00576677500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c60000000000006c05776675000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c60000000000006c00577775000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c60000000000006c00557555000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000c60000000000006c00005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0107070707070707070707070707070200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
1107070707070707070707070707071200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0308080808080808080808080808080400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
