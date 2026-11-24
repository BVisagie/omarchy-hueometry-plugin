# Assets

Every asset in Hueometry is this project's own work, licensed CC BY-SA 4.0
(see LICENSE-ASSETS), © 2026 Bernard Visagie and the Hueometry contributors.
There are no third-party images, sounds or fonts.

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
| `qml/Hueometry/sounds/drop.wav` | effect |
| `qml/Hueometry/sounds/hint.wav` | effect |
| `qml/Hueometry/sounds/lift-1.wav` | effect |
| `qml/Hueometry/sounds/lift-2.wav` | effect |
| `qml/Hueometry/sounds/lift-3.wav` | effect |
| `qml/Hueometry/sounds/music-menu.ogg` | music loop |
| `qml/Hueometry/sounds/music-play.ogg` | music loop |
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

The game uses the system's sans-serif font; it ships none.
