-- unique candies
candies = {
  razor_apple = {
    name = "razor apple",
    sprite = 20,
    hp = 100,
    max_hp = 100,
    attack_power = 100,
    defense_rating = 150,
    abilities = {
      abilities.throw_razor,
      abilities.bash,
      abilities.rot_teeth,
      abilities.caramelize
    }
  },
  boom_pops = {
    name = "boom pops",
    sprite = 28,
    hp = 100,
    max_hp = 100,
    attack_power = 100,
    defense_rating = 100,
    abilities = {
      abilities.pop,
      abilities.acid_spit,
      abilities.boom,
      abilities.settle_down
    }
  }
}