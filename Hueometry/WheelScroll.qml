import QtQuick

// Scrolls `view` with the wheel where the view itself does not take it (a
// card's padding, the strips kept for "more" cues): by the distance a
// touchpad reports, or a step per notch of a mouse wheel.
MouseArea {
  property Flickable view
  acceptedButtons: Qt.NoButton
  onWheel: function(wheel) {
    if (!view) return
    const by = wheel.pixelDelta.y !== 0 ? wheel.pixelDelta.y : wheel.angleDelta.y / 120 * Theme.em * 2
    view.contentY = Math.max(0, Math.min(view.contentHeight - view.height, view.contentY - by))
  }
}
