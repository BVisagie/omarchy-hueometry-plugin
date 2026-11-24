import QtQuick

// Every key, in one card (shown with ?).
Item {
  id: root
  signal closed()
  // the plugin closes on Q; the app asks first
  property bool quitsAtOnce: false

  function handleKey(event) { closed(); return true }

  readonly property var keys: [
    [qsTr("← → or 1–9"), qsTr("choose a pillar")],
    [qsTr("Space or Enter"), qsTr("lift an orb, or put it down")],
    [qsTr("Esc"), qsTr("put the orb back, or go back")],
    [qsTr("U or Ctrl+Z"), qsTr("undo a move")],
    [qsTr("R, then R"), qsTr("start the puzzle again")],
    [qsTr("H"), qsTr("a hint")],
    [qsTr("?"), qsTr("these keys")],
    [qsTr("F11"), qsTr("full screen (app)")],
    root.quitsAtOnce ? [qsTr("Q"), qsTr("close the game")] : [qsTr("Q, then Q"), qsTr("quit")],
  ]

  Rectangle { anchors.fill: parent; color: "#80000000" }
  MouseArea { anchors.fill: parent; onClicked: root.closed() }

  Card {
    anchors.centerIn: parent
    width: Math.min(parent.width - Theme.em * 4, Theme.em * 32)
    height: grid.implicitHeight + title.implicitHeight + Theme.em * 4
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
    Grid {
      id: grid
      anchors.top: title.bottom
      anchors.topMargin: Theme.em
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
}
