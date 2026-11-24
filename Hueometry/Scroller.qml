import QtQuick

// Holds a screen's content centred when it fits, and lets it scroll when the
// interface is large on a small screen. Then it keeps a strip at its head
// and foot for "more" cues, so a cue never covers what scrolls; show(item)
// keeps the focused item in view for keyboard players (and may open the
// screen scrolled, so the head has a cue too).
Item {
  id: root
  default property alias content: inner.data
  // taller than the space: the view gives up its head and foot to the cues
  readonly property bool overflows: inner.childrenRect.height > height

  // the very top, title and all (for the first item of a screen)
  function toTop() { f.contentY = 0 }

  function show(item) {
    if (!item) return
    const top = item.mapToItem(inner, 0, 0).y + inner.y
    if (top < f.contentY) f.contentY = Math.max(0, top - Theme.em * 0.5)
    else if (top + item.height > f.contentY + f.height) f.contentY = Math.min(f.contentHeight - f.height, top + item.height - f.height + Theme.em * 0.5)
  }

  Flickable {
    id: f
    anchors.fill: parent
    anchors.topMargin: root.overflows ? Theme.em * 1.9 : 0
    anchors.bottomMargin: root.overflows ? Theme.em * 1.9 : 0
    clip: true
    contentWidth: width
    contentHeight: Math.max(height, inner.childrenRect.height)
    boundsBehavior: Flickable.StopAtBounds

    Item {
      id: inner
      width: f.width
      height: childrenRect.height
      y: Math.max(0, (f.height - childrenRect.height) / 2)
    }
  }

  // the strips are not part of the view, but the wheel over them scrolls it
  Repeater {
    model: root.overflows ? 2 : 0
    WheelScroll {
      required property int index
      view: f
      width: root.width
      height: Theme.em * 1.9
      y: index === 0 ? 0 : root.height - height
    }
  }

  MoreCue {
    up: true
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: Theme.em * 0.25
    visible: root.overflows && !f.atYBeginning
  }
  MoreCue {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: Theme.em * 0.25
    visible: root.overflows && !f.atYEnd
  }
}
