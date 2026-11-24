import QtQuick

// Holds a screen's content centred when it fits, and lets it scroll when the
// interface is large on a small screen; show(item) keeps the focused item in
// view for keyboard players.
Flickable {
  id: f
  default property alias content: inner.data
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

  function show(item) {
    if (!item) return
    const top = item.mapToItem(inner, 0, 0).y + inner.y
    if (top < contentY) contentY = Math.max(0, top - Theme.em * 0.5)
    else if (top + item.height > contentY + height) contentY = Math.min(contentHeight - height, top + item.height - height + Theme.em * 0.5)
  }
}
