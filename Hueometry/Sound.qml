import QtQuick

// Sound for the whole game, behind one small interface. The real player
// (SoundBank.qml) needs Qt Multimedia, which not every Omarchy install has,
// so it is loaded at run time: without it, the game is simply silent.
Item {
  id: root
  property real music: 0.6
  property real effects: 0.8
  property bool muted: false
  property int area: 0
  property bool inPlay: false
  property bool playing: false
  readonly property bool available: bank.status === Loader.Ready

  Loader {
    id: bank
    source: "SoundBank.qml"
    asynchronous: true
  }

  Binding { target: bank.item; property: "music"; value: root.muted ? 0 : root.music; when: root.available }
  Binding { target: bank.item; property: "effects"; value: root.muted ? 0 : root.effects; when: root.available }
  Binding { target: bank.item; property: "area"; value: root.area; when: root.available }
  Binding { target: bank.item; property: "inPlay"; value: root.inPlay; when: root.available }
  Binding { target: bank.item; property: "playing"; value: root.playing; when: root.available }

  // what session.touch answered: lift, drop, move, refuse, empty
  function effect(e) {
    if (!available) return
    if (e.kind === "move") bank.item.cue("place", e.bead)
    else if (e.kind === "lift") bank.item.cue("lift", 0)
    else if (e.kind === "drop") bank.item.cue("drop", 0)
    else if (e.kind === "refuse" || e.kind === "empty") bank.item.cue("refuse", 0)
  }

  // undo, restart, hint, solved, select, open
  function cue(name) {
    if (available) bank.item.cue(name, 0)
  }
}
