# Assets

Every image and sound in Hueometry is this project's own work, licensed
CC BY-SA 4.0 (see LICENSE-ASSETS), © 2026 Bernard Visagie and the Hueometry
contributors. The one third-party asset is the typeface (below).

## Pictures

The game itself has no image files: the jungle, the pillars, the orbs, the
symbols, the animal friends and the icons are drawn by the QML in
`qml/Hueometry/` and are covered by the code's MIT licence as well. Two image
files exist outside the game:

| File | What |
|---|---|
| `pkgbuild/hueometry.svg` | the app icon, drawn by hand in SVG |
| `plugin/preview.png` | the plugin's marketplace preview, a screenshot of the game made with `tools/shot` |

## Sounds

Made by `tools/audio/synth.py` (run `bin/audio`) from sine waves and noise
with fixed random seeds: no samples or recordings.

| File | Kind |
|---|---|
| `qml/Hueometry/sounds/ambience-forest.ogg` | ambience loop |
| `qml/Hueometry/sounds/ambience-river.ogg` | ambience loop |
| `qml/Hueometry/sounds/ambience-temple.ogg` | ambience loop |
| `qml/Hueometry/sounds/complete-0.wav` | effect |
| `qml/Hueometry/sounds/complete-1.wav` | effect |
| `qml/Hueometry/sounds/complete-2.wav` | effect |
| `qml/Hueometry/sounds/complete-3.wav` | effect |
| `qml/Hueometry/sounds/complete-4.wav` | effect |
| `qml/Hueometry/sounds/complete-5.wav` | effect |
| `qml/Hueometry/sounds/critter-bird-1.wav` | critter |
| `qml/Hueometry/sounds/critter-bird-2.wav` | critter |
| `qml/Hueometry/sounds/critter-bird-3.wav` | critter |
| `qml/Hueometry/sounds/critter-drip-1.wav` | critter |
| `qml/Hueometry/sounds/critter-drip-2.wav` | critter |
| `qml/Hueometry/sounds/critter-frog.wav` | critter |
| `qml/Hueometry/sounds/critter-plop.wav` | critter |
| `qml/Hueometry/sounds/drop.wav` | effect |
| `qml/Hueometry/sounds/hint.wav` | effect |
| `qml/Hueometry/sounds/lift-1.wav` | effect |
| `qml/Hueometry/sounds/lift-2.wav` | effect |
| `qml/Hueometry/sounds/lift-3.wav` | effect |
| `qml/Hueometry/sounds/music-menu.ogg` | music loop |
| `qml/Hueometry/sounds/music-forest.ogg` | music loop |
| `qml/Hueometry/sounds/music-river.ogg` | music loop |
| `qml/Hueometry/sounds/music-temple.ogg` | music loop |
| `qml/Hueometry/sounds/place-0.wav` | effect |
| `qml/Hueometry/sounds/place-1.wav` | effect |
| `qml/Hueometry/sounds/place-2.wav` | effect |
| `qml/Hueometry/sounds/place-3.wav` | effect |
| `qml/Hueometry/sounds/place-4.wav` | effect |
| `qml/Hueometry/sounds/place-5.wav` | effect |
| `qml/Hueometry/sounds/refuse.wav` | effect |
| `qml/Hueometry/sounds/restart.wav` | effect |
| `qml/Hueometry/sounds/select.wav` | effect |
| `qml/Hueometry/sounds/solved.wav` | effect |
| `qml/Hueometry/sounds/undo.wav` | effect |

## Typeface

| File | Source | Licence |
|---|---|---|
| `qml/Hueometry/fonts/Nunito-Regular.ttf` | Nunito, © 2014 The Nunito Project Authors (https://github.com/googlefonts/nunito) | SIL Open Font License 1.1 (LICENSE-OFL) |
| `qml/Hueometry/fonts/Nunito-Bold.ttf` | as above | as above |
| `qml/Hueometry/fonts/Nunito-Italic.ttf` | as above | as above |

The three files are static instances (weights 400, 700 and italic 400) of
the variable `Nunito[wght].ttf` and `Nunito-Italic[wght].ttf`, made with
fontTools' `varLib.instancer` and subset with `pyftsubset` to Latin and the
punctuation the game shows. Characters Nunito lacks (the arrows) fall back
to the system font.
