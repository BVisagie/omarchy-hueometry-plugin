import QtQuick
import Quickshell
import qs.Ui

// An orb in the bar that opens Hueometry. (The game has no app-launcher entry
// when installed as a plugin; a key can also be bound to
// `omarchy-shell shell summon io.github.bvisagie.hueometry '{}'`.)
BarWidget {
  id: root
  moduleName: "io.github.bvisagie.hueometry"
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "◉"
    tooltipText: qsTr("Play Hueometry")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton)
        Quickshell.execDetached(["omarchy-shell", "shell", "summon", "io.github.bvisagie.hueometry", "{}"])
    }
  }
}
