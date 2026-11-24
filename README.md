# Hueometry (Omarchy shell plugin)

A colour-sorting puzzle for children and families: sort the glowing jungle
orbs so every pillar holds one colour, using the empty pillar as space, in as
few moves as you can. Its rules engine is written in Bend 2 and its gameplay
laws are machine-checked proofs.

This repository is generated from
https://github.com/BVisagie/omarchy-hueometry by its release workflow, at each
release. Report problems and find the source there.

## Install

```sh
omarchy plugin add https://github.com/BVisagie/omarchy-hueometry-plugin --enable
```

Then click the orb (◉) in the bar, or bind a key to:

```sh
omarchy-shell shell summon io.github.bvisagie.hueometry '{}'
```

For example, in `~/.config/hypr/bindings.lua`:

```lua
o.bind("SUPER + SHIFT + H", "Hueometry", "omarchy-shell shell summon io.github.bvisagie.hueometry '{}'")
```

## Sound

Sound needs Qt Multimedia, which not every Omarchy install includes. Without
it the game plays silently. To add it:

```sh
omarchy-pkg-add qt6-multimedia
```

## Remove

```sh
omarchy plugin remove io.github.bvisagie.hueometry
```

Your progress stays in `~/.local/share/hueometry` and settings in
`~/.config/hueometry`. Delete those folders to remove them too.

## Licences

Code: MIT (LICENSE). Art and audio: CC BY-SA 4.0 (LICENSE-ASSETS, ASSETS.md).
The Nunito typeface: SIL Open Font License 1.1 (LICENSE-OFL).
