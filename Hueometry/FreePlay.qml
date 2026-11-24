import QtQuick
import "js/session.mjs" as S
import "js/palette.mjs" as Palette

// Free play: choose a difficulty and get a random puzzle of that size.
Item {
  id: free
  required property var game
  property int cursor: 0

  readonly property var kinds: [
    { key: "beginner", name: qsTr("Sprout"), colours: 3, cap: 3 },
    { key: "easy", name: qsTr("Explorer"), colours: 4, cap: 4 },
    { key: "medium", name: qsTr("Adventurer"), colours: 5, cap: 5 },
    { key: "hard", name: qsTr("Temple Keeper"), colours: 6, cap: 6 },
    { key: "expert", name: qsTr("Legend"), colours: 6, cap: 10 },
  ]

  function pick(i) { game.startFree(kinds[i].key) }

  function handleKey(event) {
    switch (event.key) {
    case Qt.Key_Left: case Qt.Key_Up: cursor = (cursor + kinds.length - 1) % kinds.length; return true
    case Qt.Key_Right: case Qt.Key_Down: case Qt.Key_Tab: cursor = (cursor + 1) % kinds.length; return true
    case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: pick(cursor); return true
    case Qt.Key_Escape: game.goBack(); return true
    }
    return false
  }

  RoundButton {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: Theme.em
    icon: "back"
    label: qsTr("Back")
    onActivated: free.game.goBack()
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Theme.em * 1.5
    text: qsTr("How big a puzzle?")
    color: Theme.ink
    font.family: Theme.font
    font.pixelSize: Theme.em * 2
    font.bold: true
    style: Text.Raised
    styleColor: "#A0000000"
  }

  onCursorChanged: scroller.show(tiles.itemAt(cursor))

  Scroller {
    id: scroller
    anchors.fill: parent
    anchors.topMargin: Theme.em * 5
    anchors.bottomMargin: Theme.em
  Grid {
    anchors.horizontalCenter: parent.horizontalCenter
    columns: Math.max(1, Math.min(5, Math.floor((free.width - Theme.em * 2) / (Theme.em * 13.7))))
    spacing: Theme.em * 1.2
    Repeater {
      id: tiles
      model: free.kinds.length
      Item {
        id: tile
        required property int index
        readonly property var kind: free.kinds[index]
        width: Theme.em * 12.5
        height: Theme.em * 11
        Card {
          anchors.fill: parent
          border.color: free.cursor === tile.index ? Theme.glow : Theme.cardEdge
          border.width: free.cursor === tile.index ? Math.max(3, Theme.em * 0.2) : Math.max(2, Theme.em * 0.12)
        }
        Column {
          anchors.centerIn: parent
          spacing: Theme.em * 0.6
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.kind.name
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.em * 1.35
            font.bold: true
          }
          // a picture of the size: one orb per colour, a column per bead
          Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.em * 0.15
            Repeater {
              model: tile.kind.colours
              Rectangle {
                required property int index
                width: Theme.em * 1.1
                height: width
                radius: width / 2
                color: Palette.orb(index).base
                border.color: Palette.orb(index).dark
              }
            }
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("%1 colours · %2 each").arg(tile.kind.colours).arg(tile.kind.cap)
            color: Theme.inkSoft
            font.family: Theme.font
            font.pixelSize: Theme.em * 0.95
          }
        }
        MouseArea { anchors.fill: parent; onClicked: free.pick(tile.index) }
      }
    }
  }
  }
}
