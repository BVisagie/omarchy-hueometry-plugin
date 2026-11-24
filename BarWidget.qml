import QtQuick
import Quickshell
import qs.Ui

// An orb in the bar that opens (or closes) Hueometry. (The game has no
// app-launcher entry when installed as a plugin; a key can also be bound to
// `omarchy-shell shell summon io.github.bvisagie.hueometry '{}'`.)
BarWidget {
  id: root
  moduleName: "io.github.bvisagie.hueometry"
  // the shell types `bar` as a plain QObject; its plugin API (`shell`) is
  // reached through an untyped reference
  readonly property var barApi: root.bar
  implicitWidth: button.implicitWidth
  implicitHeight: button.implicitHeight

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: "◉"
    tooltipText: qsTr("Play Hueometry")
    onPressed: function(buttonCode) {
      if (buttonCode === Qt.LeftButton) root.open()
    }
  }

  // through the shell's plugin API (bar.shell, limited to this plugin's own
  // id), as Omarchy's own widgets do; an older shell without it gets the
  // command line instead
  function open() {
    const api = root.barApi ? root.barApi.shell : null
    // the API's own answer stands (false means the shell declined)
    if (api && typeof api.toggle === "function") { api.toggle(root.moduleName, "{}"); return "api" }
    Quickshell.execDetached(["omarchy-shell", "shell", "summon", root.moduleName, "{}"])
    return "command"
  }
}
