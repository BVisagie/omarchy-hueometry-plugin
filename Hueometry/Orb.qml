import QtQuick
import QtQuick.Shapes
import "js/palette.mjs" as Palette

// A polished jungle orb: a lit sphere with a rim, a soft highlight and a
// glint, and in symbols mode a carved symbol. Centred on (x, y) of its
// parent through `cx` and `cy`.
Item {
  id: orb
  property int colour: 0
  property real size: 40
  property real cx: 0
  property real cy: 0
  property bool glowing: false
  readonly property var tone: Palette.orb(colour)

  width: size
  height: size
  x: cx - size / 2
  y: cy - size / 2

  // the warm glow of a lifted or hinted orb
  Rectangle {
    anchors.centerIn: parent
    width: orb.size * 1.7
    height: width
    radius: width / 2
    visible: orb.glowing
    opacity: 0.55
    gradient: Gradient {
      orientation: Gradient.Vertical
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 0.5; color: Qt.alpha(orb.tone.light, 0.0) }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
  Shape {
    anchors.centerIn: parent
    width: orb.size * 1.7
    height: width
    visible: orb.glowing
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillGradient: RadialGradient {
        centerX: orb.size * 0.85; centerY: orb.size * 0.85; centerRadius: orb.size * 0.85
        focalX: centerX; focalY: centerY
        GradientStop { position: 0.45; color: Qt.alpha(orb.tone.light, 0.75) }
        GradientStop { position: 1.0; color: Qt.alpha(orb.tone.light, 0.0) }
      }
      PathAngleArc { centerX: orb.size * 0.85; centerY: orb.size * 0.85; radiusX: orb.size * 0.85; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
    }
  }

  // contact shadow
  Rectangle {
    x: orb.size * 0.12
    y: orb.size * 0.78
    width: orb.size * 0.76
    height: orb.size * 0.24
    radius: height / 2
    color: "#55000000"
  }

  // the sphere
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: Qt.darker(orb.tone.dark, 1.3)
      strokeWidth: Math.max(1, orb.size * 0.035)
      fillGradient: RadialGradient {
        centerX: orb.size * 0.5; centerY: orb.size * 0.5; centerRadius: orb.size * 0.5
        focalX: orb.size * 0.36; focalY: orb.size * 0.32; focalRadius: 0
        GradientStop { position: 0.0; color: orb.tone.light }
        GradientStop { position: 0.55; color: orb.tone.base }
        GradientStop { position: 1.0; color: orb.tone.dark }
      }
      PathAngleArc { centerX: orb.size / 2; centerY: orb.size / 2; radiusX: orb.size * 0.48; radiusY: radiusX; startAngle: 0; sweepAngle: 360 }
    }
    // light bouncing up from below
    ShapePath {
      strokeColor: "transparent"
      fillGradient: LinearGradient {
        x1: 0; y1: orb.size * 0.55; x2: 0; y2: orb.size
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 1.0; color: Qt.alpha(orb.tone.light, 0.35) }
      }
      PathAngleArc { centerX: orb.size / 2; centerY: orb.size / 2; radiusX: orb.size * 0.44; radiusY: radiusX; startAngle: 20; sweepAngle: 140 }
    }
  }

  // carved symbol, in symbols mode
  Symbol {
    anchors.centerIn: parent
    anchors.verticalCenterOffset: orb.size * 0.03
    size: orb.size * 0.5
    kind: orb.tone.symbol
    visible: Theme.symbols
    colour: Qt.alpha(Qt.darker(orb.tone.dark, 1.6), 0.82)
  }

  // highlight and glint
  Rectangle {
    x: orb.size * 0.2
    y: orb.size * 0.12
    width: orb.size * 0.42
    height: orb.size * 0.26
    radius: height / 2
    rotation: -28
    gradient: Gradient {
      GradientStop { position: 0.0; color: "#C8FFFFFF" }
      GradientStop { position: 1.0; color: "#00FFFFFF" }
    }
  }
  Rectangle {
    x: orb.size * 0.66
    y: orb.size * 0.62
    width: orb.size * 0.09
    height: width
    radius: width / 2
    color: "#70FFFFFF"
  }
}
