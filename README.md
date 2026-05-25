# Sonic Battle 2

A fan-made sequel to **Sonic Battle** (GBA, 2003): an isometric arena fighter.

> **The pitch:** *Sonic Battle where the fight is one big stylish juggle, and you build your fighter's combo kit out of swappable moves.*

## Status

[x] - character movement (run, jump, fall, land)
[x] - state machine
[x] - attacks (jab combo, heavy, upper)
[x] - two players on screen, separate controls
[x] - hitting each other (damage, knockback, juggles)
[x] - specials (guard, heal, ground shot, air shot)
[ ] - health, lives, KO, win condition                       <-- WE ARE HERE
[ ] - presentation (real sprites, dressed stage, combat UI)
[ ] - menus (title → character select → match → results)

the vision beyond demo v0.1 is more characters, the move mixing/kit building system, maybe online play in the future

## Tech

- **Engine:** Godot 4.x, GDScript.

## Running it

1. Install [Godot 4.x](https://godotengine.org/download).
2. Clone this repo.
3. Open `project.godot` in Godot and press **Play**.

Player 1 uses **WASD**; player 2 uses the **arrow keys**. Both share the same moveset (jab/heavy/upper, jump, guard, heal, ground/air shot).

## Contributing

Contributions are welcome. Fork the repo, make your change on a branch, and open a pull request against `main`. The code is meant to be readable, so if something is unclear, that's a bug worth raising.

## License

Original source code is released under the [MIT License](LICENSE).

**This is a non-commercial fan project.** Sonic the Hedgehog and all related characters, names, and assets are the property of **SEGA**. No SEGA intellectual property is owned by or granted through this repository. The MIT license covers the original code only.
