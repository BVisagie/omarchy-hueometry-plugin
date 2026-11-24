import QtQuick

// A carved, leaf-edged panel for menus and messages.
Rectangle {
  radius: Theme.em * 1.2
  color: Theme.card
  border.color: Theme.cardEdge
  border.width: Math.max(2, Theme.em * 0.12)
  Rectangle {
    anchors.fill: parent
    anchors.margins: Theme.em * 0.35
    radius: parent.radius * 0.8
    color: "transparent"
    border.color: Qt.alpha(Theme.gold, 0.25)
    border.width: 1
  }
}
