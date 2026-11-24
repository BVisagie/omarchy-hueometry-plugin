import QtQuick
import QtQuick.Shapes

// One broad jungle leaf with a midrib and veins, drawn from its stem at the
// bottom centre. It sways gently about its stem unless motion is reduced.
Item {
  id: leaf
  property color colour: "#2E6B35"
  property color vein: Qt.lighter(colour, 1.35)
  property real length: 200
  property real breadth: 0.42
  property real sway: 2.5
  property real swayPeriod: 5200
  property real phase: 0

  width: length * breadth
  height: length
  transformOrigin: Item.Bottom

  property real swing: 0
  rotation: swing
  SequentialAnimation on swing {
    running: !Theme.reducedMotion && leaf.sway > 0
    loops: Animation.Infinite
    PauseAnimation { duration: leaf.phase }
    NumberAnimation { from: -leaf.sway; to: leaf.sway; duration: leaf.swayPeriod / 2; easing.type: Easing.InOutSine }
    NumberAnimation { from: leaf.sway; to: -leaf.sway; duration: leaf.swayPeriod / 2; easing.type: Easing.InOutSine }
  }

  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    // the blade
    ShapePath {
      strokeColor: Qt.darker(leaf.colour, 1.35)
      strokeWidth: Math.max(1, leaf.length * 0.006)
      fillGradient: LinearGradient {
        x1: 0; y1: 0; x2: leaf.width; y2: leaf.height * 0.3
        GradientStop { position: 0.0; color: Qt.lighter(leaf.colour, 1.25) }
        GradientStop { position: 1.0; color: Qt.darker(leaf.colour, 1.25) }
      }
      startX: leaf.width / 2; startY: leaf.height
      PathCubic {
        x: leaf.width / 2; y: 0
        control1X: -leaf.width * 0.05; control1Y: leaf.height * 0.72
        control2X: leaf.width * 0.12; control2Y: leaf.height * 0.12
      }
      PathCubic {
        x: leaf.width / 2; y: leaf.height
        control1X: leaf.width * 0.88; control1Y: leaf.height * 0.12
        control2X: leaf.width * 1.05; control2Y: leaf.height * 0.72
      }
    }
    // midrib
    ShapePath {
      strokeColor: leaf.vein
      strokeWidth: Math.max(1, leaf.length * 0.01)
      fillColor: "transparent"
      startX: leaf.width / 2; startY: leaf.height
      PathQuad { x: leaf.width / 2; y: leaf.height * 0.06; controlX: leaf.width * 0.47; controlY: leaf.height * 0.5 }
    }
    // veins
    ShapePath {
      strokeColor: Qt.alpha(leaf.vein, 0.55)
      strokeWidth: Math.max(1, leaf.length * 0.005)
      fillColor: "transparent"
      PathMove { x: leaf.width * 0.5; y: leaf.height * 0.75 }
      PathQuad { x: leaf.width * 0.12; y: leaf.height * 0.58; controlX: leaf.width * 0.3; controlY: leaf.height * 0.7 }
      PathMove { x: leaf.width * 0.5; y: leaf.height * 0.75 }
      PathQuad { x: leaf.width * 0.88; y: leaf.height * 0.58; controlX: leaf.width * 0.7; controlY: leaf.height * 0.7 }
      PathMove { x: leaf.width * 0.5; y: leaf.height * 0.55 }
      PathQuad { x: leaf.width * 0.16; y: leaf.height * 0.36; controlX: leaf.width * 0.3; controlY: leaf.height * 0.48 }
      PathMove { x: leaf.width * 0.5; y: leaf.height * 0.55 }
      PathQuad { x: leaf.width * 0.84; y: leaf.height * 0.36; controlX: leaf.width * 0.7; controlY: leaf.height * 0.48 }
      PathMove { x: leaf.width * 0.5; y: leaf.height * 0.35 }
      PathQuad { x: leaf.width * 0.26; y: leaf.height * 0.18; controlX: leaf.width * 0.36; controlY: leaf.height * 0.28 }
      PathMove { x: leaf.width * 0.5; y: leaf.height * 0.35 }
      PathQuad { x: leaf.width * 0.74; y: leaf.height * 0.18; controlX: leaf.width * 0.64; controlY: leaf.height * 0.28 }
    }
  }
}
