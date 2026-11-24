import QtQuick

// A large, round, carved-stone button with an icon: easy to hit, with a
// clear focus ring and a pressed state. `hold` makes it act only after being
// held down, for actions that should not happen by accident.
Item {
  id: root
  property string icon: "back"
  property string label: ""
  property real size: Theme.em * 3.2
  property bool enabled: true
  property bool focused: false
  property bool lit: false
  property int hold: 0
  signal activated()

  width: size
  height: size + (label !== "" ? Theme.em * 1.4 : 0)
  opacity: enabled ? 1 : 0.4

  property real holdProgress: 0

  Rectangle {
    id: face
    width: root.size
    height: root.size
    radius: width / 2
    scale: area.pressed ? 0.94 : 1
    Behavior on scale { NumberAnimation { duration: Theme.ms(80) } }
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.lit ? Qt.lighter(Theme.gold, 1.1) : "#7E8A62" }
      GradientStop { position: 1.0; color: root.lit ? Qt.darker(Theme.gold, 1.4) : "#3E4A30" }
    }
    border.color: root.focused ? Theme.gold : "#22000000"
    border.width: root.focused ? Math.max(3, root.size * 0.07) : 2

    // the ring that fills while a hold-to-confirm button is held
    Rectangle {
      anchors.fill: parent
      anchors.margins: -root.size * 0.06
      radius: width / 2
      color: "transparent"
      border.color: Theme.glow
      border.width: root.size * 0.06
      visible: root.hold > 0 && root.holdProgress > 0
      opacity: root.holdProgress
    }

    Icon {
      anchors.centerIn: parent
      kind: root.icon
      size: root.size * 0.5
      colour: root.lit ? Theme.inkDark : Theme.ink
    }
  }

  Text {
    anchors.top: face.bottom
    anchors.topMargin: Theme.em * 0.2
    anchors.horizontalCenter: face.horizontalCenter
    text: root.label
    color: Theme.ink
    font.family: Theme.font
    font.pixelSize: Theme.em * 0.92
    style: Text.Raised
    styleColor: "#80000000"
  }

  NumberAnimation {
    id: holding
    target: root
    property: "holdProgress"
    from: 0
    to: 1
    duration: root.hold
    onFinished: { root.holdProgress = 0; root.activated() }
  }

  MouseArea {
    id: area
    anchors.fill: face
    enabled: root.enabled
    onPressed: if (root.hold > 0) holding.restart()
    onReleased: if (root.hold > 0) { holding.stop(); root.holdProgress = 0 }
    onCanceled: { holding.stop(); root.holdProgress = 0 }
    onClicked: if (root.hold === 0) root.activated()
  }
}
