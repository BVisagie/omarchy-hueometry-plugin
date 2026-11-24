import QtQuick
import QtQuick.Shapes

// One of the six carved symbols, drawn in a square of side `size`.
Shape {
  id: root
  property string kind: "circle"
  property real size: 20
  property color colour: "#40000000"
  property real strokeWidth: 0
  width: size
  height: size
  preferredRendererType: Shape.CurveRenderer

  function path(kind) {
    // in a 100 x 100 box
    switch (kind) {
    case "star": {
      let d = ""
      for (let i = 0; i < 10; i++) {
        const r = i % 2 === 0 ? 46 : 19
        const a = -Math.PI / 2 + i * Math.PI / 5
        d += (i === 0 ? "M " : "L ") + (50 + r * Math.cos(a)).toFixed(1) + " " + (52 + r * Math.sin(a)).toFixed(1) + " "
      }
      return d + "Z"
    }
    case "triangle": return "M 50 8 L 93 84 L 7 84 Z"
    case "square": return "M 14 14 L 86 14 L 86 86 L 14 86 Z"
    case "diamond": return "M 50 4 L 94 50 L 50 96 L 6 50 Z"
    case "leaf": return "M 50 4 C 88 26 88 74 50 96 C 12 74 12 26 50 4 Z M 50 18 L 50 84 L 47 84 L 47 18 Z"
    default: return "M 50 8 A 42 42 0 1 1 49.9 8 Z M 50 30 A 20 20 0 1 0 50.1 30 Z"
    }
  }

  ShapePath {
    fillColor: root.colour
    fillRule: ShapePath.OddEvenFill
    strokeColor: root.strokeWidth > 0 ? Qt.lighter(root.colour, 1.6) : "transparent"
    strokeWidth: root.strokeWidth
    scale: Qt.size(root.size / 100, root.size / 100)
    PathSvg { path: root.path(root.kind) }
  }
}
