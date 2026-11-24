import QtQuick
import QtMultimedia

// The sounds themselves (made by tools/audio/synth.py). Loaded by Sound.qml
// only where Qt Multimedia is installed. Effects follow the sounds slider;
// music, the area's ambience and its critters follow the music slider.
Item {
  id: bank
  // silent until Sound.qml passes on the game's settings, in whatever order
  // its bindings arrive, so a muted game never starts its music on load
  property real music: 0
  property real effects: 0
  property int area: 0
  property bool playing: false
  property bool inPlay: false
  property real duck: 1.0

  readonly property var ambienceFor: ["forest", "forest", "river", "temple", "river", "temple", "forest"]
  // the area's family: its ambience, its play theme and its critters
  readonly property string family: ambienceFor[area] ?? "forest"
  readonly property url themeSource: inPlay ? "sounds/music-" + family + ".ogg" : "sounds/music-menu.ogg"

  // a few players per sound, so quick moves do not cut each other off
  component Pool: Item {
    id: pool
    property url source
    property int next: 0
    function play(volume) {
      // silenced: start nothing at all, rather than a sound at no volume
      if (bank.effects <= 0) return
      const v = [a, b, c][next]
      next = (next + 1) % 3
      v.level = volume
      v.play()
    }
    // the volume follows the slider (and silence) while a sound plays
    SoundEffect { id: a; property real level: 1; source: pool.source; volume: bank.effects * level }
    SoundEffect { id: b; property real level: 1; source: pool.source; volume: bank.effects * level }
    SoundEffect { id: c; property real level: 1; source: pool.source; volume: bank.effects * level }
  }

  Pool { id: lift1; source: "sounds/lift-1.wav" }
  Pool { id: lift2; source: "sounds/lift-2.wav" }
  Pool { id: lift3; source: "sounds/lift-3.wav" }
  Repeater { id: places; model: 6; Pool { required property int index; source: "sounds/place-" + index + ".wav" } }
  Repeater { id: completes; model: 6; Pool { required property int index; source: "sounds/complete-" + index + ".wav" } }
  Pool { id: drop; source: "sounds/drop.wav" }
  Pool { id: refuse; source: "sounds/refuse.wav" }
  Pool { id: undo; source: "sounds/undo.wav" }
  Pool { id: restart; source: "sounds/restart.wav" }
  Pool { id: hint; source: "sounds/hint.wav" }
  Pool { id: select; source: "sounds/select.wav" }
  Pool { id: solved; source: "sounds/solved.wav" }

  property int liftTurn: 0

  // every effect plays at full level: the mix is set in the files
  // (EFFECT_LUFS in tools/audio/synth.py, checked by tools/check/audio.py)
  function cue(name, arg) {
    switch (name) {
    case "lift": [lift1, lift2, lift3][liftTurn++ % 3].play(1.0); break
    case "place": places.itemAt(Math.max(0, Math.min(5, arg % 6)))?.play(1.0); break
    case "complete": completes.itemAt(Math.max(0, Math.min(5, arg % 6)))?.play(1.0); break
    case "drop": drop.play(1.0); break
    case "refuse": refuse.play(1.0); break
    case "undo": undo.play(1.0); break
    case "restart": restart.play(1.0); break
    case "hint": hint.play(1.0); break
    case "select": select.play(1.0); break
    // the music steps back only for a fanfare that can be heard
    case "solved": solved.play(1.0); if (effects > 0) duckAnim.restart(); break
    }
  }

  // the music steps back while the fanfare plays
  SequentialAnimation {
    id: duckAnim
    NumberAnimation { target: bank; property: "duck"; to: 0.25; duration: 250 }
    PauseAnimation { duration: 2600 }
    NumberAnimation { target: bank; property: "duck"; to: 1.0; duration: 1500 }
  }

  MediaPlayer {
    id: tune
    source: bank.themeSource
    loops: MediaPlayer.Infinite
    audioOutput: AudioOutput { volume: bank.music * bank.duck * 0.7 }
    onSourceChanged: if (bank.musicOn) play()
  }

  MediaPlayer {
    id: air
    source: bank.inPlay ? "sounds/ambience-" + bank.family + ".ogg" : ""
    loops: MediaPlayer.Infinite
    audioOutput: AudioOutput { volume: bank.music * 0.9 }
    onSourceChanged: if (bank.musicOn && source != "") play()
  }

  // music and ambience pause while silenced or turned to nothing, and pick
  // up where they were when turned back up
  readonly property bool musicOn: playing && music > 0
  onMusicOnChanged: {
    if (musicOn) { tune.play(); if (air.source != "") air.play() }
    else { tune.pause(); air.pause() }
  }

  // critters: a bird, a frog, a drip now and then, at random, so the
  // ambience never sounds like a loop. Only while a puzzle is open and the
  // music is on.
  readonly property var crittersFor: ({
    forest: ["bird-1", "bird-2", "bird-3", "bird-1"],
    river: ["bird-2", "frog", "plop", "plop"],
    temple: ["drip-1", "drip-2", "drip-1"],
  })
  readonly property bool crittersOn: critterClock.running
  Timer {
    id: critterClock
    running: bank.musicOn && bank.inPlay
    repeat: true
    interval: 6000
    // leaving the puzzle or turning the music off silences a critter at once
    onRunningChanged: if (!running) { for (const v of bank.critterVoices) v.stop(); interval = 6000 }
    onTriggered: {
      const names = bank.crittersFor[bank.family] ?? []
      const name = names[Math.floor(Math.random() * names.length)]
      const voice = critterVoices.find(v => v.name === name)
      if (voice) {
        // near or far
        voice.level = 0.45 + Math.random() * 0.55
        voice.play()
      }
      interval = 4000 + Math.random() * 9000
    }
  }
  readonly property var critterVoices: [bird1, bird2, bird3, frog, plop, drip1, drip2]
  component Critter: SoundEffect {
    property string name
    property real level: 1
    source: "sounds/critter-" + name + ".wav"
    volume: bank.music * 0.9 * level
  }
  Critter { id: bird1; name: "bird-1" }
  Critter { id: bird2; name: "bird-2" }
  Critter { id: bird3; name: "bird-3" }
  Critter { id: frog; name: "frog" }
  Critter { id: plop; name: "plop" }
  Critter { id: drip1; name: "drip-1" }
  Critter { id: drip2; name: "drip-2" }
}
