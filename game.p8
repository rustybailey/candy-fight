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

-- helper function to add delay in coroutines
function delay(frames)
  for i = 1, frames do
    yield()
  end
end

function merge_tables(a, b)
  for k,v in pairs(b) do
    a[k] = v
  end
  return a
end

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
  end
}

dialog = {
  x = 8,
  y = 96,
  color = 7,
  current_message = nil,
  message = nil,
  animation_loop = nil,
  max_chars_per_line = 27,
  trigger = function(self, message, autoplay)
    -- default autoplay to true
    self.autoplay = type(autoplay) == "nil" and true or autoplay
    self:format_message(message)
    self.animation_loop = cocreate(self.animate_text)
    add(animations, self.animation_loop)
  end,
  format_message = function(self, message)
    local total_msg = ''
    local word = ''
    local letter = ''
    local delimiter = ''
    self.current_line_msg = ''
    self.num_lines = 1

    for i = 1, #message do
      -- get the current letter add
      letter = sub(message, i, i)

      -- keep track of the current word
      word ..= letter

      -- if it's a space or the end of the message,
      -- determine whether we need to put this word on a new line
      if letter == ' ' or i == #message then
        local line_length = #self.current_line_msg + #word
        if line_length > self.max_chars_per_line then
          word = '\n' .. word
          self.num_lines += 1
          self.current_line_msg = ''
        else
          self.current_line_msg ..= word
        end

        total_msg ..= word
        word = ''
      end
    end

    self.message = total_msg
  end,
  animate_text = function(self)
    for i = 1, #self.message + 1 do
      self.current_message = sub(self.message, 1, i)

      if (i % 5 == 0) sfx(2)
      yield()
    end

    if (self.autoplay) then
      delay(30)
    end
  end,
  update = function(self)
    -- @todo when you press a button before the animation finishes
    -- it should automatically complete the message

    -- @todo possibly show a blinking cursor at the end of a completed message
    -- @todo deal with line wraps for long messages

    if (self.animation_loop and costatus(self.animation_loop) != 'dead') then
      coresume(self.animation_loop, self)
    elseif (self.animation_loop and self.current_message) then
      if (not self.autoplay and btnp(4)) then
        self.current_message = nil
        del(animations, self.animation_loop)
      elseif self.autoplay then
        self.current_message = nil
        del(animations, self.animation_loop)
      end
    end
  end,
  draw = function(self)
    if (self.current_message) then
      print(self.current_message, self.x, self.y, self.color)
    end

    if (not self.autoplay and self.message and self.current_message == self.message) then
      -- @todo make it blink
      -- @todo use a down arrow sprite instead of square
      -- draw end cursor
      local square_height = 2
      local top_left_x = self.x + (#self.current_line * 4) - 2
      local top_left_y = self.y + ((self.number_of_lines) * 6) - square_height - 2
      rectfill(
        top_left_x,
        top_left_y,
        top_left_x + square_height,
        top_left_y + square_height,
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
      sfx(0)
    end

    -- down
    if btnp(3) then
      self.current_selection += 1
      if (self.current_selection > self.max_attacks) then
        self.current_selection = 1
      end
      sfx(0)
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
      -- if anyone's hp is 0, time to end the battle
      if (self.hp == 0 and #animations == 0) then
        change_scene(make_end_screen(player))
      end

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
      -- dialog:trigger("this is some really long text that will likely go to the next line you stupid punk")
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

      -- @todo animate the health bar and hp decreasing
      -- draw name, hp, and health bar
      local hp_text = self.hp .. "/100"
      local name_x = 0
      local hp_x = 0
      local bar_x = 0
      local padding = 7
      -- position player elements to the right
      if (self.is_player) then
        name_x = 128 - (#self.name * 4) - padding
        bar_x = 75
        hp_x = 128 - (#hp_text * 4) - padding
      -- position enemy elements to the left
      else
        name_x = padding + 2
        bar_x = padding
        hp_x = padding + 2
      end

      -- display name
      print(self.name, name_x, self.y, 6)

      -- display health bar
      local bar_length = 46
      local health_length = flr(bar_length * (self.hp / 100))
      line(bar_x, self.y + 8, (bar_x + bar_length), self.y + 8, 2)
      if (self.hp > 0) then
        line(bar_x, self.y + 8, (bar_x + health_length), self.y + 8, 10)
      end

      -- display hp numbers
      print(hp_text, hp_x, self.y + 12, 6)
    end
  }
end

-- @todo tie game_state and other globals to the individual scene
function make_scene(options)
  local o = {
    init = options.init,
    update = options.update,
    draw = options.draw
  }

  local scene = {
    init = function(self)
      self.objects = {}
      if (self.music) then
        music(self.music)
      else
        music(-1)
      end
      o.init(self)
    end,
    add = function(self, object)
      if (object.init) then
        object:init()
      end
      return add(self.objects, object)
    end,
    remove = function(self, object)
      del(self.objects, object)
    end,
    update = function(self)
      if (o.update) then
        o.update(self)
      end
      for k, object in pairs(self.objects) do
        if (object.update) then
          object:update()
        end
      end
    end,
    draw = function(self)
      if (o.draw) then
        o.draw(self)
      end
      for k, object in pairs(self.objects) do
        if (object.draw) then
          object:draw()
        end
      end
    end
  }
  return merge_tables(options, scene)
end

function change_scene(scene)
  current_scene = scene
  current_scene:init()
end

battle_screen = make_scene({
  init = function(self)
    self:add(game_state)
    player = self:add(make_candy(razor_apple, 10, 68, 8, true))
    enemy = self:add(make_candy(razor_apple, 100, 13, 9, false))
    self:add(menu)
    self:add(dialog)

    for k, attack in pairs(player.attacks) do
      self:add(attack)
    end

    for k, attack in pairs(enemy.attacks) do
      self:add(attack)
    end
  end,
  update = function(self)
  end,
  draw = function(self)
    cls()
    map()
  end
})

function make_end_screen(player)
  return make_scene({
    init = function(self)
      self.did_win = player.hp != 0
    end,
    update = function(self)
      if btnp(4) then
        change_scene(title_screen)
      end
    end,
    draw = function(self)
      cls()
      if (self.did_win) then
        -- @todo use dialog here. will need to expand it's capabilities
        -- to display at any y so we can center it in the screen
        print("you win, champ!", 42, 45, 10)
      else
        print("you're a worthless piece of garbage.", 42, 45, 10)
      end
    end
  })
end

title_screen = make_scene({
  init = function(self)
    self.blinking_counter = 0
  end,
  update = function(self)
    self.blinking_counter += 1
    if self.blinking_counter > 30 then self.blinking_counter = 0 end

    if btnp(4) then
      change_scene(battle_screen)
    end
  end,
  draw = function(self)
    cls()

    -- @todo instead of magic numbers, use the word length to help position on x
    print("candy fight", 42, 45, 10)

    if (self.blinking_counter > 15) then
      print("press ❎ or 🅾️ to start", 20, 70, 10)
    end

    print("a game by", 2, 100, 10)
    print("rusty bailey &", 2, 107, 10)
    print("matt rathbun", 2, 114, 10)
  end
})

current_scene = title_screen
-- current_scene = battle_screen

-- player = {hp = 0}
-- current_scene = make_end_screen(player)

function _init()
  current_scene:init()
end

function _update()
  current_scene:update()
end

function _draw()
  current_scene:draw()
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
__sfx__
0003000022050190501cb0025b0025b0025b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b00
000300000c1500d150286501d650116500f6500d6500d1000d1000e100121001510019100201002b1003010017500165001550015500185001d50024500275002c5002e500005000050000500005000050000500
000500001f7500a7501e750097501f700087001d7000970020700097001e7001870016700157001570014700147001470016700177001b7002670031700007000070000700007000070000700007000070000700
000500001f7000a7001e70009700287002670025700247002470025700277002a7002e70039700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
000500001f7000a700127000f7000e7000d7000d7000d7000d7000f700177002b7003070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0003000019700197001c7001e70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001c70020700267002e70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
