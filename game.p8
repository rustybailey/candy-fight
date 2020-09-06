pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

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

dialog = {
  x = 8,
  y = 96,
  color = 7,
  max_chars_per_line = 24,
  max_lines = 4,
  init = function(self)
    self.blinking_counter = 0
  end,
  trigger = function(self, message, autoplay)
    -- default autoplay to true
    self.autoplay = type(autoplay) == "nil" and true or autoplay
    self.current_message = ''
    self.messages_by_line = nil
    self.animation_loop = nil
    self.current_line_in_table = 1
    self.current_line_count = 1
    self.pause_dialog = false
    self:format_message(message)
    self.animation_loop = cocreate(self.animate_text)
    add(animations, self.animation_loop)
  end,
  format_message = function(self, message)
    local total_msg = {}
    local word = ''
    local letter = ''
    local current_line_msg = ''

    for i = 1, #message do
      -- get the current letter add
      letter = sub(message, i, i)

      -- keep track of the current word
      word ..= letter

      -- if it's a space or the end of the message,
      -- determine whether we need to continue the current message
      -- or start it on a new line
      if letter == ' ' or i == #message then
        -- get the potential line length if this word were to be added
        local line_length = #current_line_msg + #word
        -- if this would overflow the dialog width
        if line_length > self.max_chars_per_line then
          -- add our current line to the total message table
          add(total_msg, current_line_msg)
          -- and start a new line with this word
          current_line_msg = word
        else
          -- otherwise, continue adding to the current line
          current_line_msg ..= word
        end

        -- if this is the last letter and it didn't overflow
        -- the dialog width, then go ahead and add it
        if i == #message then
          add(total_msg, current_line_msg)
        end

        -- reset the word since we've written
        -- a full word to the current message
        word = ''
      end
    end

    self.messages_by_line = total_msg
  end,
  animate_text = function(self)
    -- for each line, write it out letter by letter
    -- if we each the max lines, pause the coroutine
    -- wait for input in update before proceeding
    for k, line in pairs(self.messages_by_line) do
      self.current_line_in_table = k
      for i = 1, #line do
        self.current_message ..= sub(line, i, i)

        if (i % 5 == 0) sfx(2)
        yield()
      end
      self.current_message ..= '\n'
      self.current_line_count += 1
      if ((self.current_line_count > self.max_lines) or (self.current_line_in_table == #self.messages_by_line and not self.autoplay)) then
        self.pause_dialog = true
        yield()
      end
    end

    if (self.autoplay) then
      delay(30)
    end
  end,
  update = function(self)
    -- @todo when you press a button before the animation finishes
    -- it should automatically complete the message

    if (self.animation_loop and costatus(self.animation_loop) != 'dead') then
      if (not self.pause_dialog) then
        coresume(self.animation_loop, self)
      else
        if btnp(4) then
          self.pause_dialog = false
          self.current_line_count = 1
          self.current_message = ''
        end
      end
    elseif (self.animation_loop and self.current_message) then
      if (self.autoplay) self.current_message = ''
      del(animations, self.animation_loop)
    end

    if (not self.autoplay) then
      self.blinking_counter += 1
      if self.blinking_counter > 30 then self.blinking_counter = 0 end
    end
  end,
  draw = function(self)
    -- display message
    if (self.current_message) then
      print(self.current_message, self.x, self.y, self.color)
    end

    -- draw blinking cursor at the end of the line
    if (not self.autoplay and self.pause_dialog) then
      local sprite_height = 4
      local cursor_x = self.x + ((#self.messages_by_line[self.current_line_in_table] + 1) * 4) - 2
      local cursor_y = self.y + ((self.current_line_count - 1) * 6) - 3

      if self.blinking_counter > 15 then
        spr(32, cursor_x, cursor_y)
      end
    end

    -- debugging formatted message
    -- local offset = 0
    -- for k,line in pairs(self.messages_by_line) do
    --   print(line, 10, 10 + (7 * offset), 10)
    --   offset += 1
    -- end
  end
}

menu = {
  x = 76,
  y = 95,
  max_attacks = 4,
  toggle = function(self, should_show)
    self.is_visible = should_show
  end,
  init = function(self)
    self.is_visible = true
    self.current_selection = 1
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
    for k, attack in pairs(player.attack_objects) do
      local attack_color = k == self.current_selection and 12 or 7
      print(attack.name, self.x, attack_display_y, attack_color)
      attack_display_y += 7
    end

    -- draw cursor
    if (current_scene.is_player_turn) then
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
    width = 32,
    height = 32,
    name = candy.name,
    sprite = candy.sprite,
    hp = candy.hp,
    attack = candy.attack,
    defense = candy.defense,
    element = candy.element,
    attacks = candy.attacks,
    attack_objects = {},
    state = nil, -- maybe to be used for status effects?
    update = function(self)
      if ((player.hp == 0 or enemy.hp == 0) and #animations == 0) then
        return
      end

      -- when you attack, damage the enemy
      if (self.is_player and current_scene.is_player_turn and #animations == 0 and btnp(4)) then
        self:selected_attack(enemy)
        current_scene:switch_turns()
        menu:toggle(false)
      end

      -- if it's not the player's turn, it's not the player, and no animations are happening
      if (not self.is_player and not current_scene.is_player_turn and #animations == 0) then
        self:random_attack(player)
        current_scene:switch_turns()
      end
    end,
    random_attack = function(self, victim)
      local random_attack = self.attack_objects[flr(rnd(4)) + 1]
      self:attack(victim, random_attack)
    end,
    selected_attack = function(self, victim)
      local selected_attack = self.attack_objects[menu.current_selection]
      self:attack(victim, selected_attack)
    end,
    attack = function(self, victim, selected_attack)
      selected_attack:trigger(victim)
      dialog:trigger(self.name .. " used " .. selected_attack.name)
      -- dialog:trigger("this is some really long text that will likely go to the next line you stupid punk")
    end,
    draw = function(self)
      -- draw character
      if (self.sprite) then
        spr(self.sprite, x, y, 4, 4)
      else
        rectfill(
          self.x,
          self.y,
          self.x + self.width,
          self.y + self.height,
          color
        )
      end

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
    end,
    init = function(self)
      foreach(self.attacks, function(attack)
        add(self.attack_objects, make_attack(attack))
      end)
    end
  }
end

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
  switch_turns = function(self)
    self.listen_for_turn_switch = true
  end,
  init = function(self)
    self.is_player_turn = true
    self.listen_for_turn_switch = false

    player = self:add(make_candy(razor_apple, 10, 55, 8, true))
    -- enemy = self:add(make_candy(razor_apple, 100, 13, 9, false))
    enemy = self:add(make_candy(boom_pops, 85, 13, 9, false))
    self:add(menu)
    self:add(dialog)

    foreach(player.attack_objects, function(attack)
      self:add(attack)
    end)

    foreach(enemy.attack_objects, function(attack)
      self:add(attack)
    end)
  end,
  update = function(self)
    if (self.listen_for_turn_switch) then
      if (#animations == 0) then
        self.is_player_turn = not self.is_player_turn
        self.listen_for_turn_switch = false
        menu:toggle(self.is_player_turn)
      end
    end

    -- if anyone's hp is 0, time to end the battle
    if ((player.hp == 0 or enemy.hp == 0) and #animations == 0) then
      change_scene(make_end_screen(player))
    end
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
        if self.did_win then
          change_scene(title_screen)
        else
          change_scene(battle_screen)
        end
      end
    end,
    draw = function(self)
      cls()
      if (self.did_win) then
        -- @todo maybe use dialog here? would need to expand it's capabilities
        -- to display at any y so we can center it in the screen
        print("you win, champ!", 35, 45, 10)
      else
        print("you're a worthless\n piece of garbage", 30, 45, 10)
        print("retry?", 52, 75, 10)
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
      change_scene(story_screen)
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

story_screen = make_scene({
  x = 0,
  y = 88,
  init = function(self)
    self:add(dialog)
    local message = "it was a dark halloween night as you finished up a run of trick or treating. when you arrive home with your friends, you sort through your candy hoping for the best treats. however, as soon as you're about to bite into a delicious candy, it turns out to be more of a trick than a treat, and engages in battle with your friend's candy."
    -- local message = "test"
    dialog:trigger(message, false)
  end,
  update = function(self)
    if (#animations == 0) then
      change_scene(battle_screen)
    end
  end,
  draw = function(self)
    cls()
    map(0, 16)
  end
})

map_screen = make_scene({
  char_sprites = {33, 35, 33, 34},
  starting_circle_x = 10,
  circle_increment = 35,
  init = function(self)
    self.current_sprite_index = 1
    self.animation_timer = 0
    self.start_pos = 1
    self.is_finished_walking = false
    self.character_x = self.starting_circle_x - 4 + (self.circle_increment * (self.start_pos - 1))
    self.next_circle_x = self.character_x + self.circle_increment
  end,
  update = function(self)
    self.animation_timer += 1
    if (self.animation_timer < 15) then
      return
    end

    if (self.is_finished_walking) then
      change_scene(battle_screen)
      return
    end

    if (self.animation_timer % 5 == 0) then
      self.current_sprite_index += 1
      if self.current_sprite_index > #self.char_sprites then
        self.current_sprite_index = 1
      end
    end

    if (self.animation_timer % 2 == 0) then
      self.character_x += 1
    end

    if (self.animation_timer % 10 == 0) then
      sfx(3)
    end

    if (self.character_x >= self.next_circle_x) then
      self.current_sprite_index = 1
      self.is_finished_walking = true
      self.animation_timer = 0
    end
  end,
  draw = function(self)
    cls()
    local circle_x = self.starting_circle_x
    local circle_y = 70
    local circle_increment = self.circle_increment
    local num_circles = 4

    -- draw line
    rectfill(
      self.starting_circle_x,
      circle_y - 1,
      self.starting_circle_x + (self.circle_increment * (num_circles - 1)),
      circle_y + 1,
      3
    )

    -- draw character
    spr(
      self.char_sprites[self.current_sprite_index],
      self.character_x,
      circle_y - 15
    )

    -- @todo: change to 3 and draw skull in last place
    -- draw circles
    for i = 0, num_circles do
      circfill(circle_x, circle_y, 4, 7)
      circle_x += circle_increment
    end
  end
})

-- current_scene = title_screen
-- current_scene = story_screen
-- current_scene = battle_screen
current_scene = map_screen

-- player = {hp = 0}
-- current_scene = make_end_screen(player)

function _init()
  current_scene:init()
end

function _update()
  current_scene:update()
end

profiler_on = false
function _draw()
  current_scene:draw()

  if (profiler_on) then
    print('mem: '.. flr(stat(0)), 0, 0, 7)
    print('cpu: '.. (flr(stat(1) * 100)) .. '%', 0, 8, 7)
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
00000000c6cccccccccccc6c00005000000000000000000bbb00000000000000000000000000000000000000000000000000000000000000a000000000000000
00000000cc666666666666cc0555755000000000000000bbb3b000000000000000000000000000000000000000000000000009000000000099a0000000000000
00000000c66000000000066c057777500000000000004b3333bb00000000000000000000000000000000000000000000000000aa9a00000089000000a0a00000
00000000c60000000000006c0576677500000000000040b3bbb00000000000000000000000000000000000000000000000000098a00000000aa000000999a000
00000000c60000000000006c57766750000000000000400bbb000000000000000000000000000000000000000000000000000a9a900000000000000009890000
00000000c60000000000006c057777500000000000004400000566676600000000000000000000000000000000000000000000000000000000000000a00a0000
00000000c60000000000006c05575550000000000888044088805777666000000000000000000000000000000000000000000000000000000000000000000000
00000000c60000000000006c00050000000088888888884888885677766600000dddddddddddddddddddddddddddd0000dddddddddddddddddddddddddddd000
77777000008888000088880000888800008888888888834388888567660600000dddddddddddddddddddddddddddd0000dedfdddddddddddddddddddddddd000
07770000088888800888888008888880000888888888833388888566666660000dddd77dddddddddddddddddddddd0000ddfdddddddddddddddddefdddddd000
00700000707777077077770770777707000556888888888888888888866606000dd77227ddddddddddddddddddddd0000ddfd6dddddddddddddddeedddddd000
0000000077077077770770777707707700005649a88d888888888888886666000d722222d777d777dd7dddddddddd0000ddddd6ddddddddddddd6dddddddd000
0000000007744770077447700774477000000559a888f88888888888888666600d722dd2722272227d2777dd77ddd0000ddddd77ddddddddddd6ddddddddd000
000000000cccccc07cccccc00cccccc70000065548888f4488888888888666600d722d2227dd27dd27272277227dd0000ddd77997ddddddddd6dddddddddd000
000000007cccccc70ccccc7007ccccc000000056a888844888888888888666600d722dd2227d227d2272d222d227d0000dd799999d777d777dd7ddddddddd000
0000000001100110011000000000011000000056aa8888888d888888888666600dd722dd227d227d227dd22dd227d0000dd799dd9799979997d9777dd77dd000
00000000000000000000000000000000000000569a888888f8888888885666000dd722dd227d227d227d227d227dd0000dd799d9997dd97dd97979977997dd00
00000000000000000000000000000000000000569a888884f4888888888566000dd72222227d227d227dd7dd227dd00000d799dd9997d997d9979d999d997d00
00000000000000000000000000000000000000549488888448888888888560000dd722222722772277dddddd27ddd00000dd799dd997d997d997dd99dd997d00
00000000000000000000000000000000000000569a88888888888888888850000ddd77777d77dd77dddddadd7dddd00000dd799dd997d997d997d997d997dd00
00000000000000000000000000000000000000559a88888888888448888800000ddddd77dddddddddddd8955ddddd00000dd79999997d997d997dd7dd997dd00
00000000000000000000000000000000000000569a888844888884f4888800000ddd77227dddddddddd98add5dddd00000dd799999799779977dddddd97ddd00
0000000000000000000000000000000000000066aa8884f4888888f8888000000dd7222227ddddddddddddddd5ddd00000ddd77777d77dd77dddddddd7dddd00
00000000000000000000000000000000000005569a8888f88848888d888000000d7222dd227dddddddd7777ddd5dd00000dddddddddddddddddd6ddddddddd00
000000000000000000000000000000000000056494888f8884f48888888000000d722ddd2277dd777d722227dd88d00000ddddddd6ddddddddddd6ddddddddd0
00000000000000000000000000000000000056698888d88888f88888888000000d72222d27227722272ddddddd88d00000ddddddd6dddddddddddd6dddddddd0
00000000000000000000000000000000000055994888888888f88888880000000d72222272222722227777dddd88d000000dddddd6ddddddddddddd6ddddddd0
000000000000000000000000000000000005588888888888888f8888880000000dd7227722ddd27dd272227ddd88d000000ddddeddeddddddddddddddfddddd0
0000000000000000000000000000000000088888888888888888d888800000000dd7227722d2227d227ddd27dd88d000000dddddfeddddddddddddddfffdddd0
00000000000000000000000000000000000088888888888888888888000000000dd7227d7222272227777727dd88d000000ddddfdedddddddddddddddeddddd0
00000000000000000000000000000000000008888888000088888880000000000dd727ddd72277227722227ddd88d000000dddddddedddddddddddddddddddd0
00000000000000000000000000000000000000888880000008888800000000000ddd7ddddd77d727dddddddddd88d000000dddddddddddddddddddddddddddd0
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
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0107070707070707070707070707070200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0500000000000000000000000000000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0308080808080808080808080808080400000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
0003000022050190501cb0025b0025b0025b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b0000b00
000300000c1500d150286501d650116500f6500d6500d1000d1000e100121001510019100201002b1003010017500165001550015500185001d50024500275002c5002e500005000050000500005000050000500
000500001f7500a7501e750097501f700087001d7000970020700097001e7001870016700157001570014700147001470016700177001b7002670031700007000070000700007000070000700007000070000700
01080000106550a6001e60009600286002660025600246002460025600276002a6002e60039600006000060000600006000060000600006000060000600006000060000600006000060000600006000060000600
000500001f7000a700127000f7000e7000d7000d7000d7000d7000f700177002b7003070000700007000070000700007000070000700007000070000700007000070000700007000070000700007000070000700
0003000019700197001c7001e70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000400001c70020700267002e70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
