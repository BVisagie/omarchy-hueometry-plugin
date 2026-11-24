import QtQuick
import QtQuick.Shapes
import "js/layout.mjs" as Layout
import "js/palette.mjs" as Palette

// The puzzle board: pillars placed by a layout, the orbs on them, and the
// animations between two engine states. It draws what `view` says (from
// session.mjs) and reports touches; it never decides a rule.
Item {
  id: board

  // { columns (top first), cap, selected, targets, solved, complete } from
  // session.view
  property var view: null
  property string pattern: "line"
  property int focusColumn: -1
  // { kind: "play", from, to } while a hint is shown
  property var hint: null
  property bool celebrating: false

  signal touched(int column)
  signal cancelled()
  signal settled()
  // a move just filled this pillar with one colour: its flower opened
  signal opened(int column, int colour)

  readonly property int count: view ? view.columns.length : 0
  readonly property int cap: view ? view.cap : 1
  readonly property var geom: Layout.place(pattern, count, width, height, cap)
  readonly property real unit: geom.unit
  readonly property real orbSize: unit * 0.9

  // what is drawn: the columns, minus any orb that is in the air
  property var stack: []
  property bool busy: false

  function copy(cols) { return cols.map(c => c.slice()) }

  // the pillars whose flower is open: the engine's `complete`, drawn in step
  // with the orbs, so a flower waits for its last orb to land and closes
  // while an orb is lifted from its pillar
  property var bloomed: []
  function bloomExcept(column) { bloomed = (view && view.complete ? view.complete : []).map((d, i) => d && i !== column) }

  function sync() {
    if (!view) { stack = []; bloomed = []; return }
    bloomExcept(view.selected)
    const cols = copy(view.columns)
    // (with no room to draw the board, nothing is lifted into view)
    if (view.selected >= 0 && cols[view.selected].length > 0 && geom.columns[view.selected]) {
      const top = cols[view.selected].shift()
      flyer.colour = top
      flyer.place(Layout.liftedAt(geom.columns[view.selected], cap, unit))
      flyer.visible = true
    } else {
      flyer.visible = false
    }
    stack = cols
  }

  // the engine's completed pillars now and before the latest change: with
  // no room to draw the board, a move's chime is decided from these
  property var shownComplete: []
  property var priorComplete: []
  onViewChanged: {
    priorComplete = shownComplete
    shownComplete = view && view.complete ? view.complete : []
    if (!busy) sync()
  }
  onGeomChanged: if (!busy) sync()

  function topOf(cols, c) { return cols[c].length - 1 }

  // Plays what session.touch answered.
  function effect(e) {
    if (!view) return
    // an orb still in the air lands first (Play calls land() earlier still)
    flyer.settle()
    if (!geom.columns.length) {
      // nothing to animate, but a filled pillar still rings
      if (e.kind === "move" && shownComplete[e.to] && !priorComplete[e.to]) opened(e.to, e.bead)
      return
    }
    switch (e.kind) {
    case "lift": {
      const cols = copy(view.columns)
      const colour = cols[e.column].shift()
      stack = cols
      bloomExcept(e.column)
      flyer.colour = colour
      flyer.fly(Layout.beadAt(geom.columns[e.column], cols[e.column].length, unit),
                Layout.liftedAt(geom.columns[e.column], cap, unit), 0, Theme.ms(150), null)
      break
    }
    case "drop": {
      const cols = copy(view.columns)
      stack = cols.map((c, i) => i === e.column ? c.slice(1) : c)
      bloomExcept(e.column)
      flyer.fly(Layout.liftedAt(geom.columns[e.column], cap, unit),
                Layout.beadAt(geom.columns[e.column], cols[e.column].length - 1, unit), 0, Theme.ms(150),
                function() { board.finish(e.column, false) })
      break
    }
    case "move": {
      // the board already shows the new state; hold the landing orb back
      const cols = copy(view.columns)
      stack = cols.map((c, i) => i === e.to ? c.slice(1) : c)
      bloomExcept(e.to)
      flyer.colour = e.bead
      const a = geom.columns[e.from], b = geom.columns[e.to]
      flyer.fly(Layout.liftedAt(a, cap, unit), Layout.liftedAt(b, cap, unit), unit * 1.6, Theme.ms(260), function() {
        flyer.fly(Layout.liftedAt(b, cap, unit), Layout.beadAt(b, cols[e.to].length - 1, unit), 0, Theme.ms(130), function() { board.finish(e.to, true) })
      })
      break
    }
    case "refuse":
      flyer.wobble()
      pillars.itemAt(e.to)?.nudge()
      break
    case "empty":
      pillars.itemAt(e.column)?.nudge()
      break
    }
  }

  // land any orb still in the air, from the state it flew in: call before
  // the session changes, so a pillar it filled opens even if the next touch
  // lifts from that pillar
  function land() { flyer.settle() }

  // drop any orb in the air and draw the engine's state (undo, restart)
  function stop() {
    flyer.stopFlight()
    busy = false
    sync()
  }

  // an orb has landed on `column`; a move (not a put-back) whose landing
  // opens that pillar's flower says so
  function finish(column, moved) {
    const before = bloomed.slice()
    busy = false
    sync()
    settled()
    if (column === undefined || column < 0 || !stack[column] || !stack[column].length) return
    if (moved && bloomed[column] && !before[column]) opened(column, stack[column][0])
    // no room to draw the board: nothing to squash
    if (geom.columns[column]) landed(column)
  }

  // the landed orb gives a little squash, and dust puffs from the stone
  function landed(column) {
    const k = stack[column].length - 1
    // the column's top orb is the first of its row
    const row = restingColumns.itemAt(column)
    const orb = row ? row.orbs.itemAt(0) : null
    if (orb) orb.land()
    const g = geom.columns[column]
    const at = Layout.beadAt(g, k, unit)
    const a = g.angle * Math.PI / 180
    dust.burst(at.x - Math.sin(a) * orbSize * 0.45, at.y + Math.cos(a) * orbSize * 0.45, g.angle)
  }

  // the medallion the circle's spokes grow from
  Shape {
    visible: board.pattern === "circle" && board.count > 0
    x: geom.centre ? geom.centre.x - width / 2 : 0
    y: geom.centre ? geom.centre.y - height / 2 : 0
    width: geom.inner ? geom.inner * 1.7 : 0
    height: width
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: Theme.stoneDark
      strokeWidth: Math.max(2, board.unit * 0.08)
      fillGradient: RadialGradient {
        centerX: geom.inner ? geom.inner * 0.85 : 0; centerY: centerX; centerRadius: centerX
        focalX: centerX * 0.8; focalY: centerX * 0.7
        GradientStop { position: 0.0; color: Theme.stoneLight }
        GradientStop { position: 1.0; color: Theme.stoneDark }
      }
      PathAngleArc {
        centerX: geom.inner ? geom.inner * 0.85 : 0; centerY: centerX
        radiusX: geom.inner ? geom.inner * 0.82 : 0; radiusY: radiusX; startAngle: 0; sweepAngle: 360
      }
    }
    ShapePath {
      strokeColor: Qt.alpha(Theme.gold, 0.5)
      strokeWidth: Math.max(1.5, board.unit * 0.05)
      fillColor: "transparent"
      PathAngleArc {
        centerX: geom.inner ? geom.inner * 0.85 : 0; centerY: centerX
        radiusX: geom.inner ? geom.inner * 0.5 : 0; radiusY: radiusX; startAngle: 0; sweepAngle: 360
      }
    }
  }

  Repeater {
    id: pillars
    model: board.count
    Pillar {
      id: pillar
      required property int index
      readonly property var c: board.geom.columns[index] || ({ x: 0, y: 0, w: 1, h: 1, angle: 0 })
      px: c.x
      py: c.y
      w: c.w
      h: c.h
      angle: c.angle
      focused: index === board.focusColumn
      target: !!board.view && board.view.targets.indexOf(index) >= 0
      hinted: !!board.hint && board.hint.kind === "play" && (board.hint.from === index || board.hint.to === index)
      empty: !!board.view && board.view.columns[index].length === 0
      seed: index + 1
      bloomAtEnd: board.pattern === "circle"
      complete: board.bloomed[index] === true
      // from the orbs as drawn, so a flower changes colour only with them
      tone: board.stack[index] && board.stack[index].length ? Palette.orb(board.stack[index][board.stack[index].length - 1]) : null

      function nudge() { shakeAnim.restart() }
      SequentialAnimation {
        id: shakeAnim
        NumberAnimation { target: pillar; property: "shake"; to: board.unit * 0.12; duration: Theme.ms(50) }
        NumberAnimation { target: pillar; property: "shake"; to: -board.unit * 0.1; duration: Theme.ms(70) }
        NumberAnimation { target: pillar; property: "shake"; to: 0; duration: Theme.ms(60) }
      }
    }
  }

  // the orbs at rest, a row per pillar: a row is rebuilt only when its own
  // orbs change (its content is compared as text), so a landing orb keeps
  // its squash while another pillar changes
  Repeater {
    id: restingColumns
    model: Math.min(board.stack.length, board.geom.columns.length)
    Item {
      id: row
      required property int index
      readonly property string content: JSON.stringify(board.stack[index] || [])
      readonly property var list: JSON.parse(content)
      readonly property alias orbs: orbs
      Repeater {
        id: orbs
        model: row.list
        Orb {
          required property int index
          required property int modelData
          readonly property int k: row.list.length - 1 - index
          readonly property var at: Layout.beadAt(board.geom.columns[row.index], k, board.unit)
          colour: modelData
          size: board.orbSize
          cx: at.x
          cy: at.y
          axis: board.geom.columns[row.index].angle
          glowing: board.celebrating
        }
      }
    }
  }

  // a soft puff of dust where an orb lands, spreading along the stone
  Item {
    id: dust
    z: 9
    property real ax: 0
    property real ay: 0
    property real angle: 0
    property real t: 1
    visible: t < 1
    function burst(x, y, angle) {
      if (Theme.reducedMotion) return
      ax = x; ay = y; dust.angle = angle
      puff.restart()
    }
    Repeater {
      model: 6
      Rectangle {
        required property int index
        readonly property real side: index % 2 ? 1 : -1
        readonly property int ring: index >> 1
        readonly property real a: dust.angle * Math.PI / 180
        // across the pillar, and up it
        readonly property real across: side * board.unit * (0.3 + ring * 0.22) * (0.35 + 0.65 * dust.t)
        readonly property real up: board.unit * (0.04 + 0.22 * dust.t * (1 - 0.3 * ring))
        width: board.unit * (0.14 + 0.16 * dust.t)
        height: width
        radius: width / 2
        x: dust.ax + Math.cos(a) * across + Math.sin(a) * up - width / 2
        y: dust.ay + Math.sin(a) * across - Math.cos(a) * up - height / 2
        color: "#E8E2C8"
        opacity: 0.42 * (1 - dust.t) * (1 - ring * 0.25)
      }
    }
    NumberAnimation { id: puff; target: dust; property: "t"; from: 0; to: 1; duration: Theme.ms(480); easing.type: Easing.OutCubic }
  }

  // the orb in the air: lifted, flying, or settling
  Orb {
    id: flyer
    visible: false
    size: board.orbSize
    glowing: true
    z: 10
    property var from: ({ x: 0, y: 0 })
    property var to: ({ x: 0, y: 0 })
    property real arc: 0
    property real t: 1
    property real jiggle: 0
    property var after: null
    cx: from.x + (to.x - from.x) * t + jiggle
    cy: from.y + (to.y - from.y) * t - Math.sin(Math.PI * t) * arc

    function place(p) { from = p; to = p; t = 1 }
    function fly(a, b, height, duration, then) {
      flight.stop()
      from = a; to = b; arc = height; t = 0; after = then; visible = true
      board.busy = then !== null
      flight.duration = duration
      flight.start()
    }
    function wobble() { wobbleAnim.restart() }
    function stopFlight() { flight.stop(); after = null }
    // run the rest of the flight at once: a move's second leg, then its
    // landing (a few steps at most)
    function settle() {
      for (let i = 0; i < 4 && flight.running && after; i++) {
        const next = after
        after = null
        flight.stop()
        next()
      }
    }

    NumberAnimation {
      id: flight
      target: flyer
      property: "t"
      from: 0
      to: 1
      easing.type: Easing.InOutQuad
      onFinished: {
        const next = flyer.after
        flyer.after = null
        if (next) next()
      }
    }
    SequentialAnimation {
      id: wobbleAnim
      NumberAnimation { target: flyer; property: "jiggle"; to: board.unit * 0.18; duration: Theme.ms(45) }
      NumberAnimation { target: flyer; property: "jiggle"; to: -board.unit * 0.16; duration: Theme.ms(70) }
      NumberAnimation { target: flyer; property: "jiggle"; to: board.unit * 0.08; duration: Theme.ms(60) }
      NumberAnimation { target: flyer; property: "jiggle"; to: 0; duration: Theme.ms(50) }
    }
  }

  MouseArea {
    anchors.fill: parent
    onClicked: function(mouse) {
      const c = Layout.hit(board.geom.columns, mouse.x, mouse.y, board.unit)
      if (c >= 0) board.touched(c)
      else board.cancelled()
    }
  }
}
