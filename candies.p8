-- unique candies
razor_apple = {
  name = "razor apple",
  sprite = nil,
  hp = 100,
  attack = 100,
  defense = 100,
  element = elements.grass,
  attacks = {
    make_attack(punch),
    make_attack(kick),
    make_attack(rot_teeth),
    make_attack(caramelize)
  }
}