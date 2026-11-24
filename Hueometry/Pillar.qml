import QtQuick
import QtQuick.Shapes

// A carved stone pillar, standing on its base at (x, y) of the board and
// growing in the direction of `angle` (degrees clockwise from straight up).
// Orbs are drawn by the board, on top.
Item {
  id: root
  property real px: 0
  property real py: 0
  property real w: 40
  property real h: 200
  property real angle: 0
  property bool focused: false
  property bool target: false
  property bool empty: false
  property bool hinted: false
  property real shake: 0

  width: w
  height: h
  x: px - w / 2
  y: py - h
  transformOrigin: Item.Bottom
  rotation: angle

  transform: Translate { x: root.shake }

  // a hinted pillar's light breathes, so the eye finds it
  property real pulse: 1
  SequentialAnimation on pulse {
    running: root.hinted && !Theme.reducedMotion
    loops: Animation.Infinite
    NumberAnimation { to: 0.4; duration: Theme.ms(700); easing.type: Easing.InOutSine }
    NumberAnimation { to: 1; duration: Theme.ms(700); easing.type: Easing.InOutSine }
  }
  onHintedChanged: if (!hinted) pulse = 1

  // where a legal move may land: a warm light rising from the base
  Rectangle {
    id: glow
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: root.w * 1.9
    height: root.h * 1.08
    radius: width / 2
    opacity: root.target || root.hinted ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.ms(180) } }
    // the hint keeps breathing, even once its orb is lifted
    readonly property real k: root.hinted ? root.pulse : 1
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 0.6; color: Qt.alpha(root.hinted ? "#FFFFFF" : Theme.glow, 0.18 * glow.k) }
      GradientStop { position: 1.0; color: Qt.alpha(root.hinted ? "#FFFFFF" : Theme.glow, 0.42 * glow.k) }
    }
  }

  // plinth
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    width: root.w * 1.32
    height: root.w * 0.34
    radius: height * 0.25
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: Theme.stoneDark }
      GradientStop { position: 0.35; color: Theme.stoneLight }
      GradientStop { position: 1.0; color: Theme.stoneDark }
    }
  }

  // shaft: a hollow channel the orbs sit in
  Rectangle {
    id: shaft
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.bottom: parent.bottom
    anchors.bottomMargin: root.w * 0.3
    width: root.w
    height: root.h - root.w * 0.55
    radius: root.w * 0.22
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: Qt.darker(Theme.stone, 1.5) }
      GradientStop { position: 0.3; color: Theme.stoneLight }
      GradientStop { position: 0.62; color: Theme.stone }
      GradientStop { position: 1.0; color: Qt.darker(Theme.stone, 1.8) }
    }
    // the channel
    Rectangle {
      anchors.horizontalCenter: parent.horizontalCenter
      anchors.top: parent.top
      anchors.bottom: parent.bottom
      anchors.topMargin: root.w * 0.08
      anchors.bottomMargin: root.w * 0.08
      width: parent.width * 0.78
      radius: width * 0.45
      gradient: Gradient {
        orientation: Gradient.Horizontal
        GradientStop { position: 0.0; color: "#2A2C22" }
        GradientStop { position: 0.5; color: "#3E4134" }
        GradientStop { position: 1.0; color: "#24261D" }
      }
    }
    // carved bands
    Repeater {
      model: Math.max(0, Math.floor(shaft.height / (root.w * 2.4)))
      Rectangle {
        required property int index
        x: 0
        width: shaft.width
        y: shaft.height - (index + 1) * root.w * 2.4
        height: root.w * 0.07
        color: "#30000000"
      }
    }
  }

  // capital
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: 0
    width: root.w * 1.22
    height: root.w * 0.3
    radius: height * 0.3
    gradient: Gradient {
      orientation: Gradient.Horizontal
      GradientStop { position: 0.0; color: Theme.stoneDark }
      GradientStop { position: 0.4; color: Theme.stoneLight }
      GradientStop { position: 1.0; color: Theme.stoneDark }
    }
  }

  // which pillar this is: it shapes the moss and the fern, so pillars differ
  // but a pillar always looks the same
  property int seed: 0
  // full of one colour (the engine decides): its flower is open
  property bool complete: false
  // the colour the pillar holds (palette.mjs), for the flower
  property var tone: null
  // on the circle layout the bases crowd the centre: the flower opens on
  // the pillar's outer end instead, where the spokes are far apart
  property bool bloomAtEnd: false
  // the flower keeps the colour it opened in while it closes
  property var bloomTone: null
  onCompleteChanged: if (complete && tone) bloomTone = tone
  onToneChanged: if (complete && tone) bloomTone = tone
  function rnd(k) { const v = Math.sin(seed * 12.9898 + k * 78.233) * 43758.5453; return v - Math.floor(v) }

  // a moss cushion on each shoulder of the plinth, beside the shaft and
  // inside the plinth's edge, so it never covers an orb or a neighbour
  Repeater {
    model: 2
    Item {
      id: clump
      required property int index
      readonly property real side: index === 0 ? -1 : 1
      readonly property real big: 0.85 + root.rnd(index + 1) * 0.3
      width: root.w * 0.4 * big
      height: root.w * 0.2 * big
      x: root.w / 2 + side * root.w * 0.5 - width / 2
      y: root.h - root.w * 0.34 - height * 0.7
      // its shadow on the stone
      Rectangle {
        x: clump.width * 0.04; y: clump.height * 0.5
        width: clump.width * 0.92; height: clump.height * 0.55; radius: height / 2
        color: "#40000000"
      }
      // overlapping mounds, lit from above
      Repeater {
        model: 4
        Rectangle {
          required property int index
          readonly property real r: clump.height * (0.85 + root.rnd(index * 7 + clump.index * 31) * 0.4)
          x: clump.width * (0.14 + index * 0.24) - r / 2
          y: clump.height - r * 0.9 - Math.sin((index + 0.5) / 4 * Math.PI) * clump.height * 0.25
          width: r; height: r * 0.86; radius: height / 2
          gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.lighter(Theme.moss, 1.45) }
            GradientStop { position: 0.45; color: Theme.moss }
            GradientStop { position: 1.0; color: Qt.darker(Theme.moss, 1.6) }
          }
        }
      }
      // bright tips
      Repeater {
        model: 3
        Rectangle {
          required property int index
          x: clump.width * (0.2 + index * 0.27 + root.rnd(index + 60 + clump.index) * 0.06)
          y: clump.height * (0.05 + root.rnd(index + 70 + clump.index) * 0.2)
          width: Math.max(2, root.w * 0.035); height: width; radius: width / 2
          color: Qt.lighter(Theme.moss, 1.9)
        }
      }
    }
  }

  // a fern curling up beside the shaft, on some pillars
  Item {
    id: fern
    visible: root.rnd(9) > 0.4
    readonly property real side: root.rnd(10) > 0.5 ? 1 : -1
    x: root.w / 2 + side * root.w * 0.56
    y: root.h - root.w * 0.4
    Shape {
      preferredRendererType: Shape.CurveRenderer
      ShapePath {
        strokeColor: Qt.darker(Theme.moss, 1.2)
        strokeWidth: Math.max(2, root.w * 0.04)
        fillColor: "transparent"
        capStyle: ShapePath.RoundCap
        startX: 0; startY: 0
        PathQuad { x: fern.side * root.w * 0.16; y: -root.w * 0.95; controlX: fern.side * root.w * 0.02; controlY: -root.w * 0.62 }
      }
    }
    // fronds along the stem (points on that same curve)
    Repeater {
      model: 6
      Rectangle {
        required property int index
        readonly property real t: (index + 1) / 7
        readonly property real sx: fern.side * root.w * (2 * (1 - t) * t * 0.02 + t * t * 0.16)
        readonly property real sy: -root.w * (2 * (1 - t) * t * 0.62 + t * t * 0.95)
        readonly property real len: root.w * 0.2 * (1.05 - t * 0.6)
        x: sx + (index % 2 ? -len : 0)
        y: sy - height / 2
        width: len; height: len * 0.36; radius: height / 2
        transformOrigin: index % 2 ? Item.Right : Item.Left
        rotation: index % 2 ? 25 : -25
        color: index % 2 ? Qt.lighter(Theme.moss, 1.2) : Theme.moss
      }
    }
  }

  // the flower: opens on the plinth when the pillar is done, in its colour
  Item {
    id: flower
    // above the focus outline, which would cross its heart
    z: 1
    // never so small that its symbol cannot be read (thin circle spokes)
    width: Math.max(root.w * 0.5, Theme.em * 1.5)
    height: width
    x: root.w / 2 - width / 2
    // past the capital on the circle, clear of the outermost orb
    // on the line, low enough that the top petal (0.52 of the height above
    // the centre, up to 1.1x while it pops open) stays below the plinth's
    // top edge, clear of the bottom orb
    y: root.bloomAtEnd ? root.w * 0.1 - height : Math.max(root.h - root.w * 0.17 - height / 2, root.h - root.w * 0.34 + height * 0.08)
    visible: scale > 0 && !!root.bloomTone
    scale: root.complete && root.tone ? 1 : 0
    Behavior on scale { NumberAnimation { duration: Theme.ms(420); easing.type: Easing.OutBack } }
    readonly property var tone: root.bloomTone
    readonly property color petal: tone ? tone.base : "white"
    // a pale halo, so a green flower still shows against the moss
    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 1.5; height: width; radius: width / 2
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.alpha(Theme.glow, 0.0) }
        GradientStop { position: 0.5; color: Qt.alpha(Theme.glow, 0.35) }
        GradientStop { position: 1.0; color: Qt.alpha(Theme.glow, 0.0) }
      }
    }
    Repeater {
      model: 5
      Rectangle {
        required property int index
        x: flower.width / 2 - width / 2
        y: flower.height / 2 - height
        width: flower.width * 0.38; height: flower.height * 0.52; radius: width / 2
        transformOrigin: Item.Bottom
        rotation: index * 72
        gradient: Gradient {
          GradientStop { position: 0.0; color: flower.tone ? flower.tone.light : "white" }
          GradientStop { position: 1.0; color: flower.petal }
        }
        border.color: Theme.glow
        border.width: Math.max(1, root.w * 0.018)
      }
    }
    // its heart, carrying the colour's symbol in symbols mode
    Rectangle {
      anchors.centerIn: parent
      width: flower.width * 0.42; height: width; radius: width / 2
      color: Theme.gold
      border.color: Qt.darker(Theme.gold, 1.6)
      border.width: Math.max(1, root.w * 0.015)
      Symbol {
        anchors.centerIn: parent
        size: parent.width * 0.75
        // upright on every spoke of the circle layout
        rotation: -root.angle
        kind: flower.tone ? flower.tone.symbol : "circle"
        visible: Theme.symbols && !!flower.tone
        // dark on the gold heart for every colour (pale symbols vanish)
        colour: Theme.inkDark
      }
    }
  }

  // the empty socket glows faintly, so the spare pillar invites a bead
  Rectangle {
    anchors.horizontalCenter: parent.horizontalCenter
    y: root.h - root.w * 1.05
    width: root.w * 0.62
    height: width
    radius: width / 2
    visible: root.empty
    opacity: 0.55
    gradient: Gradient {
      GradientStop { position: 0.0; color: Qt.alpha(Theme.glow, 0.0) }
      GradientStop { position: 1.0; color: Qt.alpha(Theme.glow, 0.6) }
    }
  }

  // keyboard focus: a clear golden outline around the whole pillar
  Rectangle {
    anchors.fill: parent
    anchors.margins: -root.w * 0.22
    radius: root.w * 0.3
    color: "transparent"
    border.color: Theme.gold
    border.width: Math.max(3, root.w * 0.07)
    visible: root.focused
  }
}
