import QtQuick
import "js/session.mjs" as S
import "js/store.mjs" as Store

// The adventure: the tutorial, then six areas of the temple, each with eight
// puzzles. An area opens once five puzzles of the one before it are done.
Item {
  id: map
  required property var game
  // the first steps until they are done, then the area last visited (set
  // once on opening: a binding here would loop through lastArea)
  property int area: 0
  // free play can leave lastArea on an area not open yet
  function openAtOrBefore(i) {
    let a = Math.max(0, Math.min(i, S.AREAS.length))
    while (a > 0 && !isOpen(a)) a--
    return a
  }
  property int level: 0
  // 0: choosing an area, 1: choosing a level in it
  property int depth: 0

  readonly property var areas: game.areas
  readonly property int perArea: 8

  function isOpen(i) { return i === 0 ? true : Store.areaOpen(game.progress, S.AREAS, i - 1, perArea) }
  function levelRef(i) { return area === 0 ? { kind: "tutorial", index: i } : { kind: "level", area: S.AREAS[area - 1], index: i } }
  function levelCount() { return area === 0 ? 3 : perArea }

  function handleKey(event) {
    if (depth === 0) {
      switch (event.key) {
      case Qt.Key_Left: case Qt.Key_Up: area = (area + areas.length - 1) % areas.length; return true
      case Qt.Key_Right: case Qt.Key_Down: case Qt.Key_Tab: area = (area + 1) % areas.length; return true
      case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: if (isOpen(area)) { depth = 1; level = 0 } return true
      case Qt.Key_Escape: game.goBack(); return true
      }
    } else {
      switch (event.key) {
      case Qt.Key_Left: case Qt.Key_Up: level = (level + levelCount() - 1) % levelCount(); return true
      case Qt.Key_Right: case Qt.Key_Down: case Qt.Key_Tab: level = (level + 1) % levelCount(); return true
      case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: game.start(levelRef(level)); return true
      case Qt.Key_Escape: depth = 0; return true
      }
    }
    return false
  }

  onAreaChanged: { game.lastArea = area; areaScroll.show(tiles.itemAt(area)) }
  // reveal the starting selection once the grid has placed its tiles
  Component.onCompleted: {
    area = game.progress.tutorial ? openAtOrBefore(game.lastArea) : 0
    Qt.callLater(function() { areaScroll.show(tiles.itemAt(area)) })
  }
  onLevelChanged: levelScroll.show(stones.itemAt(level))

  RoundButton {
    anchors.left: parent.left
    anchors.top: parent.top
    anchors.margins: Theme.em
    icon: "back"
    label: qsTr("Back")
    onActivated: map.depth === 1 ? map.depth = 0 : map.game.goBack()
  }

  Text {
    id: heading
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Theme.em * 1.5
    text: map.depth === 0 ? qsTr("Choose where to explore") : map.areas[map.area].name
    color: Theme.ink
    font.family: Theme.font
    font.pixelSize: Theme.em * 2
    font.bold: true
    style: Text.Raised
    styleColor: "#A0000000"
  }

  // areas
  Scroller {
    id: areaScroll
    visible: map.depth === 0
    anchors.fill: parent
    anchors.topMargin: Theme.em * 5
    anchors.bottomMargin: Theme.em
  Grid {
    anchors.horizontalCenter: parent.horizontalCenter
    // as many columns as fit, from two to four
    columns: Math.max(1, Math.min(4, Math.floor((map.width - Theme.em * 4) / (Theme.em * 14.2))))
    horizontalItemAlignment: Grid.AlignHCenter
    spacing: Theme.em * 1.2
    Repeater {
      id: tiles
      model: map.areas.length
      Item {
        id: tile
        required property int index
        readonly property bool open: map.isOpen(index)
        readonly property int done: index === 0 ? Store.doneIn(map.game.progress, "tutorial", 3) : Store.doneIn(map.game.progress, S.AREAS[index - 1], map.perArea)
        width: Theme.em * 13
        height: Theme.em * 7.6
        Card {
          anchors.fill: parent
          border.color: map.area === tile.index ? Theme.glow : Theme.cardEdge
          border.width: map.area === tile.index ? Math.max(3, Theme.em * 0.2) : Math.max(2, Theme.em * 0.12)
          opacity: tile.open ? 1 : 0.55
        }
        Column {
          anchors.centerIn: parent
          spacing: Theme.em * 0.4
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            width: tile.width - Theme.em
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            maximumLineCount: 2
            text: map.areas[tile.index].name
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.em * 1.15
            font.bold: true
          }
          Text {
            anchors.horizontalCenter: parent.horizontalCenter
            text: tile.open ? qsTr("%1 of %2 solved").arg(tile.done).arg(tile.index === 0 ? 3 : map.perArea) : qsTr("Solve 5 in the area before")
            color: Theme.inkSoft
            font.family: Theme.font
            font.pixelSize: Theme.em * 0.95
          }
          Icon { anchors.horizontalCenter: parent.horizontalCenter; kind: tile.open ? (tile.done === (tile.index === 0 ? 3 : map.perArea) ? "check" : "play") : "lock"; size: Theme.em * 1.6 }
        }
        MouseArea {
          anchors.fill: parent
          onClicked: { map.area = tile.index; if (tile.open) { map.depth = 1; map.level = 0 } }
        }
      }
    }
  }

  }

  // the puzzles of one area: round stones
  Scroller {
    id: levelScroll
    visible: map.depth === 1
    anchors.fill: parent
    anchors.topMargin: Theme.em * 5
    anchors.bottomMargin: Theme.em
  Grid {
    anchors.horizontalCenter: parent.horizontalCenter
    // as many stones as fit in a row, up to four (the keys move in order)
    columns: Math.max(1, Math.min(4, Math.floor((map.width - Theme.em * 2 + spacing) / (Theme.em * 7 + spacing))))
    spacing: Theme.em * 1.2
    Repeater {
      id: stones
      model: map.depth === 1 ? map.levelCount() : 0
      Item {
        id: stone
        required property int index
        readonly property var rec: map.game.progress.done[Store.key(map.levelRef(index))]
        width: Theme.em * 7
        height: Theme.em * 7.5
        Rectangle {
          width: Theme.em * 6
          height: width
          anchors.horizontalCenter: parent.horizontalCenter
          radius: width / 2
          gradient: Gradient {
            GradientStop { position: 0.0; color: stone.rec ? "#B6C37A" : Theme.stoneLight }
            GradientStop { position: 1.0; color: stone.rec ? "#4E6A2A" : Theme.stoneDark }
          }
          border.color: map.level === stone.index ? Theme.glow : "#40000000"
          border.width: map.level === stone.index ? Math.max(3, Theme.em * 0.22) : 2
          Text {
            anchors.centerIn: parent
            text: stone.index + 1
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.em * 2.2
            font.bold: true
            style: Text.Raised
            styleColor: "#90000000"
          }
        }
        Text {
          anchors.bottom: parent.bottom
          anchors.horizontalCenter: parent.horizontalCenter
          text: stone.rec ? qsTr("best %1").arg(stone.rec.best) : ""
          color: Theme.inkSoft
          font.family: Theme.font
          font.pixelSize: Theme.em * 0.9
        }
        MouseArea { anchors.fill: parent; onClicked: map.game.start(map.levelRef(stone.index)) }
      }
    }
  }
  }
}
