import QtQuick
import "js/session.mjs" as S
import "js/layout.mjs" as Layout

// Playing one puzzle: the board, the move count, undo, restart and hint, and
// the results when it is solved. All rule changes go through session.mjs.
Item {
  id: play
  required property var game

  property var session: null
  // a narrow window: smaller round buttons without labels, so the title
  // keeps room (the Keys card still names every action)
  readonly property bool compact: width < Theme.em * 46
  readonly property real toolSize: compact ? Theme.em * 2.7 : Theme.em * 3.2
  property var ref: null
  property bool assisted: false
  property var hint: null
  property string message: ""
  property int focusColumn: 0
  property bool confirmRestart: false
  // set when the winning move is accepted; shown once the orb has landed
  property var won: null
  property var result: null
  property bool loading: false
  property int token: 0
  property var pending: null

  readonly property var view: session ? S.view(session) : null
  readonly property bool showPar: !!session && !!ref && ref.kind !== "tutorial"
    && !(ref.kind === "level" && (ref.area === "clearing" || ref.area === "river"))
    && !(ref.kind === "free" && (ref.difficulty === "beginner" || ref.difficulty === "easy"))

  // Opens a puzzle, or resumes a saved one ({ moves, assisted }). The board
  // is regenerated on a worker thread; play starts when it arrives.
  function open(r, saved) {
    bloomWait.stop()
    ref = r
    session = null
    won = null
    result = null
    hint = null
    board.celebrating = false
    loading = true
    token += 1
    pending = { token, ref: r, saved: saved || null }
    message = ""
    if (preparer.ready) preparer.sendMessage({ token, ref: r })
  }

  function begin(p, saved) {
    loading = false
    if (!p) { game.goBack(); return }
    session = saved ? S.resume(p, saved.moves) : S.start(p)
    assisted = !!(saved && saved.assisted)
    focusColumn = 0
    confirmRestart = false
    message = ref.kind === "tutorial" ? tutorialText(ref.index) : ""
    if (S.view(session).solved) { win(); showResult() }
    // a resumed puzzle is saved again only when it changes, so resuming
    // never makes an old save look newer than another host's
    else if (!saved) game.saveCurrent(ref, S.history(session), assisted)
  }

  WorkerScript {
    id: preparer
    source: "js/prepare.mjs"
    onReadyChanged: if (ready && play.pending) sendMessage({ token: play.pending.token, ref: play.pending.ref })
    onMessage: function(m) {
      if (!play.pending || m.token !== play.pending.token) return
      const saved = play.pending.saved
      play.pending = null
      play.begin(m.puzzle, saved)
    }
  }

  function tutorialText(i) {
    return [
      qsTr("Click a pillar to lift its top orb, then click another pillar to put it there. Make each pillar one colour!"),
      qsTr("Any orb can go on any colour. Use the empty pillar as a place to wait."),
      qsTr("Three colours now. Try to finish in as few moves as you can."),
    ][i] || ""
  }

  // the words shown with no hint: the tutorial's lesson, or nothing
  function defaultText() {
    return ref && ref.kind === "tutorial" ? tutorialText(ref.index) : ""
  }

  function touch(column) {
    if (!session || won) return
    board.land()
    const out = S.touch(session, column)
    session = out.state
    focusColumn = column
    // a hint stays lit while its orb is lifted, even through a refusal,
    // until the orb lands or goes back
    const keep = hint && ((out.effect.kind === "lift" && hint.from === column) || out.effect.kind === "refuse")
    if (hint && !keep) {
      hint = null
      // the hint's words go with its highlight
      if (out.effect.kind !== "move") message = defaultText()
    }
    if (out.effect.kind === "move") message = ""
    played(out.effect)
  }

  // after the session changed: animate and sound the effect, and for a move
  // win or save (a touch and a redo both end here)
  function played(effect) {
    // the move's own note first: with less movement the board lands the orb
    // (and may ring a pillar's chime) at once
    game.sound.effect(effect)
    board.effect(effect)
    if (effect.kind === "move") {
      if (S.view(session).solved) {
        board.celebrating = true
        win()
        // no landing to wait for (less movement, or no room to draw the
        // board): still hold the board a moment so the last flower is seen
        if (Theme.reducedMotion || !board.busy) bloomWait.restart()
      } else {
        game.saveCurrent(ref, S.history(session), assisted)
      }
    }
  }

  // records the win at once, so leaving during the last animation keeps it
  function win() {
    if (won) return
    won = game.recordSolved(ref, S.view(session).moves, assisted)
  }

  function showResult() {
    if (!won || result) return
    result = won
    game.sound.cue("solved")
    sparkles.burst()
  }

  function cancel() {
    if (session && session.selected >= 0) touch(session.selected)
  }

  function undo() {
    if (!session || won || S.view(session).moves === 0) return
    session = S.undo(session)
    board.stop()
    hint = null
    message = defaultText()
    game.sound.cue("undo")
    game.saveCurrent(ref, S.history(session), assisted)
  }

  // plays the move taken back last, again (Ctrl+Shift+Z, or the button)
  function redo() {
    if (!session || won || !S.canRedo(session)) return
    board.land()
    if (session.selected >= 0) { session = S.cancel(session); board.stop() }
    const out = S.redo(session)
    if (out.effect.kind !== "move") return
    session = out.state
    focusColumn = out.effect.to
    hint = null
    message = ""
    played(out.effect)
  }

  function restart() {
    if (!session) return
    bloomWait.stop()
    session = S.restart(session)
    // a new attempt uses the latest layout and motion settings
    game.refreshSettings()
    board.stop()
    hint = null
    won = null
    result = null
    assisted = false
    confirmRestart = false
    board.celebrating = false
    message = ref.kind === "tutorial" ? tutorialText(ref.index) : ""
    game.sound.cue("restart")
    game.saveCurrent(ref, S.history(session), assisted)
  }

  function askHint() {
    if (!session || won) return
    session = S.cancel(session)
    const h = S.hint(session)
    assisted = true
    game.saveCurrent(ref, S.history(session), assisted)
    game.sound.cue("hint")
    if (h.kind === "play") {
      hint = h
      focusColumn = h.from
      message = qsTr("Try lifting from one shining pillar and placing on the other.")
    } else if (h.kind === "back") {
      hint = null
      message = h.steps === 1 ? qsTr("That way is hard. Undo 1 move to get back on track.")
                              : qsTr("That way is hard. Undo %1 moves to get back on track.").arg(h.steps)
    } else {
      hint = null
      message = qsTr("No hint here. You can always start again.")
    }
  }

  function finished() {
    // let the last pillar's flower open before the card covers the board
    if (won) bloomWait.restart()
  }
  // a still pause, so it stays even with less movement
  Timer { id: bloomWait; interval: 550; onTriggered: play.showResult() }

  function handleKey(event) {
    if (result) return results.handleKey(event)
    if (!session) return event.key === Qt.Key_Escape ? (game.goBack(), true) : false
    const order = board.geom.order
    const ctrl = event.modifiers & Qt.ControlModifier
    switch (event.key) {
    case Qt.Key_Left: case Qt.Key_Up:
      focusColumn = Layout.step(order, focusColumn, -1); return true
    case Qt.Key_Right: case Qt.Key_Down: case Qt.Key_Tab:
      focusColumn = Layout.step(order, focusColumn, 1); return true
    case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter:
      touch(focusColumn); return true
    case Qt.Key_Escape:
      if (session.selected >= 0) cancel()
      else if (confirmRestart) confirmRestart = false
      else game.goBack()
      return true
    case Qt.Key_U: undo(); return true
    // Ctrl+Shift+Z redoes, Ctrl+Z undoes (never both)
    case Qt.Key_Z:
      if (!ctrl) return false
      if (event.modifiers & Qt.ShiftModifier) redo(); else undo()
      return true
    case Qt.Key_H: askHint(); return true
    case Qt.Key_R:
      // a held key repeats; only a second press confirms
      if (event.isAutoRepeat) return true
      if (confirmRestart) restart()
      else { confirmRestart = true; restartTimer.restart() }
      return true
    }
    if (event.key >= Qt.Key_1 && event.key <= Qt.Key_9) {
      // a number chooses a pillar; Space or Enter then lifts or places
      const c = event.key - Qt.Key_1
      if (view && c < view.columns.length) focusColumn = c
      return true
    }
    return false
  }

  Timer { id: restartTimer; interval: 3000; onTriggered: play.confirmRestart = false }

  // top bar
  Item {
    id: bar
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: parent.top
    anchors.margins: Theme.em
    height: Theme.em * 4.6

    Row {
      spacing: Theme.em * 0.8
      anchors.left: parent.left
      anchors.top: parent.top
      // the title and counts never run under the buttons on the right
      width: parent.width - tools.width - Theme.em
      RoundButton { id: backButton; icon: "back"; size: play.toolSize; label: play.compact ? "" : qsTr("Back"); onActivated: play.game.goBack() }
      Column {
        width: parent.width - backButton.width - parent.spacing
        anchors.verticalCenter: parent.verticalCenter
        anchors.verticalCenterOffset: -Theme.em * 0.6
        spacing: Theme.em * 0.1
        // the area's name and its place ("· 3 of 8"): the name keeps at least half
        // the row, and either part shortens if it must
        Row {
          width: parent.width
          Text {
            id: nameText
            // up to half the row, so a long place ("· Temple Keeper")
            // cannot squeeze the name to a letter
            width: Math.min(implicitWidth, Math.max(parent.width * 0.5, parent.width - placeText.implicitWidth))
            elide: Text.ElideRight
            text: play.ref ? play.game.nameOf(play.ref) : ""
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.em * 1.35
            font.bold: true
            style: Text.Raised
            styleColor: "#90000000"
          }
          Text {
            id: placeText
            width: Math.min(implicitWidth, parent.width - nameText.width)
            elide: Text.ElideRight
            text: play.ref ? " · " + play.game.placeOf(play.ref) : ""
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.em * 1.35
            font.bold: true
            style: Text.Raised
            styleColor: "#90000000"
          }
        }
        Text {
          width: parent.width
          elide: Text.ElideRight
          text: play.view ? (play.showPar ? qsTr("Moves: %1  ·  Par: %2").arg(play.view.moves).arg(play.session.puzzle.par)
                                          : qsTr("Moves: %1").arg(play.view.moves)) : ""
          color: Theme.inkSoft
          font.family: Theme.font
          font.pixelSize: Theme.em * 1.05
          style: Text.Raised
          styleColor: "#90000000"
        }
      }
    }

    Row {
      id: tools
      spacing: play.compact ? Theme.em * 0.5 : Theme.em * 0.8
      anchors.right: parent.right
      anchors.top: parent.top
      RoundButton { icon: "undo"; size: play.toolSize; label: play.compact ? "" : (qsTr("Undo")); enabled: !!play.view && play.view.moves > 0; onActivated: play.undo() }
      RoundButton { icon: "redo"; size: play.toolSize; label: play.compact ? "" : (qsTr("Redo")); enabled: !!play.session && S.canRedo(play.session) && !play.won; onActivated: play.redo() }
      RoundButton { icon: "restart"; size: play.toolSize; label: play.confirmRestart ? qsTr("Press R") : qsTr("Hold"); hold: 700; lit: play.confirmRestart; onActivated: play.restart() }
      RoundButton { icon: "hint"; size: play.toolSize; label: play.compact ? "" : (qsTr("Hint")); onActivated: play.askHint() }
      RoundButton { icon: "help"; size: play.toolSize; label: play.compact ? "" : (qsTr("Keys")); onActivated: play.game.showHelp() }
    }
  }

  Text {
    anchors.centerIn: parent
    visible: play.loading
    text: qsTr("Waking the temple…")
    color: Theme.inkSoft
    font.family: Theme.font
    font.pixelSize: Theme.em * 1.4
    style: Text.Raised
    styleColor: "#90000000"
  }

  Board {
    id: board
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.top: bar.bottom
    anchors.bottom: tip.top
    anchors.margins: Theme.em
    view: play.view
    pattern: play.game.settings.layout
    focusColumn: play.focusColumn
    hint: play.hint
    onTouched: function(c) { play.touch(c) }
    onCancelled: play.cancel()
    onSettled: play.finished()
    // a pillar filled by a move rings its colour's note, unless it is the
    // winning move: the fanfare has that moment
    onOpened: function(column, colour) { if (play.session && !S.view(play.session).solved) play.game.sound.cue("complete", colour) }
  }

  // a gentle line of guidance under the board
  Rectangle {
    id: tip
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.em
    width: Math.min(parent.width - Theme.em * 4, tipText.implicitWidth + Theme.em * 2.4)
    height: play.message !== "" ? tipText.implicitHeight + Theme.em * 1.2 : 0
    radius: Theme.em * 0.8
    color: Theme.card
    border.color: Theme.cardEdge
    visible: height > 0
    Text {
      id: tipText
      anchors.centerIn: parent
      width: Math.min(implicitWidth, play.width - Theme.em * 6)
      text: play.message
      wrapMode: Text.WordWrap
      horizontalAlignment: Text.AlignHCenter
      color: Theme.ink
      font.family: Theme.font
      font.pixelSize: Theme.em * 1.1
    }
  }

  Sparkles {
    id: sparkles
    anchors.fill: board
  }

  Results {
    id: results
    anchors.fill: parent
    visible: !!play.result
    result: play.result
    moves: play.view ? play.view.moves : 0
    par: play.showPar && play.session ? play.session.puzzle.par : 0
    hasNext: !!play.ref && !!play.game.nextRef(play.ref)
    backLabel: play.ref && play.ref.kind === "free" ? qsTr("Sizes") : qsTr("Map")
    onReplay: play.restart()
    onNext: play.game.playNext(play.ref)
    onLeave: play.game.goBack()
  }

  // a friend from the jungle cheers each solved puzzle
  Friend {
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.rightMargin: Theme.em * 2
    anchors.bottomMargin: -Theme.em * 0.5
    size: Math.min(play.width, play.height) * 0.26
    // the friend of the scene behind the board (free play sizes have areas
    // too): tutorial, clearing, river, ruins, waterfall, temple, heart
    kind: ["toucan", "toucan", "frog", "monkey", "frog", "monkey", "frog"][play.game.areaIndex(play.ref)] ?? "toucan"
    cheering: !!play.result
  }
}
