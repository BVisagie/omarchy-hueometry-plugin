import QtQuick
import QtQuick.Shapes
import QtQuick.Particles

// The Lost Jungle Temple, drawn: canopy light, far trees, each area's own
// feature (a river, ruins, a waterfall, the temple, the heart tree), swaying
// leaves and vines, mist and fireflies. The middle stays calm and dark enough
// for the board. `restored` brings colour and light back when a puzzle is
// solved. Placement is seeded per area, so each area always looks the same.
Item {
  id: root
  property int area: 0
  property bool restored: false

  // tutorial, clearing, river, ruins, waterfall, temple, heart
  readonly property var looks: [
    { top: "#6E9E52", mid: "#2F6036", ground: "#13301B", far: "#24502F", leaf: "#3E7A3A", near: "#14341C", light: "#FFF1B8", feature: "none" },
    { top: "#7DAA4E", mid: "#2E6A33", ground: "#12321A", far: "#23562C", leaf: "#468A3C", near: "#123A1B", light: "#FFF0A8", feature: "none" },
    { top: "#5FA38C", mid: "#25605A", ground: "#0F2E2C", far: "#1E4E45", leaf: "#3C8060", near: "#0F3326", light: "#E8FFF4", feature: "river" },
    { top: "#7A9A6A", mid: "#3D5A40", ground: "#1A2A1C", far: "#38503A", leaf: "#5A7E44", near: "#1A3020", light: "#FFF5D0", feature: "ruins" },
    { top: "#5C9CA0", mid: "#24585A", ground: "#0E2A2A", far: "#1D4A48", leaf: "#3A7E62", near: "#0E3028", light: "#E6FBFF", feature: "waterfall" },
    { top: "#B88A4A", mid: "#5A4A2A", ground: "#22180E", far: "#4A3A22", leaf: "#6A7A3A", near: "#262010", light: "#FFD890", feature: "temple" },
    { top: "#6C5CA0", mid: "#30305A", ground: "#120F24", far: "#2A2A48", leaf: "#3E7A6A", near: "#141830", light: "#E8D8FF", feature: "heart" },
  ]
  readonly property var look: looks[Math.max(0, Math.min(looks.length - 1, area))]

  // a small seeded random sequence (mulberry32)
  function rand(seed) {
    let a = seed >>> 0
    return function() {
      a = (a + 0x6D2B79F5) >>> 0
      let t = a
      t = Math.imul(t ^ (t >>> 15), t | 1)
      t ^= t + Math.imul(t ^ (t >>> 7), t | 61)
      return ((t ^ (t >>> 14)) >>> 0) / 4294967296
    }
  }
  function spread(seed, n) {
    const r = rand(seed)
    const out = []
    for (let i = 0; i < n; i++) out.push([r(), r(), r(), r()])
    return out
  }
  readonly property var trees: spread(101 + area * 17, 9)
  readonly property var blobs: spread(203 + area * 13, 16)
  readonly property var shafts: spread(307 + area * 11, 5)
  readonly property var vines: spread(409 + area * 7, 6)

  readonly property real w: width
  readonly property real h: height

  // sky through the canopy
  Rectangle {
    anchors.fill: parent
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.look.top }
      GradientStop { position: 0.45; color: root.look.mid }
      GradientStop { position: 1.0; color: root.look.ground }
    }
  }

  // light shafts
  Repeater {
    model: root.shafts.length
    Rectangle {
      id: shaft
      required property int index
      readonly property var s: root.shafts[index]
      x: root.w * (0.08 + s[0] * 0.84)
      y: -root.h * 0.15
      width: root.w * (0.03 + s[1] * 0.05)
      height: root.h * 1.25
      rotation: 14 + s[2] * 10
      transformOrigin: Item.Top
      opacity: 0.55
      gradient: Gradient {
        GradientStop { position: 0.0; color: Qt.alpha(root.look.light, 0.32) }
        GradientStop { position: 0.7; color: Qt.alpha(root.look.light, 0.05) }
        GradientStop { position: 1.0; color: "transparent" }
      }
      SequentialAnimation on opacity {
        running: !Theme.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { to: 0.25; duration: 4000 + shaft.s[3] * 3000; easing.type: Easing.InOutSine }
        NumberAnimation { to: 0.6; duration: 4000 + shaft.s[3] * 3000; easing.type: Easing.InOutSine }
      }
    }
  }

  // far trees: trunks and canopy blobs, in the haze
  Item {
    anchors.fill: parent
    layer.enabled: true
    opacity: 0.85
    Repeater {
      model: root.trees.length
      Rectangle {
        required property int index
        readonly property var t: root.trees[index]
        x: root.w * t[0]
        y: root.h * (0.1 + t[1] * 0.15)
        width: root.w * (0.012 + t[2] * 0.02)
        height: root.h
        color: Qt.darker(root.look.far, 1.1 + t[3] * 0.3)
      }
    }
    Repeater {
      model: root.blobs.length
      Rectangle {
        required property int index
        readonly property var b: root.blobs[index]
        x: root.w * (b[0] * 1.1 - 0.05) - width / 2
        y: root.h * (-0.12 + b[1] * 0.22)
        width: root.w * (0.16 + b[2] * 0.16)
        height: width * (0.55 + b[3] * 0.25)
        radius: height / 2
        color: Qt.darker(root.look.far, 1.0 + b[3] * 0.4)
      }
    }
  }

  // each area's feature
  Loader {
    anchors.fill: parent
    sourceComponent: ({ river: river, ruins: ruins, waterfall: waterfall, temple: temple, heart: heart })[root.look.feature] || null
  }

  Component {
    id: river
    Item {
      // a river crossing the forest floor, with shimmer
      Rectangle {
        x: 0; y: root.h * 0.78
        width: root.w; height: root.h * 0.1
        gradient: Gradient {
          GradientStop { position: 0.0; color: "#4FA6B0" }
          GradientStop { position: 1.0; color: "#1F5A66" }
        }
        opacity: 0.8
      }
      Repeater {
        model: 14
        Rectangle {
          required property int index
          x: (index * 0.13 % 1) * root.w
          y: root.h * (0.79 + (index % 5) * 0.017)
          width: root.w * 0.05; height: Math.max(2, root.h * 0.003); radius: height / 2
          color: "#C8F4FF"; opacity: 0.4
          NumberAnimation on x {
            running: !Theme.reducedMotion
            loops: Animation.Infinite
            from: -root.w * 0.05; to: root.w
            duration: 9000 + index * 700
          }
        }
      }
    }
  }

  Component {
    id: ruins
    Shape {
      // broken walls and columns on the horizon
      preferredRendererType: Shape.CurveRenderer
      opacity: 0.75
      ShapePath {
        strokeColor: "transparent"
        fillColor: "#5A6450"
        startX: 0; startY: root.h * 0.82
        PathLine { x: root.w * 0.05; y: root.h * 0.82 }
        PathLine { x: root.w * 0.05; y: root.h * 0.6 }
        PathLine { x: root.w * 0.09; y: root.h * 0.6 }
        PathLine { x: root.w * 0.09; y: root.h * 0.66 }
        PathLine { x: root.w * 0.16; y: root.h * 0.66 }
        PathLine { x: root.w * 0.16; y: root.h * 0.55 }
        PathLine { x: root.w * 0.19; y: root.h * 0.55 }
        PathLine { x: root.w * 0.19; y: root.h * 0.72 }
        PathLine { x: root.w * 0.8; y: root.h * 0.72 }
        PathLine { x: root.w * 0.8; y: root.h * 0.5 }
        PathLine { x: root.w * 0.84; y: root.h * 0.5 }
        PathLine { x: root.w * 0.84; y: root.h * 0.63 }
        PathLine { x: root.w * 0.92; y: root.h * 0.63 }
        PathLine { x: root.w * 0.92; y: root.h * 0.58 }
        PathLine { x: root.w; y: root.h * 0.58 }
        PathLine { x: root.w; y: root.h }
        PathLine { x: 0; y: root.h }
      }
    }
  }

  Component {
    id: waterfall
    Item {
      // a waterfall on the left, its stripes falling, its spray rising
      Rectangle {
        x: root.w * 0.06; y: 0
        width: root.w * 0.1; height: root.h * 0.85
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "#406E8A9A" }
          GradientStop { position: 0.5; color: "#90D8F0F8" }
          GradientStop { position: 1.0; color: "#406E8A9A" }
        }
      }
      Repeater {
        model: 10
        Rectangle {
          required property int index
          x: root.w * (0.065 + (index % 5) * 0.018)
          width: Math.max(2, root.w * 0.004); height: root.h * 0.12; radius: width / 2
          color: "#E8FBFF"; opacity: 0.45
          NumberAnimation on y {
            running: !Theme.reducedMotion
            loops: Animation.Infinite
            from: -root.h * 0.12; to: root.h * 0.85
            duration: 1400 + index * 130
          }
        }
      }
      Rectangle {
        x: root.w * 0.02; y: root.h * 0.78
        width: root.w * 0.2; height: root.h * 0.12; radius: height / 2
        color: "#60E8FBFF"
      }
    }
  }

  Component {
    id: temple
    Item {
      // a stepped temple, lit by torches
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: 0.8
        ShapePath {
          strokeColor: "transparent"
          fillColor: "#4A3A24"
          startX: root.w * 0.2; startY: root.h * 0.8
          PathLine { x: root.w * 0.24; y: root.h * 0.7 }
          PathLine { x: root.w * 0.3; y: root.h * 0.7 }
          PathLine { x: root.w * 0.34; y: root.h * 0.58 }
          PathLine { x: root.w * 0.4; y: root.h * 0.58 }
          PathLine { x: root.w * 0.44; y: root.h * 0.46 }
          PathLine { x: root.w * 0.56; y: root.h * 0.46 }
          PathLine { x: root.w * 0.6; y: root.h * 0.58 }
          PathLine { x: root.w * 0.66; y: root.h * 0.58 }
          PathLine { x: root.w * 0.7; y: root.h * 0.7 }
          PathLine { x: root.w * 0.76; y: root.h * 0.7 }
          PathLine { x: root.w * 0.8; y: root.h * 0.8 }
        }
      }
      Repeater {
        model: [[0.27, 0.68], [0.73, 0.68], [0.42, 0.56], [0.58, 0.56]]
        Rectangle {
          required property var modelData
          x: root.w * modelData[0] - width / 2
          y: root.h * modelData[1] - height
          width: root.w * 0.012; height: width * 1.6; radius: width / 2
          color: "#FFC45A"
          SequentialAnimation on opacity {
            running: !Theme.reducedMotion
            loops: Animation.Infinite
            NumberAnimation { to: 0.6; duration: 300 }
            NumberAnimation { to: 1.0; duration: 420 }
          }
        }
      }
    }
  }

  Component {
    id: heart
    Item {
      // the heart tree and its glowing flowers
      Rectangle {
        x: root.w * 0.47; y: root.h * 0.3
        width: root.w * 0.06; height: root.h * 0.7
        color: "#2A2440"
      }
      Rectangle {
        x: root.w * 0.3; y: root.h * 0.08
        width: root.w * 0.4; height: root.h * 0.32; radius: height / 2
        color: "#3A3070"; opacity: 0.8
      }
      Repeater {
        model: 18
        Rectangle {
          id: flower
          required property int index
          readonly property var p: root.blobs[index % root.blobs.length]
          x: root.w * (0.1 + p[0] * 0.8)
          y: root.h * (0.15 + p[1] * 0.7)
          width: root.w * 0.008; height: width; radius: width / 2
          color: ["#F7C8E2", "#C4EBFF", "#FFF9B8"][index % 3]
          SequentialAnimation on opacity {
            running: !Theme.reducedMotion
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 1800 + flower.index * 90 }
            NumberAnimation { to: 1.0; duration: 1800 + flower.index * 90 }
          }
        }
      }
    }
  }

  // the forest floor
  Rectangle {
    anchors.left: parent.left
    anchors.right: parent.right
    anchors.bottom: parent.bottom
    height: root.h * 0.16
    gradient: Gradient {
      GradientStop { position: 0.0; color: "transparent" }
      GradientStop { position: 1.0; color: Qt.darker(root.look.ground, 1.3) }
    }
  }

  // hanging vines
  Repeater {
    model: root.vines.length
    Item {
      id: vine
      required property int index
      readonly property var v: root.vines[index]
      x: root.w * (index < 3 ? 0.02 + v[0] * 0.22 : 0.76 + v[0] * 0.22)
      y: -root.h * 0.02
      width: root.w * 0.02
      height: root.h * (0.18 + v[1] * 0.3)
      transformOrigin: Item.Top
      property real swing: 0
      rotation: swing
      SequentialAnimation on swing {
        running: !Theme.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { from: -2; to: 2; duration: 3800 + vine.v[2] * 2400; easing.type: Easing.InOutSine }
        NumberAnimation { from: 2; to: -2; duration: 3800 + vine.v[2] * 2400; easing.type: Easing.InOutSine }
      }
      Rectangle {
        x: parent.width / 2 - width / 2
        width: Math.max(2, root.w * 0.0025)
        height: parent.height
        radius: width / 2
        color: Qt.darker(root.look.leaf, 1.4)
      }
      Repeater {
        model: 5
        Leaf {
          required property int index
          x: vine.width / 2 - width / 2 + (index % 2 ? width * 0.35 : -width * 0.35)
          y: vine.height * (0.2 + index * 0.17) - height
          length: root.h * 0.045
          rotation: index % 2 ? 40 : -40
          sway: 0
          colour: root.look.leaf
        }
      }
    }
  }

  // leaves along the sides: broad mid-layer leaves fanning in
  Repeater {
    model: 12
    Leaf {
      required property int index
      readonly property bool onLeft: index < 6
      readonly property int k: index % 6
      x: onLeft ? -width * 0.3 + k * root.w * 0.012 : root.w - width * 0.7 - k * root.w * 0.012
      y: root.h * (0.62 + (k % 3) * 0.08) - height
      length: root.h * (0.32 + (k % 3) * 0.06)
      rotation: (onLeft ? 1 : -1) * (25 + k * 9)
      phase: k * 420
      colour: Qt.darker(root.look.leaf, 1.0 + (k % 3) * 0.12)
    }
  }

  // drifting mist: soft bands, wider than the scene so no end shows
  Repeater {
    model: 2
    Rectangle {
      id: mist
      required property int index
      width: root.w * 1.6
      height: root.h * 0.24
      y: root.h * (0.52 + index * 0.2)
      opacity: 0.14
      gradient: Gradient {
        GradientStop { position: 0.0; color: "transparent" }
        GradientStop { position: 0.5; color: root.look.light }
        GradientStop { position: 1.0; color: "transparent" }
      }
      SequentialAnimation on x {
        running: !Theme.reducedMotion
        loops: Animation.Infinite
        NumberAnimation { from: -root.w * 0.35; to: -root.w * 0.15; duration: 23000 + mist.index * 6000; easing.type: Easing.InOutSine }
        NumberAnimation { from: -root.w * 0.15; to: -root.w * 0.35; duration: 23000 + mist.index * 6000; easing.type: Easing.InOutSine }
      }
    }
  }

  // fireflies
  ParticleSystem {
    id: motes
    anchors.fill: parent
    running: !Theme.reducedMotion
  }
  ItemParticle {
    system: motes
    delegate: Rectangle {
      width: root.h * 0.006
      height: width
      radius: width / 2
      color: root.look.light
    }
  }
  Emitter {
    system: motes
    x: root.w * 0.05
    y: root.h * 0.25
    width: root.w * 0.9
    height: root.h * 0.65
    emitRate: root.restored ? 12 : 4
    lifeSpan: 6000
    lifeSpanVariation: 2000
    velocity: AngleDirection { angle: 270; angleVariation: 60; magnitude: root.h * 0.012; magnitudeVariation: root.h * 0.01 }
  }
  Wander { system: motes; xVariance: root.w * 0.02; pace: root.w * 0.02 }

  // near leaves framing the bottom corners
  Repeater {
    model: 6
    Leaf {
      required property int index
      readonly property bool onLeft: index < 3
      readonly property int k: index % 3
      x: onLeft ? -width * 0.25 + k * root.w * 0.03 : root.w - width * 0.75 - k * root.w * 0.03
      y: root.h * 1.05 - height
      length: root.h * (0.36 + k * 0.08)
      rotation: (onLeft ? 1 : -1) * (12 + k * 22)
      phase: 900 + k * 600
      sway: 1.5
      colour: root.look.near
    }
  }

  // shade at the edges keeps the eye on the board; it lifts when the
  // temple's light comes back
  Shape {
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    ShapePath {
      strokeColor: "transparent"
      fillGradient: RadialGradient {
        centerX: root.w / 2; centerY: root.h * 0.52; centerRadius: Math.max(root.w, root.h) * 0.75
        focalX: centerX; focalY: centerY
        GradientStop { position: 0.45; color: "transparent" }
        GradientStop { position: 1.0; color: "#AA040A06" }
      }
      startX: 0; startY: 0
      PathLine { x: root.w; y: 0 }
      PathLine { x: root.w; y: root.h }
      PathLine { x: 0; y: root.h }
    }
  }
  Rectangle {
    anchors.fill: parent
    color: "#081408"
    opacity: root.restored ? 0.0 : 0.22
    Behavior on opacity { NumberAnimation { duration: Theme.ms(1800); easing.type: Easing.InOutQuad } }
  }
  Rectangle {
    anchors.fill: parent
    opacity: root.restored ? 0.18 : 0.0
    Behavior on opacity { NumberAnimation { duration: Theme.ms(1200) } }
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.look.light }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
}
