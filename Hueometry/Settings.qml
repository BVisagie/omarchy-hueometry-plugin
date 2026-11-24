import QtQuick
import "js/palette.mjs" as Palette

// Settings: sound, motion, symbols, the board layout and the interface size.
// Up and down choose a row; left and right (or Space) change it.
Item {
  id: root
  required property var game
  property int cursor: 0

  readonly property var s: game.settings
  readonly property var rows: [
    { key: "music", kind: "level", label: qsTr("Music") },
    { key: "effects", kind: "level", label: qsTr("Sounds") },
    { key: "muted", kind: "switch", label: qsTr("Silence everything") },
    { key: "symbols", kind: "switch", label: qsTr("Symbols on orbs") },
    { key: "reducedMotion", kind: "switch", label: qsTr("Less movement") },
    { key: "layout", kind: "layout", label: qsTr("Board shape") },
    { key: "scale", kind: "size", label: qsTr("Size of words and buttons") },
  ]

  function change(row, dir) {
    const r = rows[row]
    if (r.kind === "level") game.setSetting(r.key, Math.max(0, Math.min(1, Math.round((s[r.key] + dir * 0.1) * 10) / 10)))
    else if (r.kind === "switch") game.setSetting(r.key, !s[r.key])
    else if (r.kind === "layout") game.setSetting(r.key, s.layout === "line" ? "circle" : "line")
    else if (r.kind === "size") {
      game.setSetting(r.key, Math.max(0.75, Math.min(1.5, Math.round((s.scale + dir * 0.125) * 8) / 8)))
      // every row changed size: lay them out now, then keep this one in view
      list.forceLayout()
      reveal()
    }
  }

  // keep the chosen row in view
  onCursorChanged: reveal()
  function reveal() {
    // back on the first row: right to the top, so the note above it shows
    if (cursor === 0) { scroller.contentY = 0; return }
    // (the Repeater is a child of the column too, so find the row by index)
    const row = list.children.find(c => c.index === cursor && c.r !== undefined)
    if (!row) return
    if (row.y < scroller.contentY) scroller.contentY = row.y
    else if (row.y + row.height > scroller.contentY + scroller.height) scroller.contentY = row.y + row.height - scroller.height
  }

  function handleKey(event) {
    switch (event.key) {
    case Qt.Key_Up: cursor = (cursor + rows.length - 1) % rows.length; return true
    case Qt.Key_Down: case Qt.Key_Tab: cursor = (cursor + 1) % rows.length; return true
    case Qt.Key_Left: change(cursor, -1); return true
    case Qt.Key_Right: change(cursor, 1); return true
    case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: change(cursor, 1); return true
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
    onActivated: root.game.goBack()
  }

  Text {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Theme.em * 1.5
    text: qsTr("Settings")
    color: Theme.ink
    font.family: Theme.font
    font.pixelSize: Theme.em * 2
    font.bold: true
    style: Text.Raised
    styleColor: "#A0000000"
  }

  Card {
    id: card
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Theme.em * 6
    width: Math.min(parent.width - Theme.em * 4, Theme.em * 36)
    // scrolls when the interface is made large on a small screen
    height: Math.min(list.implicitHeight + Theme.em * 2.4, root.height - Theme.em * 7)

    Flickable {
      id: scroller
      objectName: "scroller"
      anchors.fill: parent
      anchors.margins: Theme.em * 1.2
      clip: true
      contentHeight: list.implicitHeight
      boundsBehavior: Flickable.StopAtBounds
    Column {
      id: list
      width: scroller.width
      spacing: Theme.em * 0.5
      // without Qt Multimedia there is no sound: say so plainly, first, so it
      // is in view whatever row the keyboard is on
      Text {
        objectName: "soundMissing"
        visible: root.game.sound.missing
        width: list.width
        leftPadding: Theme.em
        rightPadding: Theme.em
        bottomPadding: Theme.em * 0.4
        wrapMode: Text.WordWrap
        text: qsTr("Sound is off because Qt Multimedia is not installed. Install the qt6-multimedia package to hear the game.")
        color: Theme.gold
        font.family: Theme.font
        font.pixelSize: Theme.em * 0.95
      }

      Repeater {
        model: root.rows.length
        Rectangle {
          id: row
          required property int index
          readonly property var r: root.rows[index]
          width: list.width
          height: r.kind === "layout" ? Theme.em * 6.5 : Theme.em * 2.9
          radius: Theme.em * 0.6
          color: root.cursor === index ? Qt.alpha(Theme.gold, 0.16) : "transparent"
          border.color: root.cursor === index ? Theme.glow : "transparent"
          border.width: Math.max(2, Theme.em * 0.12)

          Text {
            anchors.left: parent.left
            anchors.leftMargin: Theme.em
            anchors.verticalCenter: parent.verticalCenter
            text: row.r.label
            color: Theme.ink
            font.family: Theme.font
            font.pixelSize: Theme.em * 1.15
          }

          // music and sounds: ten steps
          Row {
            visible: row.r.kind === "level"
            anchors.right: parent.right
            anchors.rightMargin: Theme.em
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.em * 0.2
            // off
            Rectangle {
              width: Theme.em * 1.4
              height: Theme.em * 1.4
              anchors.bottom: parent.bottom
              radius: width / 2
              color: (root.s[row.r.key] || 0) === 0 ? Theme.gold : "#40FFFFFF"
              Text { anchors.centerIn: parent; text: "0"; color: Theme.inkDark; font.family: Theme.font; font.pixelSize: Theme.em * 0.8; font.bold: true }
              MouseArea { anchors.fill: parent; anchors.margins: -Theme.em * 0.1; onClicked: { root.cursor = row.index; root.game.setSetting(row.r.key, 0) } }
            }
            Repeater {
              model: 10
              Rectangle {
                required property int index
                width: Theme.em * 0.9
                height: Theme.em * (0.6 + index * 0.12)
                anchors.bottom: parent.bottom
                radius: Theme.em * 0.2
                color: (root.s[row.r.key] || 0) * 10 > index + 0.01 ? Theme.gold : "#40FFFFFF"
                MouseArea { anchors.fill: parent; anchors.margins: -Theme.em * 0.1; onClicked: { root.cursor = row.index; root.game.setSetting(row.r.key, (index + 1) / 10) } }
              }
            }
          }

          // switches
          Rectangle {
            visible: row.r.kind === "switch"
            anchors.right: parent.right
            anchors.rightMargin: Theme.em
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.em * 3.4
            height: Theme.em * 1.8
            radius: height / 2
            color: root.s[row.r.key] ? Theme.gold : "#50FFFFFF"
            Rectangle {
              width: parent.height - Theme.em * 0.3
              height: width
              radius: width / 2
              y: Theme.em * 0.15
              x: root.s[row.r.key] ? parent.width - width - Theme.em * 0.15 : Theme.em * 0.15
              Behavior on x { NumberAnimation { duration: Theme.ms(120) } }
              color: Theme.ink
            }
            MouseArea { anchors.fill: parent; onClicked: { root.cursor = row.index; root.change(row.index, 1) } }
          }

          // board shape: two small previews
          Row {
            visible: row.r.kind === "layout"
            anchors.right: parent.right
            anchors.rightMargin: Theme.em
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.em * 0.8
            Repeater {
              model: ["line", "circle"]
              Rectangle {
                id: choice
                required property string modelData
                width: Theme.em * 7
                height: Theme.em * 5.6
                radius: Theme.em * 0.6
                color: "#30000000"
                border.color: root.s.layout === modelData ? Theme.gold : "#40FFFFFF"
                border.width: root.s.layout === modelData ? Math.max(3, Theme.em * 0.16) : 1
                Board {
                  anchors.fill: parent
                  anchors.margins: Theme.em * 0.3
                  // room for the label underneath
                  anchors.bottomMargin: Theme.em * 1.3
                  enabled: false
                  pattern: choice.modelData
                  view: ({ columns: [[0, 1, 2], [1, 2, 0], [2, 0, 1], []], cap: 3, selected: -1, targets: [], solved: false })
                }
                Text {
                  anchors.bottom: parent.bottom
                  anchors.horizontalCenter: parent.horizontalCenter
                  anchors.bottomMargin: Theme.em * 0.15
                  text: choice.modelData === "line" ? qsTr("Line") : qsTr("Circle")
                  color: Theme.ink
                  font.family: Theme.font
                  font.pixelSize: Theme.em * 0.85
                }
                MouseArea { anchors.fill: parent; onClicked: { root.cursor = row.index; root.game.setSetting("layout", choice.modelData) } }
              }
            }
          }

          // interface size
          Row {
            visible: row.r.kind === "size"
            anchors.right: parent.right
            anchors.rightMargin: Theme.em
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.em * 0.6
            RoundButton { size: Theme.em * 2; icon: "back"; onActivated: { root.cursor = row.index; root.change(row.index, -1) } }
            Text {
              anchors.verticalCenter: parent.verticalCenter
              text: Math.round(root.s.scale * 100) + "%"
              color: Theme.ink
              font.family: Theme.font
              font.pixelSize: Theme.em * 1.1
            }
            RoundButton { size: Theme.em * 2; icon: "play"; onActivated: { root.cursor = row.index; root.change(row.index, 1) } }
          }
        }
      }
    }
    }
  }
}
