import QtQuick

// Every key, in one card (shown with ?).
Item {
  id: root
  signal closed()
  // the plugin closes on Q; the app asks first
  property bool quitsAtOnce: false

  function handleKey(event) { closed(); return true }

  // each time it opens, it starts at the top
  onVisibleChanged: if (visible) rows.contentY = 0

  // the arrow and page keys scroll the rows when the card is too short for
  // them; true when they did
  function scroll(event) {
    const step = { [Qt.Key_Up]: -1, [Qt.Key_Down]: 1, [Qt.Key_PageUp]: -4, [Qt.Key_PageDown]: 4 }[event.key]
    if (!step || !rows.interactive) return false
    rows.contentY = Math.max(0, Math.min(rows.contentHeight - rows.height, rows.contentY + step * Theme.em * 1.6))
    return true
  }

  readonly property var keys: [
    [qsTr("← → or 1–9"), qsTr("choose a pillar")],
    [qsTr("Space or Enter"), qsTr("lift an orb, or put it down")],
    [qsTr("Esc"), qsTr("put the orb back, or go back")],
    [qsTr("U or Ctrl+Z"), qsTr("undo a move")],
    [qsTr("Ctrl+Shift+Z"), qsTr("redo it")],
    [qsTr("R, then R"), qsTr("start the puzzle again")],
    [qsTr("H"), qsTr("a hint")],
    [qsTr("?"), qsTr("these keys")],
    [qsTr("F11"), qsTr("full screen (app)")],
    root.quitsAtOnce ? [qsTr("Q"), qsTr("close the game")] : [qsTr("Q, then Q"), qsTr("quit")],
  ]

  Rectangle { anchors.fill: parent; color: "#B0000000" }
  MouseArea { anchors.fill: parent; onClicked: root.closed() }

  Card {
    anchors.centerIn: parent
    width: Math.min(parent.width - Theme.em * 4, Theme.em * 32)
    // never taller than the window; the rows scroll inside when they must
    height: Math.min(grid.implicitHeight + title.implicitHeight + Theme.em * 4.8, parent.height - Theme.em * 2)
    Text {
      id: title
      anchors.top: parent.top
      anchors.topMargin: Theme.em * 1.2
      anchors.horizontalCenter: parent.horizontalCenter
      text: qsTr("Keys")
      color: Theme.gold
      font.family: Theme.font
      font.pixelSize: Theme.em * 1.8
      font.bold: true
    }
    Flickable {
      id: rows
      anchors.top: title.bottom
      anchors.topMargin: Theme.em
      anchors.bottom: parent.bottom
      // a strip below the rows for the "more" cue
      anchors.bottomMargin: Theme.em * 1.8
      anchors.left: parent.left
      anchors.right: parent.right
      clip: true
      contentHeight: grid.implicitHeight
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds
    Grid {
      id: grid
      anchors.horizontalCenter: parent.horizontalCenter
      columns: 2
      columnSpacing: Theme.em * 1.5
      rowSpacing: Theme.em * 0.5
      Repeater {
        model: root.keys.length * 2
        Text {
          required property int index
          text: root.keys[Math.floor(index / 2)][index % 2]
          color: index % 2 === 0 ? Theme.gold : Theme.ink
          font.family: Theme.font
          font.pixelSize: Theme.em * 1.1
          font.bold: index % 2 === 0
        }
      }
    }
    }
    // there is more below: say so
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.bottom: parent.bottom
      anchors.bottomMargin: Theme.em * 0.4
      visible: rows.interactive && !rows.atYEnd
      text: qsTr("▾ more")
      color: Theme.gold
      font.family: Theme.font
      font.pixelSize: Theme.em * 0.85
    }
  }
}
