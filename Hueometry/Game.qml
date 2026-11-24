import QtQuick
import "js/session.mjs" as S
import "js/store.mjs" as Store

// The whole game, for either host. `host` provides storage and window
// control (see ARCHITECTURE.md): readText(name), writeText(name, text),
// quit(), kind ("app" or "plugin"), canFullscreen, toggleFullscreen(), and
// version (shown on the menu).
Item {
  id: root
  property var host: null

  // defaults until the host is set: a host's binding can arrive after these
  // properties are first evaluated (it does under the Omarchy shell)
  property var settings: Store.settings("")
  property var progress: Store.progress("")
  property string screen: "menu"
  property int lastArea: 1
  property bool helpShown: false
  property bool confirmQuit: false
  property alias sound: sound
  // the screen showing now, for tests and previews
  readonly property var current: screens.item

  readonly property var areas: [
    { id: "tutorial", name: qsTr("First Steps") },
    { id: "clearing", name: qsTr("Jungle Clearing") },
    { id: "river", name: qsTr("The River Crossing") },
    { id: "ruins", name: qsTr("The Ancient Ruins") },
    { id: "waterfall", name: qsTr("The Waterfall Sanctuary") },
    { id: "temple", name: qsTr("The Hidden Temple") },
    { id: "heart", name: qsTr("The Heart of the Rainforest") },
  ]
  readonly property var freeNames: ({ beginner: qsTr("Sprout"), easy: qsTr("Explorer"), medium: qsTr("Adventurer"), hard: qsTr("Temple Keeper"), expert: qsTr("Legend") })

  focus: true

  Binding { target: Theme; property: "reducedMotion"; value: root.settings.reducedMotion }
  Binding { target: Theme; property: "symbols"; value: root.settings.symbols }
  Binding { target: Theme; property: "em"; value: Math.max(11, Math.min(root.width / 52, root.height / 34)) * root.settings.scale }

  // Saving
  // ------

  // Each host writes only its own progress file and reads all of them, so
  // the app and the plugin can never overwrite each other's progress.
  readonly property var progressFiles: ["progress-app.json", "progress-plugin.json", "progress.json"]
  function ownProgressFile() { return host && host.kind === "plugin" ? "progress-plugin.json" : "progress-app.json" }

  function readProgress() {
    // merge keeps every record and the most recently changed unfinished
    // puzzle; files that do not exist take no part
    return progressFiles.map(name => host.readText(name)).filter(text => text !== "")
      .map(text => Store.progress(text))
      .reduce((acc, p) => Store.merge(acc, p), Store.progress(""))
  }

  function load() {
    if (!host) return
    settings = Store.settings(host.readText("settings.json"))
    progress = readProgress()
  }
  onHostChanged: load()
  Component.onCompleted: load()

  // a save that could not be written (shown on screen until one works)
  property bool progressUnsaved: false
  // settings changed here but not yet written, by key: kept over rereads
  property var unsavedSettings: ({})
  // the saves were written by a newer Hueometry, so this one leaves them be
  property bool newerSaves: false
  readonly property bool saveFailed: progressUnsaved || Object.keys(unsavedSettings).length > 0

  function saveProgress() {
    if (!host) return
    // merge keeps this copy's unfinished puzzle (the newest)
    progress = Store.merge(readProgress(), progress)
    const own = host.readText(ownProgressFile())
    if (Store.newer(own)) { newerSaves = true; progressUnsaved = true; return }
    progressUnsaved = !host.writeText(ownProgressFile(), Store.progressText(own, progress))
  }

  // what is on disk, merged with this copy: an unsaved change here (a failed
  // write) is newer, so it survives
  function refreshProgress() {
    if (host) progress = Store.merge(readProgress(), progress)
  }

  // what is on disk with this copy's unsaved changes on top: the other host
  // may have changed something else
  function settingsWith(pending, disk) {
    let next = disk
    for (const k of Object.keys(pending)) next = JSON.stringify(Store.withSetting(next, k, pending[k]))
    return Store.settings(next)
  }

  function refreshSettings() {
    if (host) settings = settingsWith(unsavedSettings, host.readText("settings.json"))
  }

  function setSetting(key, value) {
    const pending = Object.assign({}, unsavedSettings)
    pending[key] = value
    // one read of the disk for the merge, the version check and the write
    const disk = host ? host.readText("settings.json") : JSON.stringify(settings)
    settings = settingsWith(pending, disk)
    if (!host) return
    if (Store.newer(disk)) { newerSaves = true; unsavedSettings = pending; return }
    unsavedSettings = host.writeText("settings.json", Store.settingsText(disk, settings)) ? ({}) : pending
  }

  function saveCurrent(ref, moves, assisted) {
    // stamp the change later than anything either host has saved
    refreshProgress()
    progress = Store.setCurrent(progress, { ref, moves: moves.map(m => [m.from, m.to]), assisted: assisted === true }, Store.nextAt(progress, Date.now()))
    saveProgress()
  }

  function recordSolved(ref, moves, assisted) {
    // compare against every host's records, not this copy's
    refreshProgress()
    const out = Store.solved(progress, ref, moves, assisted, Store.nextAt(progress, Date.now()))
    progress = out.progress
    saveProgress()
    return out
  }

  // Places
  // ------

  function areaIndex(ref) {
    if (!ref) return lastArea
    if (ref.kind === "tutorial") return 0
    if (ref.kind === "level") return Math.max(0, S.AREAS.indexOf(ref.area) + 1)
    return { beginner: 1, easy: 2, medium: 3, hard: 4, expert: 6 }[ref.difficulty] || 1
  }

  // the play screen's title, in two parts, so a long name can shorten
  // without losing its place
  function nameOf(ref) {
    if (ref.kind === "free") return qsTr("Free play")
    return areas[areaIndex(ref)].name
  }
  function placeOf(ref) {
    if (ref.kind === "tutorial") return qsTr("%1 of 3").arg(ref.index + 1)
    if (ref.kind === "level") return qsTr("%1 of 8").arg(ref.index + 1)
    return freeNames[ref.difficulty] || ""
  }


  function nextRef(ref) {
    if (!ref) return null
    if (ref.kind === "tutorial") return ref.index < 2 ? { kind: "tutorial", index: ref.index + 1 } : { kind: "level", area: S.AREAS[0], index: 0 }
    if (ref.kind === "level") {
      if (ref.index < 7) return { kind: "level", area: ref.area, index: ref.index + 1 }
      const a = S.AREAS.indexOf(ref.area)
      return a + 1 < S.AREAS.length && Store.areaOpen(progress, S.AREAS, a + 1, 8) ? { kind: "level", area: S.AREAS[a + 1], index: 0 } : null
    }
    return { kind: "free", difficulty: ref.difficulty, index: -1 }
  }

  function show(name) {
    helpShown = false
    // the other host may have solved, opened or changed something since
    refreshProgress()
    refreshSettings()
    screen = name
    sound.cue("select")
  }

  function start(ref) {
    // the other host may have changed the layout or motion since
    refreshSettings()
    lastArea = areaIndex(ref)
    screen = "play"
    screens.item.open(ref, null)
  }

  // a random board of this size, never the one just played (`avoid`)
  function startFree(difficulty, avoid) {
    const count = S.puzzleCount(difficulty)
    let index = Math.floor(Math.random() * (avoid >= 0 && count > 1 ? count - 1 : count))
    if (avoid >= 0 && count > 1 && index >= avoid) index++
    start({ kind: "free", difficulty, index })
  }

  function playNext(ref) {
    const n = nextRef(ref)
    if (!n) { goBack(); return }
    if (n.kind === "free") startFree(n.difficulty, ref.index)
    else start(n)
  }

  function continueOrMap() {
    // the other host may have finished or changed the puzzle, or changed a
    // setting, since
    refreshProgress()
    refreshSettings()
    const c = progress.current
    if (c && S.known(c.ref)) {
      lastArea = areaIndex(c.ref)
      screen = "play"
      // the adapter reads [from, to] pairs and drops anything malformed
      screens.item.open(c.ref, { moves: Array.isArray(c.moves) ? c.moves : [], assisted: c.assisted === true })
    } else if (!progress.tutorial && !progress.done[Store.key({ kind: "tutorial", index: 0 })]) {
      // a first visit starts with the first steps
      start({ kind: "tutorial", index: 0 })
    } else {
      show("map")
    }
  }

  function goBack() {
    if (helpShown) { helpShown = false; return }
    if (screen === "play") {
      const ref = screens.item.ref
      show(ref && ref.kind === "free" ? "free" : "map")
    } else if (screen === "menu") {
      quit()
    } else {
      show("menu")
    }
  }

  function showHelp() { helpShown = true }

  function quit() {
    if (!host) return
    if (host.kind === "plugin") { host.quit(); return }
    if (confirmQuit) host.quit()
    else { confirmQuit = true; quitTimer.restart() }
  }

  Timer { id: quitTimer; interval: 3000; onTriggered: root.confirmQuit = false }

  Keys.onPressed: function(event) {
    // a held key repeats: let only arrows and Tab repeat, so no held key can
    // confirm quitting, restarting, lifting or choosing
    const moving = [Qt.Key_Left, Qt.Key_Right, Qt.Key_Up, Qt.Key_Down, Qt.Key_Tab].indexOf(event.key) >= 0
    if (event.isAutoRepeat && !moving) { event.accepted = true; return }
    // a modifier alone (Shift for ?) neither closes nor opens anything
    if ([Qt.Key_Shift, Qt.Key_Control, Qt.Key_Alt, Qt.Key_Meta, Qt.Key_Super_L, Qt.Key_Super_R, Qt.Key_AltGr].indexOf(event.key) >= 0) return
    if (helpShown) { helpShown = false; event.accepted = true; return }
    if (event.key === Qt.Key_Question || (event.key === Qt.Key_Slash && (event.modifiers & Qt.ShiftModifier))) { helpShown = true; event.accepted = true; return }
    if (event.key === Qt.Key_F11 && host && host.canFullscreen) { host.toggleFullscreen(); event.accepted = true; return }
    if (event.key === Qt.Key_Q && !(event.modifiers & Qt.ControlModifier)) {
      // a held key repeats; only a second press confirms
      if (!event.isAutoRepeat) quit()
      event.accepted = true
      return
    }
    if (screens.item && screens.item.handleKey(event)) event.accepted = true
  }

  // Scene
  // -----

  Jungle {
    anchors.fill: parent
    area: root.screen === "play" ? root.areaIndex(screens.item ? screens.item.ref : null) : root.lastArea
    restored: root.screen === "play" && !!screens.item && !!screens.item.result
  }

  Loader {
    id: screens
    anchors.fill: parent
    sourceComponent: ({ menu: menuScreen, map: mapScreen, free: freeScreen, settings: settingsScreen, play: playScreen })[root.screen]
  }

  Component { id: menuScreen; Menu { game: root } }
  Component { id: mapScreen; Map { game: root } }
  Component { id: freeScreen; FreePlay { game: root } }
  Component { id: settingsScreen; Settings { game: root } }
  Component { id: playScreen; Play { game: root } }

  Help {
    anchors.fill: parent
    quitsAtOnce: !!root.host && root.host.kind === "plugin"
    visible: root.helpShown
    onClosed: root.helpShown = false
  }

  // a save that could not be written, said plainly
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Theme.em * 0.6
    visible: root.saveFailed
    z: 20
    width: saveText.implicitWidth + Theme.em * 2
    height: Theme.em * 2.4
    radius: height / 2
    color: "#E0402018"
    border.color: Theme.gold
    Text {
      id: saveText
      anchors.centerIn: parent
      text: root.newerSaves ? qsTr("These saves are from a newer Hueometry. Update it to keep saving.")
                            : qsTr("Progress could not be saved. Check the disk has room.")
      color: Theme.ink
      font.family: Theme.font
      font.pixelSize: Theme.em
    }
  }

  // "press Q again" when quitting the app
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.em * 5
    visible: root.confirmQuit
    width: quitText.implicitWidth + Theme.em * 2
    height: Theme.em * 2.6
    radius: height / 2
    color: Theme.card
    border.color: Theme.glow
    Text {
      id: quitText
      anchors.centerIn: parent
      text: qsTr("Press Q again to quit")
      color: Theme.ink
      font.family: Theme.font
      font.pixelSize: Theme.em * 1.1
    }
  }

  Sound {
    id: sound
    music: root.settings.music
    effects: root.settings.effects
    muted: root.settings.muted
    area: root.screen === "play" ? root.areaIndex(screens.item ? screens.item.ref : null) : 0
    inPlay: root.screen === "play"
    playing: true
  }
}
