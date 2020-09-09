pico-8 cartridge // http://www.pico-8.com
version 29
__lua__

screen_width = 128
function center_print(message, y, color)
  local width = #message * 4
  local x = (screen_width - width) / 2
  print(message, x, y, color)
end

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

-- del by index - doesn't keep order!!
-- using this so we can shift the first element from the array
function idelr(t,i)
  local n=#t
  if (i>0 and i<=n) then
    t[i]=t[n]
    t[n]=nil
  end
end

function shuffle_table(table)
  -- do a fisher-yates shuffle
  for i = #table, 1, -1 do
    local j = flr(rnd(i)) + 1
    table[i], table[j] = table[j], table[i]
  end
end

animations = {}

#include animations.p8
#include abilities.p8
#include candies.p8

dialog = {
  x = 8,
  y = 96,
  color = 7,
  max_chars_per_line = 27,
  max_lines = 4,
  dialog_queue = {},
  init = function(self)
    self.blinking_counter = 0
  end,
  queue = function(self, message, autoplay)
    autoplay = type(autoplay) == "nil" and true or autoplay
    add(self.dialog_queue, {
      message = message,
      autoplay = autoplay
    })

    if (#self.dialog_queue == 1) then
      self:trigger(self.dialog_queue[1].message, self.dialog_queue[1].autoplay)
    end
  end,
  trigger = function(self, message, autoplay)
    -- default autoplay to true
    self.autoplay = autoplay
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
      for i = 1, #line, 2 do
        self.current_message ..= sub(line, i, i + 1)

        -- press btn 5 to skip to the end of the current passage
        -- otherwise, print 1 character per frame
        -- with sfx about every 5 frames
        if (not btnp(5)) then
          if (i % 5 == 0) sfx(2)
          yield()
        end
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
      self.animation_loop = nil
    end

    if (not self.animation_loop and #self.dialog_queue > 0) then
      idelr(self.dialog_queue, 1)
      if (#self.dialog_queue > 0) then
        self:trigger(self.dialog_queue[1].message, self.dialog_queue[1].autoplay)
        coresume(self.animation_loop, self)
      end
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

    -- draw blinking cursor at the bottom right
    if (not self.autoplay and self.pause_dialog) then
      if self.blinking_counter > 15 then
        if (self.current_line_in_table == #self.messages_by_line) then
          rectfill(
            screen_width - 11,
            screen_width - 10,
            screen_width - 11 + 3,
            screen_width - 10 + 3,
            7
          )
        else
          spr(32, screen_width - 12, screen_width - 9)
        end
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
  max_abilities = 4,
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
        self.current_selection = self.max_abilities
      end
      sfx(0)
    end

    -- down
    if btnp(3) then
      self.current_selection += 1
      if (self.current_selection > self.max_abilities) then
        self.current_selection = 1
      end
      sfx(0)
    end
  end,
  draw = function(self)
    if not self.is_visible then return end

    -- display ability names
    local ability_display_y = self.y
    for k, ability in pairs(player.ability_objects) do
      local ability_color = k == self.current_selection and 12 or 7
      print(ability.name, self.x, ability_display_y, ability_color)
      ability_display_y += 7
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
    max_hp = candy.max_hp,
    attack_power = candy.attack_power,
    defense_rating = candy.defense_rating,
    abilities = candy.abilities,
    ability_objects = {},
    status_effects = {},
    update = function(self)
      if ((player.hp == 0 or enemy.hp == 0) and #animations == 0) then
        return
      end

      if (self.wait_to_apply_status_effects and #animations == 0) then
        self:apply_status_effects()
        current_scene:switch_turns()
        return
      end

      -- when you use an ability, do something
      if (self.is_player and current_scene.is_player_turn and #animations == 0 and btnp(4)) then
        self:selected_ability(enemy)
        self.wait_to_apply_status_effects = true
        menu:toggle(false)
      end

      -- if it's not the player's turn, it's not the player, and no animations are happening
      if (not self.is_player and not current_scene.is_player_turn and #animations == 0) then
        self:random_ability(player)
        self.wait_to_apply_status_effects = true
      end
    end,
    random_ability = function(self, opponent)
      foreach(self.ability_objects, function(ability_object)
        printh(ability_object.name)
      end)

      local random_ability = self.ability_objects[flr(rnd(4)) + 1]
      self:use_ability(opponent, random_ability)
    end,
    selected_ability = function(self, opponent)
      local selected_ability = self.ability_objects[menu.current_selection]
      self:use_ability(opponent, selected_ability)
    end,
    use_ability = function(self, opponent, selected_ability)
      dialog:queue(self.name .. " used " .. selected_ability.name)
      selected_ability:trigger(opponent)
    end,
    wait_to_apply_status_effects = false,
    apply_status_effects = function(self)
      self.wait_to_apply_status_effects = false
      if (#self.status_effects > 0) then
        foreach (self.status_effects, function(status_effect)
          -- @todo add status effects to current scene here if not already added
          -- if the status effect has no more duration, clean it up
          if (status_effect.duration == 0) then
            dialog:queue("the effects of " .. status_effect.name .. " on " .. self.name .. " have worn off...")
            del(self.status_effects, status_effect)
            current_scene:remove(status_effect)
            -- dereference to avoid a memory leak
            status_effect = nil
          else
            dialog:queue(self.name .. " was affected by " .. status_effect.name)
            status_effect:trigger(self)
          end
        end)
      end
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
        name_x = screen_width - (#self.name * 4) - padding
        bar_x = 75
        hp_x = screen_width - (#hp_text * 4) - padding
        ui_y = 66
      -- position enemy elements to the left
      else
        name_x = padding + 2
        bar_x = padding
        hp_x = padding + 2
        ui_y = 8
      end

      -- display name
      print(self.name, name_x, ui_y, 6)

      -- display health bar
      local bar_length = 46
      local health_length = flr(bar_length * (self.hp / 100))
      local bar_y = ui_y + 8
      -- background bar
      line(bar_x, bar_y, (bar_x + bar_length), bar_y, 2)
      -- health percentage
      if (self.hp > 0) then
        local line_color = 0
        if self.hp <= 100 and self.hp >= 75 then
          line_color = 11
        elseif self.hp <= 74 and self.hp >= 25 then
          line_color = 10
        else
          line_color = 8
        end
        line(bar_x, bar_y, (bar_x + health_length), bar_y, line_color)
      end

      -- display hp numbers
      print(hp_text, hp_x, ui_y + 12, 6)


      -- for debugging why turns weren't proceeding
      -- center_print("is player turn: " .. (current_scene.is_player_turn and "true" or "false"), 30, 7)
      -- center_print("number animations: " .. #animations, 40, 7)
    end,
    init = function(self)
      foreach(self.abilities, function(ability)
        add(self.ability_objects, make_ability(self, ability))
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

function make_battle_scene(player_candy, enemy_candy)
  return make_scene({
    switch_turns = function(self)
      self.listen_for_turn_switch = true
    end,
    end_battle = function(self)
      if (enemy.hp == 0 and current_battle < #battle_enemies) then
        change_scene(map_screen)
      else
        change_scene(make_end_screen(player))
      end
    end,
    init = function(self)
      self.is_player_turn = true
      self.listen_for_turn_switch = false

      local candy_x_padding = 15
      local player_x = candy_x_padding
      local enemy_x = screen_width - candy_x_padding - 32
      player = self:add(make_candy(player_candy, player_x, 48, 8, true))
      enemy = self:add(make_candy(enemy_candy, enemy_x, 13, 9, false))
      self:add(menu)
      self:add(dialog)

      foreach(player.ability_objects, function(ability)
        self:add(ability)
      end)

      foreach(enemy.ability_objects, function(ability)
        printh(ability.name)
        self:add(ability)
      end)

      -- each battle beyond the first, give the enemy
      -- 10 more to each stat
      enemy.hp += 10 * (current_battle - 1)
      enemy.max_hp += 10 * (current_battle - 1)
      enemy.attack_power += 10 * (current_battle - 1)
      enemy.defense_rating += 10 * (current_battle - 1)
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
        self:end_battle()
      end
    end,
    draw = function(self)
      cls()
      map()
    end,
    music = 0
  })
end

colors_light_to_dark = {10,7,15,11,6,9,12,14,13,3,8,4,5,2,1}
function make_end_screen(player)
  local did_win = player.hp != 0
  local fanfare = did_win and 4 or 7
  return make_scene({
    music = fanfare,
    init = function(self)
      self.did_win = did_win
      self.counter = 0
      self.text_color_index = 1
    end,
    update = function(self)
      self.counter += 1

      self.text_color_index += 1
      if (self.text_color_index % #colors_light_to_dark == 0) self.text_color_index = 1


      if btnp(4) then
        if self.did_win then
          change_scene(title_screen)
        else
          change_scene(make_battle_scene(player_candy, battle_enemies[current_battle]))
        end
      end
    end,
    draw = function(self)
      cls()
      if (self.did_win) then
        center_print(
          "you win, champ!",
          45,
          colors_light_to_dark[self.text_color_index]
        )

        local chord_1 = 64
        local chord_2 = 96
        local chord_3 = 128
        local end_of_fanfare = 160
        local thanks_x = 28
        local thanks_y = 75
        if (self.counter > end_of_fanfare) then
          center_print("thanks for playing", thanks_y, 9)
        elseif (self.counter > chord_3) then
          print("thanks for playing", thanks_x, thanks_y, 7)
        elseif (self.counter > chord_2) then
          print("thanks for", thanks_x, thanks_y, 7)
        elseif (self.counter > chord_1) then
          print("thanks", thanks_x, thanks_y, 7)
        end
      else
        center_print("you've lost the", 45, 9)
        center_print("battle with living candy", 52, 9)

        if (self.counter > 48 and self.counter % 30 > 15) then
          center_print("Press z to try again", 75, 9)
        end
      end
    end
  })
end

title_screen = make_scene({
  music = 8,
  init = function(self)
    current_battle = 1

    self.logo_x = 30
    self.logo_y = 30
    self.counter = 0
    self.cloud_lines = {}
    self.cloud_loop = 0
    local starting_cloud_x = self.logo_x + 25
    local cloud_y = self.logo_y + 14
    for i = 1, 14 do
      add(self.cloud_lines, {
        x = starting_cloud_x + flr(rnd(30) + 10),
        y = cloud_y,
        width = flr(rnd(30) + 20)
      })
      cloud_y += 2
    end

    -- randomize the player and enemies
    shuffle_table(candies)

    player_candy = candies[1]
    battle_enemies = {}

    for i = 2, #candies do
      printh(candies[i].name)
      add(battle_enemies, candies[i])
    end
  end,
  update = function(self)
    self.counter += 1
    if self.counter >= 30 then self.counter = 0 end

    if btnp(4) then
      change_scene(story_screen)
    end
  end,
  draw = function(self)
    cls()

    -- the moon
    circfill(self.logo_x + 35, self.logo_y + 10, 20, 6)

    -- clouds
    for k, cloud_line in pairs(self.cloud_lines) do
      if (self.counter % 15 == 0) then
        cloud_line.x -= 1
      end
      line(
        cloud_line.x,
        cloud_line.y,
        cloud_line.x + cloud_line.width,
        cloud_line.y,
        7
      )
    end

    -- "full"
    local full_height = 12
    sspr(
      0,
      32,
      35,
      full_height,
      self.logo_x,
      self.logo_y
    )
    -- "moon sweet"
    sspr(
      0,
      44,
      41,
      37,
      self.logo_x,
      self.logo_y + full_height
    )

    if (self.counter > 15) then
      center_print("press z to start", 84, 9)
    end

    print("a game by", 2, 100, 6)
    print("rusty bailey &", 2, 107, 6)
    print("matt rathbun", 2, 114, 6)
  end
})

story_screen = make_scene({
  music = 2,
  init = function(self)
    self.t = 0
    self:add(dialog)
    local message = "it was a dark halloween night as you finished up a run of trick or treating. when you arrive home with your friends, you sort through your candy hoping for the best treats. however, as soon as you're about to bite into a delicious candy, it turns out to be more of a trick than a treat, and engages in battle with your friend's candy."
    dialog:queue(message, false)
  end,
  update = function(self)
    if (#animations == 0) then
      change_scene(make_battle_scene(player_candy, battle_enemies[current_battle]))
    end
  end,
  draw = function(self)
    cls()

    -- occasional lightning
    if self.t >= 200 and self.t <= 220 and self.t % 4 == 0 then
      rectfill(0, 0, 128, 88, 7)
    end

    self.t = (self.t + 1) % 300

    -- rain
    for i = 1, 50 do
      x = flr(rnd(128))
      y = flr(rnd(85)) + 0
      line(x, y, x - 3, y + 3)
    end

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
    self.start_pos = current_battle
    self.is_finished_walking = false
    self.character_x = self.starting_circle_x - 4 + (self.circle_increment * (self.start_pos - 1))
    self.next_circle_x = self.character_x + self.circle_increment
  end,
  update = function(self)
    self.animation_timer += 1
    -- delay when character is finished walking
    if (self.animation_timer < 30 and self.is_finished_walking) then
      return
    end

    -- delay at the beginning of the scene
    if (self.animation_timer < 15) then
      return
    end

    -- when finished walking and finished with delay, change scene
    if (self.is_finished_walking) then
      current_battle += 1
      change_scene(make_battle_scene(player_candy, battle_enemies[current_battle]))
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
      self.starting_circle_x + (self.circle_increment * (num_circles - 1)) + 2,
      circle_y + 1,
      3
    )

    -- draw character
    spr(
      self.char_sprites[self.current_sprite_index],
      self.character_x,
      circle_y - 15
    )

    -- draw circles
    for i = 0, num_circles do
      if (i == num_circles - 1) then
        -- draw a skull in the last slot
        spr(48, circle_x - 3, circle_y - 4)
      else
        circfill(circle_x, circle_y, 3, 7)
      end
      circle_x += circle_increment
    end

    -- get ready!
    if (self.is_finished_walking) then
      center_print('get ready!', 40, 7)
    end
  end
})

current_scene = title_screen
current_battle = 1
player_candy = nil
battle_enemies = {}

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
0000000000cccccccccccc00c60000000000006cc60000000000006ccccccccc00000000c600000000000000000006c0000000000006c6000006c60000000000
000000000c666666666666c0c60000000000006cc60000000000006c6666666600000000c600000000000000000006c0000000000006c6000006c60000000700
00700700c66000000000066cc60000000000006cc60000000000006c0000000000000000c600000000000000000006c0000000000006c6000006c60000000c70
00077000c60000000000006cc60000000000006cc60000000000006c0000000000000000c606666666666666666606c6666666660006c6000006c60000000cc7
00077000c60000000000006cc60000000000006cc60000000000006c0000000000000000c66ccccccccccccccccc66cccccccccc0006c6000006c60000000cc0
00700700c60000000000006cc66000000000066cc60000000000006c0000000000000000ccc66666666666666666ccc66666c6660006c6000006c60000000c00
00000000c60000000000006c0c666666666666c0c60000000000006c0000000066666666c660000000000000000066c00006c6000006c6006666c66600000000
00000000c60000000000006c00cccccccccccc00c60000000000006c00000000ccccccccc600000000000000000006c00006c6000006c600cccccccc00000000
00080000c6cccccccccccc6c00005000000000000000000bbb00000000000000000000000004444400000000044400000000000000000000a000000000000000
00888000cc666666666666cc0555755000000000000000bbb3b000000000000000004444444444640000000004440000000009000000000099a0000000000000
00888000c66000000000066c057777500000000000004b3333bb00000000000000046444464644444000000444640000000000aa9a00000089000000a0a00000
08888800c60000000000006c0576677500000000000040b3bbb00000000000000054444544444444446004445444500000000098a00000000aa000000999a000
88888880c60000000000006c57766750000000000000400bbb000000000000000554444555444644444444555444550000000a9a900000000000000009890000
88788880c60000000000006c057777500000000000004400000566676600000005555555755544455444555755555550000000000000000000000000a00a0000
08878800c60000000000006c05575550000000000888044088805777666000000555555577555545545555775555555000000000000000000000000000000000
00888000c60000000000006c0005000000008888888888488888567776660000055555577705555555555077755555500dddddddddddddddddddddddddddd000
7777700000888800008888000088880000888888888883438888856766060000055555557700755555570077555555000dedfdddddddddddddddddddddddd000
0777000008888880088888800888888000088888888883338888856666666000005555555555555555555555555550000ddfdddddddddddddddddefdddddd000
0070000070777707707777077077770700055688888888888888888886660600004644444444444444444444444400000ddfd6dddddddddddddddeedddddd000
0000000077077077770770777707707700005649a88d88888888888888666600004444446444644464444644446400000ddddd6ddddddddddddd6dddddddd000
0000000007744770077447700774477000000559a888f8888888888888866660004446444444444444644444644400000ddddd77ddddddddddd6ddddddddd000
000000000cccccc07cccccc00cccccc70000065548888f4488888888888666600044444444441c44444441c4444400000ddd77997ddddddddd6dddddddddd000
000000007cccccc70ccccc7007ccccc000000056a888844888888888888666600cc4641c44641c44644141cc44441c000dd799999d777d777dd7ddddddddd000
0000000001100110011000000000011000000056aa8888888d8888888886666001c4441cc4441cc4441c441cc461cc000dd799dd9799979997d9777dd77dd000
00777100000000000000000000000000000000569a888888f88888888856660001cc4441c4441ccc41c4441cc441cc000dd799d9997dd97dd97979977997dd00
07777710000000000000000000000000000000569a888884f48888888885660001ccc441c4441ccc41c44441c441c00000d799dd9997d997d9979d999d997d00
710710710000000000000000000000000000005494888884488888888885600001ccccccccccccccccccccccccccc00000dd799dd997d997d997dd99dd997d00
71071071000000000000000000000000000000569a888888888888888888500001ccccccccccccccccccccccccccc00000dd799dd997d997d997d997d997dd00
77777771000000000000000000000000000000559a888888888884488888000001cccccccccccccccccccc77ccccc00000dd79999997d997d997dd7dd997dd00
77707771000000000000000000000000000000569a888844888884f48888000001cccccc7cccccccccccc77cccccc00000dd799999799779977dddddd97ddd00
0777771000000000000000000000000000000066aa8884f4888888f88880000001ccccc77cccccccccccc7ccccccc00000ddd77777d77dd77dddddddd7dddd00
07070710000000000000000000000000000005569a8888f88848888d8880000001cccc77ccccccc7cccc7777ccccc00000dddddddddddddddddd6ddddddddd00
888888888808888888088880000000000000056494888f8884f488888880000001cccc777ccccc7ccccc7777cccc000000ddddddd6ddddddddddd6ddddddddd0
89999998980899899808998000000000000056698888d88888f888888880000001ccccc77cccc77ccccccc77cccc000000ddddddd6dddddddddddd6dddddddd0
89999998980899899808998000000000000055994888888888f888888800000001ccccc7ccccc777cccccc7ccccc0000000dddddd6ddddddddddddd6ddddddd0
899988889808998998089980000000000005588888888888888f88888800000001ccccc7ccccccc7ccccc77ccccc0000000ddddeddeddddddddddddddfddddd0
8999808998089989980899800000000000088888888888888888d8888000000001cccc77cccccc77ccccc7cccccc0000000dddddfeddddddddddddddfffdddd0
8999888898089989980899800000000000008888888888888888888800000000001cccccccccc77cccccc7cccccc0000000ddddfdedddddddddddddddeddddd0
8999999898089989980899800000000000000888888800008888888000000000001cccccccccc7cccccccccccccc0000000dddddddedddddddddddddddddddd0
899999989808998998089980000000000000008888800000088888000000000000001cccccccccccccccccccccc00000000dddddddddddddddddddddddddddd0
8999888898889989988889888880000000000000000000000000000000000000000000000000777777aa77700000000000000000000000000000000000000000
89998089999999899999899999800000000000000000000000000000000000000000000000777777777777777000000000000000000000000000000000000000
8999808999999989999989999980000000000000000000000000000000000000000000007777777cc77779977770000000000000000000000000000000000000
888880888888888888888888888000000000000000000000000000000000000000088888777aa77cc77779977777000000000000000005555555000000000000
880000000880888880088888088880088888000000000000000000000000000000888888877aa7777777777777aa700000000000005554454454555000000000
898000008988999998099999889998089998000000000000000000000000000008888888887777777788888777aa770000000800055454444444545500000000
89980008998999999989999998999988999800000000000000000000000000000888888888777997788888887777770000008600544444444444444450000000
89998089998999999998999999899998999800000000000000000000000000000888888888077997888888888777777000008605544444444444444455000000
899998999989988899988889998999999998000000000000000000000000000008888888880077778888888887cc777000086654444444444444444444500000
899999999989980899988089998999999998000000000000000000000000000008888888887007778888888887cc799700086644444444444444444444550000
89989998998998089998808999899999999800000000000000000000000000000088888887700077888888888777799700866644444444444444444444445000
899889889989988899988889998999999998000000000000000000000000000000e8888877700777888888888777777708868644444444444444444444455000
899808089989999999989999998998999998000000000000000000000000000000ee777777700777788888887777777708668644444466444446644444445000
899800089989999999899999989998899998000000000000000000000000000000ee77777777777777888887777ee77708668644444436444443644444444500
899800089988999998099999889998089998000000000000000000000000000000ee7777777777777777ee77777ee77708866644444444444444444444444500
88880008888088888008888808888800888800000000000000000000000000000eee7777077777777777eee7707ee77708668644444444444444444444445500
00888880888000008888888888888888888888880000000000000000000000000ee777770000777777777eee00eee7aa08666644444444444444444444444500
08999998998000008998999998999998999999980000000000000000000000000ee7ee7770000777777700ee07ee77aa08077744444444444444444444444500
89999998998000008998999998999998999999980000000000000000000000000eeeee7777700007770000eee7ee777708070044444444444444444444445500
89999988998008008998998888998888999999980000000000000000000000000eeee777777777777777777ee7ee7777000777c4444444444444444444444500
89988808998089808998998089998008889998880000000000000000000000000eee7777777777777777777eeeee77700000ddcc444444447444444444445000
89999988998899988998998888998888089998000000000000000000000000000ee077777777777799777777eee777700800544cc44440007000444444455000
0899999899999999999899999899999808999800000000000000000000000000000007777aa77777997777777ee7770008005544cc4444477444444444445000
008889989999999999989988889988880899980000000000000000000000000000000c777aa77777777777aa77777700080005444c4444747744444444550000
0899999899999999999899808999800008999800000000000000000000000000000000c777777777777777aa777770000800005544444447774444c444500000
899999988999989999899988889988880899980000000000000000000000000000000007777777cc77777777777700000000000544444444c4444cc455000000
899999800899808998899999989999980899980000000000000000000000000000000000777777cc77777777777000000000000055444444cccccc4450000000
08888800008800088088888888888888088888000000000000000000000000000000000000777777777777777000000008000000054544444cccc45500000000
00000000000000000000000000000000000000000000000000000000000000000000000000007777777799700000000000000000005555454454555000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000008000000000cc5555555cc0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000000cc0000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000cc0000000cc0000000000
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
011000200c0730a700127000f700246230d7000d7000d7000c0730f700177002b700246230070000700007000c073007000070000700246230070000700007000c07300700007000070024623007000070000700
011000200e2250e3100e4100e2250e3100e4100e2200e3100e4100e2200e3150e4100e2200e3100e4200e2150e3200e4100e2150e3200e4100e2100e3250e4100e2100e3250e4100e2100e3200e4150e2200e310
011000200f075160730f0750c0730a0750a0730c0730f07511073130730f0750c0730507505073070750a0730c07511073110750f0730c07507073050730a0750f07313075160730f07305075030730a0750f073
0110002027204272032420424203242042220322204222031154213542155421154213542155422650024500245002650028500295002b5002d50013203245002d50024500155551355511555105550e5550c555
01100008250552201519055160151f0551c0152605523015250000000019000000001f00029000260000000500005000050000500005000050000500005000050000500005000050000500005000050000500005
01100008220550000516055000051c055290052305500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000200c5520c5520c5520c5520c5521055213552185521c5521c55218552185521355213552165521655211552115521154211532115221151211502125001e5001850013500135000e5000e5000650006500
01100008230552001518055150151d0551a0152405521015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
01100008200550000515055000051a055290052105500005000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
012000200c5520c5520c5520c5520c5521055213552185521d5521d5521855218552135521355218552185521e5521e5521e5421e5321e5221e51211502125001e5001850013500135000e5000e5000650006500
011000002a2042a20327204272032720425203252042520320522225022452220502225222452129500275002450024500245002250022500205002050027500305002750018555165551455513555115550f555
0120002007552075520755207552075520b5520e55213552175521755213552135520e5520e55211552115520c5520c5520c5420c5320c5220c5120c5020d5001e5001850013500135000e5000e5000650006500
0120002007552075520755207552075520b5520e55213552185521855213552135520e5520e55213552135521955219552195421953219522195120c5020d5001e5001850013500135000e5000e5000650006500
011000200c073160730f0750c073246230a0730c0730f0750c073130730f0750c0732462305073070750a0730c07311073110750f0732462307073050730a0750c07313075160730f07324623030730a0750f073
010400201305013050130501305015050150501505015050170501705017050170501a0501a0501a0501a0501c0501c0501c0501c0501f0501f0501f0501f0502105021050210502105023050230502305023050
01040020180501805018050180501a0501a0501a0501a0501c0501c0501c0501c0501f0501f0501f0501f05021050210502105021050240502405024050240502605026050260502605028050280502805028050
011000201d0501d0501d0501d0501d0501d0501d0501d0501b0501b0501b0501b0501b0501b0501b0501b0501d0501d0501d0501d0501d0501d0501d0501d0500000000000000000000000000000000000000000
011000202405024050240502405024050240502405024050220502205022050220502205022050220502205024050240502405024050240502405024050240500000000000000000000000000000000000000000
011000202d0502d0502d0502d0502d0502d0502d0502d0502b0502b0502b0502b0502b0502b0502b0502b0502d0502d0502d0502d0502d0502d0502d0502d0500000000000000000000000000000000000000000
010400201405014050140501405016050160501605016050180501805018050180501b0501b0501b0501b0501d0501d0501d0501d050200502005020050200502205022050220502205024050240502405024050
010400201b0501b0501b0501b0501d0501d0501d0501d0501f0501f0501f0501f050220502205022050220502405024050240502405027050270502705027050290502905029050290502b0502b0502b0502b050
001000002b152241521d1521b152221521d15216152131521815214152101520c152001520015200152001520b1020a1020010200102001020010200102001020010200102001020010200102001020010200102
011000001715114151111510f1510d1510b1510915107151061510415102153011530015300140001300012000000000010000100001000010000100001000010000100001000010000100001000010000100001
011000082b055280151f0551c01525055220152c05529015250000000019000000001f00029000260000000500005000050000500005000050000500005000050000500005000050000500005000050000500005
0110000829055260151e0551b01523055200152a05527015000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011000201005310050100501005310050100501005010050100501005010050100501005010050100501105111050110501105011050110501305112050120501205012050120501405113052130521305210000
011000200e0530e0500e0500e0530e0500e0500e0500e0500e0500e0500e0500e0500e0500e0500e0500f0510f0500f0500f0500f0500f050110511005010050100501005010050120511105211052110520e000
011000000010428154001040010400104001041515400104001040010400104001042e1542b104001040010400104001042415400104001040010400104001042b1542b104001040010418154181000010400104
011000000010424100241542410000104001041110011154001042a1542a100001002a1542a100001040010400104001042015400104001042015400104001042715427104001040010414154141001415414100
__music__
01 0406074e
02 4411070e
01 08490a0f
02 0b4c0d10
01 12134344
00 17184344
04 14151644
04 191a4344
01 081b1d1f
02 0b1c1e20

