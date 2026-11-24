import QtQuick

// The main menu.
Item {
  id: menu
  required property var game
  property int cursor: 0

  readonly property var items: [
    { text: game.progress.current ? qsTr("Continue") : qsTr("Adventure"), icon: "play", act: function() { game.continueOrMap() }, primary: true },
    { text: qsTr("Free play"), icon: "play", act: function() { game.show("free") } },
    { text: qsTr("Adventure map"), icon: "settings", act: function() { game.show("map") }, hidden: !game.progress.current },
    { text: qsTr("Settings"), icon: "settings", act: function() { game.show("settings") } },
    { text: game.host && game.host.kind === "plugin" ? qsTr("Close") : qsTr("Quit"), icon: "close", act: function() { game.quit() } },
  ].filter(i => !i.hidden)

  function handleKey(event) {
    switch (event.key) {
    case Qt.Key_Up: case Qt.Key_Left: cursor = (cursor + items.length - 1) % items.length; return true
    case Qt.Key_Down: case Qt.Key_Right: case Qt.Key_Tab: cursor = (cursor + 1) % items.length; return true
    case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter: items[cursor].act(); return true
    case Qt.Key_Escape: game.quit(); return true
    }
    return false
  }

  // the first button brings the title back into view too
  onCursorChanged: cursor === 0 ? scroller.toTop() : scroller.show(buttons.itemAt(cursor))

  // sized so the title and all five buttons fit 34em, the height of any
  // wide screen at 100% (docs/decisions.md)
  Scroller {
    id: scroller
    anchors.fill: parent
    anchors.margins: Theme.em * 0.5
  Column {
    anchors.horizontalCenter: parent.horizontalCenter
    spacing: Theme.em
    Title {
      anchors.horizontalCenter: parent.horizontalCenter
      size: Math.min(menu.width / 7, Theme.em * 5.5)
    }
    Text {
      anchors.horizontalCenter: parent.horizontalCenter
      text: qsTr("The Lost Jungle Temple")
      color: Theme.inkSoft
      font.family: Theme.font
      font.pixelSize: Theme.em * 1.5
      font.italic: true
      style: Text.Raised
      styleColor: "#A0000000"
    }
    Item { width: 1; height: Theme.em * 0.5 }
    Repeater {
      id: buttons
      model: menu.items.length
      TextButton {
        required property int index
        anchors.horizontalCenter: parent.horizontalCenter
        text: menu.items[index].text
        icon: menu.items[index].icon
        primary: !!menu.items[index].primary
        focused: menu.cursor === index
        onActivated: menu.items[index].act()
      }
    }
  }
  }

  // which version (and build) is running, quietly in the corner, outside
  // the scrolling column so it never covers a button; nothing when the host
  // does not say (or has not arrived yet)
  Text {
    objectName: "version"
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    anchors.margins: Theme.em * 0.6
    text: menu.game.host && menu.game.host.version ? qsTr("v%1").arg(menu.game.host.version) : ""
    visible: text !== ""
    color: Theme.inkSoft
    opacity: 0.85
    font.family: Theme.font
    font.pixelSize: Theme.em * 0.85
    style: Text.Raised
    styleColor: "#A0000000"
  }
}
