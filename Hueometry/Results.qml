import QtQuick

// The celebration card after a puzzle is solved.
Item {
  id: root
  property var result: null
  property int moves: 0
  property int par: 0
  property bool hasNext: false
  // where "back" goes: the map, or the size picker for free play
  property string backLabel: qsTr("Map")
  // 0: map, 1: play again, 2: next
  property int cursor: hasNext ? 2 : 1
  // a new result (or a change to what comes next) starts on the main action
  onResultChanged: { cursor = hasNext ? 2 : 1; Qt.callLater(reveal) }
  onHasNextChanged: cursor = hasNext ? 2 : 1
  signal replay()
  signal next()
  signal leave()

  readonly property var cheers: [qsTr("Wonderful!"), qsTr("You did it!"), qsTr("Brilliant sorting!"), qsTr("The temple glows!"), qsTr("Splendid!")]

  function handleKey(event) {
    switch (event.key) {
    // up and down too, for when the buttons are stacked
    case Qt.Key_Left: case Qt.Key_Up:
      cursor = Math.max(0, cursor - 1); return true
    case Qt.Key_Right: case Qt.Key_Down: case Qt.Key_Tab:
      cursor = Math.min(hasNext ? 2 : 1, cursor + 1); return true
    case Qt.Key_Space: case Qt.Key_Return: case Qt.Key_Enter:
      if (cursor === 0) leave(); else if (cursor === 2 && hasNext) next(); else replay()
      return true
    case Qt.Key_Escape: leave(); return true
    }
    return false
  }

  Rectangle { anchors.fill: parent; color: "#8C000000" }
  MouseArea { anchors.fill: parent }

  Card {
    id: card
    anchors.centerIn: parent
    // wide enough for its three buttons in one row (8 + 10 + 8 em and two
    // gaps, inside 1.5 em margins); narrow windows stack them
    width: Math.min(parent.width - Theme.em * 4, Theme.em * 32)
    // as tall as its words, or the window, scrolling inside when taller
    height: Math.min(column.implicitHeight + Theme.em * 3, root.height - Theme.em * 2)
    scale: root.visible ? 1 : 0.85
    Behavior on scale { NumberAnimation { duration: Theme.ms(260); easing.type: Easing.OutBack } }

    Flickable {
      id: cardScroll
      anchors.fill: parent
      anchors.margins: Theme.em * 1.5
      contentWidth: width
      contentHeight: column.implicitHeight
      clip: true
      interactive: contentHeight > height
      boundsBehavior: Flickable.StopAtBounds

    Column {
      id: column
      width: cardScroll.width
      spacing: Theme.em * 0.8

      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.result ? root.cheers[(root.moves * 7) % root.cheers.length] : ""
        color: Theme.gold
        font.family: Theme.font
        font.pixelSize: Theme.em * 2.4
        font.bold: true
        style: Text.Raised
        styleColor: "#A0000000"
      }
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        text: root.moves === 1 ? qsTr("Solved in 1 move.") : qsTr("Solved in %1 moves.").arg(root.moves)
        color: Theme.ink
        font.family: Theme.font
        font.pixelSize: Theme.em * 1.4
      }
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        visible: text !== ""
        color: Theme.inkSoft
        font.family: Theme.font
        font.pixelSize: Theme.em * 1.1
        text: {
          if (!root.result) return ""
          const r = root.result
          // a hinted solve never replaces a best made without hints
          if (r.assisted && r.best && !r.best.assisted)
            return qsTr("Your best without hints is %1.").arg(r.best.best)
          if (r.record === "first") return root.par > 0 ? qsTr("Par for this puzzle is %1.").arg(root.par) : ""
          if (r.record === "better" && r.previous.assisted && r.previous.best <= r.best.best)
            return qsTr("Your first solve without hints! Before, you used a hint and took %1.").arg(r.previous.best)
          if (r.record === "better") return qsTr("New personal best! Your last best was %1.").arg(r.previous.best)
          if (r.record === "same") return qsTr("You matched your best of %1.").arg(r.previous.best)
          return qsTr("Your best is %1. Want to try for fewer moves?").arg(r.previous.best)
        }
      }
      Text {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        visible: !!root.result && root.result.assisted
        text: qsTr("You used a hint this time.")
        color: Theme.inkSoft
        font.family: Theme.font
        font.pixelSize: Theme.em * 1.0
        font.italic: true
      }
      Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: !!root.result && root.result.record === "better"
        width: badge.implicitWidth + Theme.em * 2
        height: Theme.em * 2.2
        radius: height / 2
        color: Theme.gold
        Text {
          id: badge
          anchors.centerIn: parent
          text: qsTr("New record")
          color: Theme.inkDark
          font.family: Theme.font
          font.pixelSize: Theme.em
          font.bold: true
        }
      }
      // in a row, or stacked when the card is too narrow for one
      Grid {
        id: actions
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.em
        horizontalItemAlignment: Grid.AlignHCenter
        readonly property real rowWidth: backButton.width + againButton.width + spacing + (nextButton.visible ? nextButton.width + spacing : 0)
        columns: rowWidth <= column.width ? 3 : 1
        TextButton { id: backButton; text: root.backLabel; icon: "back"; wide: Theme.em * 8; focused: root.cursor === 0; onActivated: root.leave() }
        TextButton { id: againButton; text: qsTr("Play again"); icon: "restart"; wide: Theme.em * 10; focused: root.cursor === 1; onActivated: root.replay() }
        TextButton { id: nextButton; text: qsTr("Next"); icon: "play"; wide: Theme.em * 8; primary: true; visible: root.hasNext; focused: root.cursor === 2; onActivated: root.next() }
      }
    }
    }
  }

  // keep the chosen action in view when the card scrolls
  function reveal() {
    const b = [backButton, againButton, nextButton][cursor]
    if (!b || cardScroll.contentHeight <= cardScroll.height) return
    const y = b.mapToItem(column, 0, 0).y
    if (y < cardScroll.contentY) cardScroll.contentY = y
    else if (y + b.height > cardScroll.contentY + cardScroll.height) cardScroll.contentY = y + b.height - cardScroll.height
  }
  onCursorChanged: reveal()
  onHeightChanged: Qt.callLater(reveal)
}
