import QtQuick

// A wide button with words, for menus.
Item {
  id: root
  property string text: ""
  property string icon: ""
  property bool focused: false
  property bool enabled: true
  property bool primary: false
  property real wide: Theme.em * 15
  signal activated()

  width: wide
  height: Theme.em * 3
  opacity: enabled ? 1 : 0.45

  Rectangle {
    anchors.fill: parent
    radius: height * 0.32
    scale: area.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(80) } }
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.primary ? "#F4CC63" : "#6F7D55" }
      GradientStop { position: 1.0; color: root.primary ? "#B8862A" : "#3A4630" }
    }
    border.color: root.focused ? Theme.glow : "#33000000"
    border.width: root.focused ? Math.max(3, Theme.em * 0.18) : 2

    Row {
      anchors.centerIn: parent
      spacing: Theme.em * 0.6
      Icon {
        visible: root.icon !== ""
        kind: root.icon
        size: Theme.em * 1.3
        anchors.verticalCenter: parent.verticalCenter
        colour: root.primary ? Theme.inkDark : Theme.ink
      }
      Text {
        text: root.text
        anchors.verticalCenter: parent.verticalCenter
        color: root.primary ? Theme.inkDark : Theme.ink
        font.family: Theme.font
        font.pixelSize: Theme.em * 1.2
        font.bold: true
      }
    }
  }

  MouseArea {
    id: area
    anchors.fill: parent
    enabled: root.enabled
    onClicked: root.activated()
  }
}
