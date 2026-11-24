import QtQuick
import QtQuick.Shapes

// Simple drawn icons, so the game needs no icon font: back, undo, restart,
// hint, help, close, play, settings, lock.
Shape {
  id: root
  property string kind: "back"
  property real size: 24
  property color colour: Theme.ink
  width: size
  height: size
  preferredRendererType: Shape.CurveRenderer

  function path(kind) {
    switch (kind) {
    case "back": return "M 62 18 L 30 50 L 62 82"
    case "undo": return "M 30 34 L 18 46 L 30 58 M 18 46 L 60 46 C 78 46 84 60 84 66 C 84 76 76 84 62 84 L 44 84"
    case "redo": return "M 70 34 L 82 46 L 70 58 M 82 46 L 40 46 C 22 46 16 60 16 66 C 16 76 24 84 38 84 L 56 84"
    case "restart": return "M 76 40 A 30 30 0 1 0 80 62 M 78 22 L 78 42 L 58 42"
    case "hint": return "M 50 12 C 30 12 22 28 22 40 C 22 54 34 60 36 72 L 64 72 C 66 60 78 54 78 40 C 78 28 70 12 50 12 M 40 82 L 60 82 M 44 90 L 56 90"
    case "help": return "M 34 34 C 34 20 46 14 52 14 C 62 14 70 22 70 32 C 70 46 52 46 52 62 M 52 80 L 52 84"
    case "close": return "M 24 24 L 76 76 M 76 24 L 24 76"
    case "play": return "M 32 20 L 78 50 L 32 80 Z"
    case "settings": return "M 50 30 A 20 20 0 1 0 50.1 30 M 50 6 L 50 20 M 50 80 L 50 94 M 6 50 L 20 50 M 80 50 L 94 50 M 19 19 L 29 29 M 71 71 L 81 81 M 81 19 L 71 29 M 29 71 L 19 81"
    case "lock": return "M 28 46 L 72 46 L 72 86 L 28 86 Z M 36 46 L 36 32 C 36 18 64 18 64 32 L 64 46"
    case "check": return "M 18 52 L 40 74 L 82 28"
    default: return ""
    }
  }

  ShapePath {
    strokeColor: root.colour
    // the path is scaled from a 100 box; the stroke is not, so size it here
    strokeWidth: Math.max(1.2, root.size * 0.09)
    capStyle: ShapePath.RoundCap
    joinStyle: ShapePath.RoundJoin
    fillColor: root.kind === "play" ? root.colour : "transparent"
    scale: Qt.size(root.size / 100, root.size / 100)
    PathSvg { path: root.path(root.kind) }
  }
}
