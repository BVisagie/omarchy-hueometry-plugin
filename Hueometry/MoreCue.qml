import QtQuick

// "more" with an arrow, on a small dark pill: there is more to scroll to
// below (or, with `up`, above).
Rectangle {
  id: cue
  objectName: "more"
  property bool up: false
  width: row.implicitWidth + Theme.em * 1.1
  height: Theme.em * 1.4
  radius: height / 2
  color: "#D0101C14"
  border.color: Qt.alpha(Theme.gold, 0.5)
  border.width: 1
  Row {
    id: row
    anchors.centerIn: parent
    spacing: Theme.em * 0.3
    Text {
      anchors.verticalCenter: parent.verticalCenter
      text: qsTr("more")
      color: Theme.gold
      font.family: Theme.font
      font.pixelSize: Theme.em * 0.85
    }
    Icon {
      anchors.verticalCenter: parent.verticalCenter
      kind: "play"
      rotation: cue.up ? -90 : 90
      size: Theme.em * 0.8
      colour: Theme.gold
    }
  }
}
