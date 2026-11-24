import QtQuick
import QtQuick.Shapes
import QtQuick.Particles

// The Lost Jungle Temple, drawn: canopy light, far trees, each area's own
// landmark (standing stones, a river under a rope bridge, arches, a
// waterfall, the temple, the heart tree), swaying
// leaves and vines, mist and fireflies. The middle stays calm and dark enough
// for the board. `restored` brings colour and light back when a puzzle is
// solved. Placement is seeded per area, so each area always looks the same.
Item {
  id: root
  property int area: 0
  property bool restored: false
  // drawn once and never moving: the map's small pictures of each area
  property bool still: false
  readonly property bool moving: !still && !Theme.reducedMotion

  // tutorial, clearing, river, ruins, waterfall, temple, heart
  readonly property var looks: [
    { top: "#6E9E52", mid: "#2F6036", ground: "#13301B", far: "#24502F", leaf: "#3E7A3A", near: "#14341C", light: "#FFF1B8", feature: "none" },
    { top: "#7DAA4E", mid: "#2E6A33", ground: "#12321A", far: "#23562C", leaf: "#468A3C", near: "#123A1B", light: "#FFF0A8", feature: "stones" },
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
        running: root.moving
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

  // each area's landmark. They stand behind the board, so they rise into
  // the band above it and show between the pillars, sunk in the area's haze
  // (hazed) so they never compete with the orbs.
  Loader {
    anchors.fill: parent
    sourceComponent: ({ stones: stones, river: river, ruins: ruins, waterfall: waterfall, temple: temple, heart: heart })[root.look.feature] || null
  }

  // far things take on the colour of the air
  function hazed(c, k) { return Qt.tint(c, Qt.alpha(look.mid, k)) }
  // a point on a quadratic curve, for things hung along one
  function quad(a, c, b, t) { return (1 - t) * (1 - t) * a + 2 * (1 - t) * t * c + t * t * b }

  // a stone arch: two legs and a round head, `thick` wide
  component Arch: Shape {
    id: arch
    property real x0: 0
    property real x1: 100
    property real head: 0
    property real foot: 100
    property real thick: 10
    property color stone: "#6E7460"
    readonly property real r: (x1 - x0) / 2
    anchors.fill: parent
    preferredRendererType: Shape.CurveRenderer
    // one outline: up the left leg, over the head, down the right leg, and
    // back under the opening
    ShapePath {
      fillColor: arch.stone
      strokeColor: Qt.alpha(root.look.light, 0.16)
      strokeWidth: 1.5
      startX: arch.x0; startY: arch.foot
      PathLine { x: arch.x0; y: arch.head + arch.r }
      PathArc { x: arch.x1; y: arch.head + arch.r; radiusX: arch.r; radiusY: arch.r }
      PathLine { x: arch.x1; y: arch.foot }
      PathLine { x: arch.x1 - arch.thick; y: arch.foot }
      PathLine { x: arch.x1 - arch.thick; y: arch.head + arch.r }
      PathArc { x: arch.x0 + arch.thick; y: arch.head + arch.r; radiusX: arch.r - arch.thick; radiusY: arch.r - arch.thick; direction: PathArc.Counterclockwise }
      PathLine { x: arch.x0 + arch.thick; y: arch.foot }
      PathLine { x: arch.x0; y: arch.foot }
    }
  }

  // a flame that flickers
  component Torch: Rectangle {
    id: torch
    property real fx: 0
    property real fy: 0
    x: root.w * fx - width / 2
    y: root.h * fy - height
    width: root.w * 0.009; height: width * 1.7; radius: width / 2
    color: "#FFC45A"
    // its glow on the stone
    Rectangle {
      anchors.centerIn: parent
      width: parent.width * 5; height: width; radius: width / 2
      color: Qt.alpha("#FFB040", root.restored ? 0.22 : 0.12)
      z: -1
    }
    SequentialAnimation on opacity {
      running: root.moving
      loops: Animation.Infinite
      NumberAnimation { to: 0.6; duration: 260 + torch.fx * 200 }
      NumberAnimation { to: 1.0; duration: 380 + torch.fy * 200 }
    }
  }

  Component {
    id: stones
    Item {
      // standing stones at the clearing's edge, with a carved ring that
      // wakes when the light comes back
      Repeater {
        model: [[0.05, 0.2, 0.055], [0.15, 0.27, 0.045], [0.85, 0.24, 0.05], [0.94, 0.18, 0.058]]
        Rectangle {
          required property var modelData
          x: root.w * modelData[0] - width / 2
          y: root.h * modelData[1]
          width: root.w * modelData[2]
          height: root.h * 0.75 - y
          radius: width * 0.45
          gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: root.hazed("#6A6F5E", 0.35) }
            GradientStop { position: 0.4; color: root.hazed("#8A8E78", 0.35) }
            GradientStop { position: 1.0; color: root.hazed("#4A5042", 0.35) }
          }
          // moss on its crown
          Rectangle {
            width: parent.width * 0.8; height: parent.width * 0.28; radius: height / 2
            x: parent.width * 0.1; y: parent.width * 0.08
            color: root.hazed(root.look.leaf, 0.2)
          }
          Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            y: parent.width * 0.7
            width: parent.width * 0.5; height: width; radius: width / 2
            color: "transparent"
            border.width: Math.max(1.5, width * 0.14)
            border.color: root.restored ? Qt.alpha("#FFE9A0", 0.8) : Qt.alpha("#000000", 0.25)
            Behavior on border.color { enabled: !root.still; ColorAnimation { duration: Theme.ms(1200) } }
          }
        }
      }
    }
  }

  Component {
    id: river
    Item {
      // the river winds out of the far forest and widens toward you
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        opacity: 0.9
        ShapePath {
          strokeColor: "transparent"
          fillGradient: LinearGradient {
            x1: 0; y1: root.h * 0.6; x2: 0; y2: root.h
            GradientStop { position: 0.0; color: root.hazed("#BFEDE6", 0.3) }
            GradientStop { position: 0.35; color: "#3E8E92" }
            GradientStop { position: 1.0; color: "#143C46" }
          }
          startX: root.w * 0.4; startY: root.h * 0.6
          PathLine { x: root.w * 0.47; y: root.h * 0.6 }
          PathQuad { x: root.w * 1.05; y: root.h * 0.88; controlX: root.w * 0.76; controlY: root.h * 0.66 }
          PathLine { x: root.w * 1.05; y: root.h }
          PathLine { x: -root.w * 0.05; y: root.h }
          PathLine { x: -root.w * 0.05; y: root.h * 0.82 }
          PathQuad { x: root.w * 0.4; y: root.h * 0.6; controlX: root.w * 0.18; controlY: root.h * 0.65 }
        }
      }
      // light glinting on the water
      Repeater {
        model: 16
        Rectangle {
          id: glint
          required property int index
          readonly property var p: root.blobs[index % root.blobs.length]
          readonly property real t: (index + 0.5) / 16
          readonly property real spanW: 0.07 + t * 1.0
          x: root.w * (0.435 + t * 0.07 + (p[0] - 0.5) * spanW * 0.8) - width / 2
          y: root.h * (0.61 + t * t * 0.36)
          width: root.w * (0.012 + t * 0.05)
          height: Math.max(2, root.h * (0.002 + t * 0.004))
          radius: height / 2
          color: "#E0FBFF"
          opacity: 0.25 + p[1] * 0.3
          SequentialAnimation on opacity {
            running: root.moving
            loops: Animation.Infinite
            PauseAnimation { duration: glint.p[2] * 2000 }
            NumberAnimation { to: 0.05; duration: 1400 + glint.p[3] * 1200; easing.type: Easing.InOutSine }
            NumberAnimation { to: 0.55; duration: 1400 + glint.p[3] * 1200; easing.type: Easing.InOutSine }
          }
        }
      }
      // a rope bridge high over the gorge
      Shape {
        id: bridge
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        readonly property color rope: root.hazed("#2A2216", 0.3)
        ShapePath {
          strokeColor: bridge.rope
          strokeWidth: Math.max(1.5, root.h * 0.003)
          fillColor: "transparent"
          startX: -root.w * 0.02; startY: root.h * 0.17
          PathQuad { x: root.w * 1.02; y: root.h * 0.17; controlX: root.w * 0.5; controlY: root.h * 0.36 }
        }
        ShapePath {
          strokeColor: bridge.rope
          strokeWidth: Math.max(2.5, root.h * 0.007)
          fillColor: "transparent"
          startX: -root.w * 0.02; startY: root.h * 0.215
          PathQuad { x: root.w * 1.02; y: root.h * 0.215; controlX: root.w * 0.5; controlY: root.h * 0.41 }
        }
      }
      // hangers from the hand rope to the deck, and the deck's planks
      Repeater {
        model: 19
        Rectangle {
          required property int index
          readonly property real t: (index + 1) / 20
          readonly property real hand: root.quad(0.17, 0.36, 0.17, t)
          readonly property real deck: root.quad(0.215, 0.41, 0.215, t)
          x: root.w * (-0.02 + t * 1.04)
          y: root.h * hand
          width: Math.max(1, root.h * 0.002)
          height: root.h * (deck - hand)
          color: bridge.rope
        }
      }
      Repeater {
        model: 38
        Rectangle {
          required property int index
          readonly property real t: (index + 0.5) / 38
          x: root.w * (-0.02 + t * 1.04) - width / 2
          y: root.h * root.quad(0.215, 0.41, 0.215, t) - height * 0.3
          width: root.w * 0.011
          height: Math.max(2, root.h * 0.009)
          radius: 1
          color: root.hazed("#5A4630", 0.3)
        }
      }
    }
  }

  Component {
    id: ruins
    Item {
      // a great broken arch far off, then a colonnade on the left and a gate
      // on the right, overgrown
      Arch {
        x0: root.w * 0.3; x1: root.w * 0.7; head: root.h * 0.08; foot: root.h * 0.8; thick: root.w * 0.035
        stone: root.hazed("#7A806A", 0.62)
      }
      // its broken keystone: a gap in the head
      Rectangle {
        x: root.w * 0.515; y: root.h * 0.07
        width: root.w * 0.035; height: root.h * 0.08
        rotation: 12
        color: root.hazed(root.look.far, 0.3)
      }
      Repeater {
        model: [0.0, 0.11]
        Arch {
          required property real modelData
          x0: root.w * modelData; x1: root.w * (modelData + 0.11); head: root.h * 0.2; foot: root.h * 0.82; thick: root.w * 0.022
          stone: root.hazed("#6E7460", 0.35)
        }
      }
      // the lintel over the colonnade, broken short
      Rectangle {
        x: -root.w * 0.01; y: root.h * 0.17
        width: root.w * 0.205; height: root.h * 0.035
        color: root.hazed("#767C66", 0.35)
        border.color: Qt.alpha(root.look.light, 0.14)
      }
      // a fallen pillar's stump
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          fillColor: root.hazed("#6E7460", 0.35)
          strokeColor: Qt.alpha(root.look.light, 0.16)
          strokeWidth: 1.5
          startX: root.w * 0.22; startY: root.h * 0.82
          PathLine { x: root.w * 0.22; y: root.h * 0.42 }
          PathLine { x: root.w * 0.228; y: root.h * 0.39 }
          PathLine { x: root.w * 0.236; y: root.h * 0.43 }
          PathLine { x: root.w * 0.244; y: root.h * 0.37 }
          PathLine { x: root.w * 0.244; y: root.h * 0.82 }
        }
      }
      Arch {
        x0: root.w * 0.76; x1: root.w * 0.97; head: root.h * 0.12; foot: root.h * 0.82; thick: root.w * 0.03
        stone: root.hazed("#6E7460", 0.35)
      }
      // moss on the tops and vines hanging from the heads
      Repeater {
        model: [[0.02, 0.165, 0.18], [0.79, 0.115, 0.15], [0.42, 0.075, 0.16]]
        Rectangle {
          required property var modelData
          x: root.w * modelData[0]; y: root.h * modelData[1]
          width: root.w * modelData[2]; height: root.h * 0.014; radius: height / 2
          color: root.hazed(root.look.leaf, modelData[0] > 0.3 && modelData[0] < 0.7 ? 0.55 : 0.2)
        }
      }
      Repeater {
        model: [[0.035, 0.2, 0.12], [0.07, 0.2, 0.2], [0.145, 0.2, 0.09], [0.82, 0.13, 0.16], [0.9, 0.13, 0.24], [0.94, 0.15, 0.1]]
        Rectangle {
          required property var modelData
          x: root.w * modelData[0]; y: root.h * modelData[1]
          width: Math.max(1.5, root.w * 0.0025); height: root.h * modelData[2]
          radius: width / 2
          color: root.hazed(Qt.darker(root.look.leaf, 1.2), 0.2)
        }
      }
    }
  }

  Component {
    id: waterfall
    Item {
      // a cliff in the back, and the fall pouring from its lip
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: Qt.alpha(root.look.light, 0.14)
          strokeWidth: 1.5
          fillGradient: LinearGradient {
            x1: root.w * 0.3; y1: 0; x2: root.w * 0.71; y2: 0
            GradientStop { position: 0.0; color: root.hazed("#3E504C", 0.45) }
            GradientStop { position: 0.35; color: root.hazed("#566A64", 0.45) }
            GradientStop { position: 1.0; color: root.hazed("#2E3E3C", 0.45) }
          }
          startX: root.w * 0.3; startY: root.h
          PathLine { x: root.w * 0.31; y: root.h * 0.5 }
          PathLine { x: root.w * 0.34; y: root.h * 0.3 }
          PathLine { x: root.w * 0.37; y: root.h * 0.13 }
          PathLine { x: root.w * 0.41; y: root.h * 0.06 }
          PathLine { x: root.w * 0.45; y: root.h * 0.08 }
          PathLine { x: root.w * 0.55; y: root.h * 0.08 }
          PathLine { x: root.w * 0.59; y: root.h * 0.04 }
          PathLine { x: root.w * 0.64; y: root.h * 0.14 }
          PathLine { x: root.w * 0.67; y: root.h * 0.33 }
          PathLine { x: root.w * 0.7; y: root.h * 0.56 }
          PathLine { x: root.w * 0.71; y: root.h }
        }
      }
      // ferns on the ledges
      Repeater {
        model: [[0.38, 0.13], [0.6, 0.06], [0.33, 0.33], [0.66, 0.3]]
        Rectangle {
          required property var modelData
          x: root.w * modelData[0] - width / 2; y: root.h * modelData[1] - height / 2
          width: root.w * 0.05; height: root.h * 0.025; radius: height / 2
          color: root.hazed(root.look.leaf, 0.3)
        }
      }
      // the falling sheet
      Rectangle {
        x: root.w * 0.455; y: root.h * 0.075
        width: root.w * 0.09; height: root.h * 0.925
        opacity: 0.6
        gradient: Gradient {
          orientation: Gradient.Horizontal
          GradientStop { position: 0.0; color: "#406E9AA8" }
          GradientStop { position: 0.3; color: "#B0D8F2F8" }
          GradientStop { position: 0.7; color: "#A0C8E8F0" }
          GradientStop { position: 1.0; color: "#406E9AA8" }
        }
      }
      // streaks falling, from the lip down
      Item {
        x: root.w * 0.455; y: root.h * 0.075
        width: root.w * 0.09; height: root.h * 0.925
        clip: true
      Repeater {
        model: 14
        Rectangle {
          id: streak
          required property int index
          readonly property real lip: 0
          readonly property real pool: root.h * 0.925
          x: root.w * (0.007 + (index * 0.37 % 1) * 0.074)
          y: lip + (index * 0.61 % 1) * (pool - lip)
          width: Math.max(2, root.w * 0.003); height: root.h * 0.13; radius: width / 2
          color: "#F2FFFFFF"; opacity: 0.5
          NumberAnimation on y {
            running: root.moving
            loops: Animation.Infinite
            from: streak.lip - streak.height; to: streak.pool
            duration: 1300 + streak.index * 110
          }
        }
      }
      }
      // foam at the lip
      Rectangle {
        x: root.w * 0.445; y: root.h * 0.065
        width: root.w * 0.11; height: root.h * 0.025; radius: height / 2
        color: "#C0F2FCFF"
      }
      // mist rising where it lands, drifting up between the pillars
      Repeater {
        model: 7
        Rectangle {
          id: puff
          required property int index
          readonly property real k: (index * 0.43) % 1
          property real rise: k
          x: root.w * (0.5 + (index % 2 ? 1 : -1) * (0.03 + k * 0.08)) - width / 2
          y: root.h * (0.98 - rise * 0.36) - height / 2
          width: root.w * (0.1 + rise * 0.1)
          height: width * 0.55
          radius: height / 2
          color: root.look.light
          opacity: 0.2 * (1 - rise)
          NumberAnimation on rise {
            running: root.moving
            loops: Animation.Infinite
            from: 0; to: 1
            duration: 7000 + puff.index * 900
          }
        }
      }
    }
  }

  Component {
    id: temple
    Item {
      id: templeView
      // the temple: five tiers, a stair up the middle, and the shrine on
      // top whose door lights when the colour comes back
      readonly property color body: root.hazed("#5E4A2C", 0.42)
      readonly property color lit: Qt.alpha(root.look.light, 0.2)
      Repeater {
        model: 5
        Shape {
          id: tier
          required property int index
          readonly property real base: 0.88 - index * 0.13
          readonly property real half: 0.42 - index * 0.06
          anchors.fill: parent
          preferredRendererType: Shape.CurveRenderer
          ShapePath {
            strokeColor: "transparent"
            fillColor: Qt.darker(templeView.body, 1 + tier.index * 0.03)
            startX: root.w * (0.5 - tier.half); startY: root.h * tier.base
            PathLine { x: root.w * (0.5 - tier.half + 0.015); y: root.h * (tier.base - 0.13) }
            PathLine { x: root.w * (0.5 + tier.half - 0.015); y: root.h * (tier.base - 0.13) }
            PathLine { x: root.w * (0.5 + tier.half); y: root.h * tier.base }
          }
        }
      }
      // the lit top edge of each tier
      Repeater {
        model: 5
        Rectangle {
          required property int index
          readonly property real half: 0.42 - index * 0.06 - 0.015
          x: root.w * (0.5 - half); y: root.h * (0.75 - index * 0.13)
          width: root.w * half * 2; height: Math.max(2, root.h * 0.006)
          color: templeView.lit
        }
      }
      // the stair
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: "transparent"
          fillColor: root.hazed("#7C6844", 0.42)
          startX: root.w * 0.4; startY: root.h * 0.88
          PathLine { x: root.w * 0.465; y: root.h * 0.23 }
          PathLine { x: root.w * 0.535; y: root.h * 0.23 }
          PathLine { x: root.w * 0.6; y: root.h * 0.88 }
        }
      }
      Repeater {
        model: 26
        Rectangle {
          required property int index
          readonly property real t: (index + 1) / 27
          x: root.w * (0.465 - t * 0.065)
          y: root.h * (0.23 + t * 0.65)
          width: root.w * (0.07 + t * 0.13)
          height: Math.max(1, root.h * 0.003)
          color: "#30000000"
        }
      }
      // the shrine: walls, a roof, and its door
      Rectangle {
        x: root.w * 0.41; y: root.h * 0.11
        width: root.w * 0.18; height: root.h * 0.12
        color: root.hazed("#6A5434", 0.42)
        border.color: templeView.lit
        // carved glyphs either side of the door
        Repeater {
          model: [0.18, 0.72]
          Rectangle {
            required property real modelData
            x: parent.width * modelData; y: parent.height * 0.3
            width: parent.width * 0.1; height: width; radius: width * 0.2
            color: "transparent"
            border.color: root.restored ? Qt.alpha("#FFD890", 0.8) : "#40000000"
            border.width: Math.max(1.5, width * 0.18)
            Behavior on border.color { enabled: !root.still; ColorAnimation { duration: Theme.ms(1500) } }
          }
        }
      }
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: "transparent"
          fillColor: root.hazed("#4E3C22", 0.42)
          startX: root.w * 0.395; startY: root.h * 0.115
          PathLine { x: root.w * 0.44; y: root.h * 0.055 }
          PathLine { x: root.w * 0.56; y: root.h * 0.055 }
          PathLine { x: root.w * 0.605; y: root.h * 0.115 }
        }
      }
      Rectangle {
        x: root.w * 0.475; y: root.h * 0.15
        width: root.w * 0.05; height: root.h * 0.08
        radius: width * 0.5
        color: root.restored ? "#FFD27A" : "#1E150A"
        Behavior on color { enabled: !root.still; ColorAnimation { duration: Theme.ms(1500) } }
      }
      Torch { fx: 0.455; fy: 0.2 }
      Torch { fx: 0.545; fy: 0.2 }
      Torch { fx: 0.13; fy: 0.86 }
      Torch { fx: 0.87; fy: 0.86 }
      Torch { fx: 0.25; fy: 0.6 }
      Torch { fx: 0.75; fy: 0.6 }
    }
  }

  Component {
    id: heart
    Item {
      id: heartView
      // the heart tree: a vast trunk and crown, glowing flowers, and the
      // heart in its fork that beats brighter when the colour returns
      readonly property color bark: root.hazed("#4A3E6E", 0.2)
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        // the trunk, its roots spreading, lit from the left
        ShapePath {
          strokeColor: Qt.alpha(root.look.light, 0.18)
          strokeWidth: 1.5
          fillGradient: LinearGradient {
            x1: root.w * 0.42; y1: 0; x2: root.w * 0.58; y2: 0
            GradientStop { position: 0.0; color: Qt.lighter(heartView.bark, 1.35) }
            GradientStop { position: 0.6; color: heartView.bark }
            GradientStop { position: 1.0; color: Qt.darker(heartView.bark, 1.3) }
          }
          startX: root.w * 0.3; startY: root.h
          PathQuad { x: root.w * 0.455; y: root.h * 0.7; controlX: root.w * 0.43; controlY: root.h * 0.93 }
          PathLine { x: root.w * 0.468; y: root.h * 0.23 }
          PathLine { x: root.w * 0.532; y: root.h * 0.23 }
          PathLine { x: root.w * 0.545; y: root.h * 0.7 }
          PathQuad { x: root.w * 0.7; y: root.h; controlX: root.w * 0.57; controlY: root.h * 0.93 }
        }
        // its boughs
        ShapePath {
          strokeColor: heartView.bark
          strokeWidth: root.w * 0.022
          capStyle: ShapePath.RoundCap
          fillColor: "transparent"
          startX: root.w * 0.48; startY: root.h * 0.27
          PathQuad { x: root.w * 0.24; y: root.h * 0.1; controlX: root.w * 0.4; controlY: root.h * 0.13 }
        }
        ShapePath {
          strokeColor: heartView.bark
          strokeWidth: root.w * 0.022
          capStyle: ShapePath.RoundCap
          fillColor: "transparent"
          startX: root.w * 0.52; startY: root.h * 0.27
          PathQuad { x: root.w * 0.77; y: root.h * 0.09; controlX: root.w * 0.6; controlY: root.h * 0.12 }
        }
        ShapePath {
          strokeColor: heartView.bark
          strokeWidth: root.w * 0.016
          capStyle: ShapePath.RoundCap
          fillColor: "transparent"
          startX: root.w * 0.5; startY: root.h * 0.25
          PathQuad { x: root.w * 0.52; y: root.h * 0.04; controlX: root.w * 0.49; controlY: root.h * 0.14 }
        }
      }
      // the crown: great soft masses lit from above
      Repeater {
        model: [[0.12, -0.06, 0.26], [0.3, -0.1, 0.24], [0.5, -0.12, 0.26], [0.7, -0.08, 0.24], [0.86, -0.04, 0.22], [0.22, 0.04, 0.2], [0.76, 0.05, 0.2]]
        Rectangle {
          required property var modelData
          x: root.w * (modelData[0] - modelData[2] / 2)
          y: root.h * modelData[1]
          width: root.w * modelData[2]; height: width * 0.5; radius: height / 2
          gradient: Gradient {
            GradientStop { position: 0.0; color: root.hazed("#6A58A8", 0.25) }
            GradientStop { position: 1.0; color: root.hazed("#33296A", 0.25) }
          }
        }
      }
      // strands hanging from the crown, each with a glowing seed
      Repeater {
        model: 9
        Item {
          id: strand
          required property int index
          readonly property var p: root.blobs[(index * 3) % root.blobs.length]
          x: root.w * (0.08 + index * 0.105 + p[0] * 0.03)
          y: root.h * (0.12 + p[1] * 0.06)
          Rectangle { width: Math.max(1, root.w * 0.0015); height: root.h * (0.06 + strand.p[2] * 0.1); color: Qt.alpha("#C4B8FF", 0.35) }
          Rectangle {
            x: -width / 2; y: root.h * (0.06 + strand.p[2] * 0.1)
            width: root.w * 0.007; height: width; radius: width / 2
            color: ["#F7C8E2", "#C4EBFF", "#FFF9B8"][strand.index % 3]
          }
        }
      }
      // flowers in the crown
      Repeater {
        model: 18
        Rectangle {
          id: flower
          required property int index
          readonly property var p: root.blobs[index % root.blobs.length]
          x: root.w * (0.08 + p[0] * 0.84)
          y: root.h * (0.0 + p[1] * 0.2)
          width: root.w * 0.008; height: width; radius: width / 2
          color: ["#F7C8E2", "#C4EBFF", "#FFF9B8"][index % 3]
          SequentialAnimation on opacity {
            running: root.moving
            loops: Animation.Infinite
            NumberAnimation { to: 0.3; duration: 1800 + flower.index * 90 }
            NumberAnimation { to: 1.0; duration: 1800 + flower.index * 90 }
          }
        }
      }
      // the heart in the fork, and its glow
      Rectangle {
        x: root.w * 0.5 - width / 2; y: root.h * 0.22 - height / 2
        // grows when the colour returns (a resize never animates)
        property real grow: root.restored ? 1.6 : 1
        Behavior on grow { enabled: !root.still; NumberAnimation { duration: Theme.ms(1500) } }
        width: root.w * 0.1 * grow; height: width; radius: width / 2
        gradient: Gradient {
          GradientStop { position: 0.0; color: "transparent" }
          GradientStop { position: 0.5; color: Qt.alpha("#FFB8E0", root.restored ? 0.35 : 0.16) }
          GradientStop { position: 1.0; color: "transparent" }
        }
      }
      Shape {
        id: beat
        readonly property real cx: root.w * 0.5
        readonly property real cy: root.h * 0.22
        readonly property real s: root.w * 0.05
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        transformOrigin: Item.TopLeft
        opacity: root.restored ? 1.0 : 0.65
        Behavior on opacity { enabled: !root.still; NumberAnimation { duration: Theme.ms(1500) } }
        ShapePath {
          strokeColor: Qt.alpha("#FFFFFF", 0.5)
          strokeWidth: 1.5
          fillColor: root.restored ? "#FF9ED0" : "#B0708F"
          startX: beat.cx; startY: beat.cy + beat.s * 0.4
          PathCubic { x: beat.cx - beat.s * 0.5; y: beat.cy - beat.s * 0.05; control1X: beat.cx - beat.s * 0.2; control1Y: beat.cy + beat.s * 0.2; control2X: beat.cx - beat.s * 0.5; control2Y: beat.cy + beat.s * 0.12 }
          PathArc { x: beat.cx; y: beat.cy - beat.s * 0.12; radiusX: beat.s * 0.25; radiusY: beat.s * 0.25 }
          PathArc { x: beat.cx + beat.s * 0.5; y: beat.cy - beat.s * 0.05; radiusX: beat.s * 0.25; radiusY: beat.s * 0.25 }
          PathCubic { x: beat.cx; y: beat.cy + beat.s * 0.4; control1X: beat.cx + beat.s * 0.5; control1Y: beat.cy + beat.s * 0.12; control2X: beat.cx + beat.s * 0.2; control2Y: beat.cy + beat.s * 0.2 }
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
        running: root.moving
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
      sway: root.still ? 0 : 2.5
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
        running: root.moving
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
    running: root.moving
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
      sway: root.still ? 0 : 1.5
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
    Behavior on opacity { enabled: !root.still; NumberAnimation { duration: Theme.ms(1800); easing.type: Easing.InOutQuad } }
  }
  Rectangle {
    anchors.fill: parent
    opacity: root.restored ? 0.18 : 0.0
    Behavior on opacity { enabled: !root.still; NumberAnimation { duration: Theme.ms(1200) } }
    gradient: Gradient {
      GradientStop { position: 0.0; color: root.look.light }
      GradientStop { position: 1.0; color: "transparent" }
    }
  }
}
