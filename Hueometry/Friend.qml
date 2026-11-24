import QtQuick
import QtQuick.Shapes

// An animal friend who pops up from the corner to cheer a solved puzzle: a
// toucan in some areas, a tree frog in others. Drawn, not pictured.
Item {
  id: root
  property string kind: "toucan"
  property bool cheering: false
  property real size: 200

  width: size
  height: size
  clip: false

  // rises into view, then bobs
  property real rise: cheering ? 0 : 1
  Behavior on rise { NumberAnimation { duration: Theme.ms(520); easing.type: Easing.OutBack } }
  property real bob: 0
  SequentialAnimation on bob {
    running: root.cheering && !Theme.reducedMotion
    loops: Animation.Infinite
    NumberAnimation { to: -root.size * 0.04; duration: 380; easing.type: Easing.InOutSine }
    NumberAnimation { to: 0; duration: 380; easing.type: Easing.InOutSine }
  }
  visible: rise < 0.99

  Item {
    id: body
    width: root.size
    height: root.size
    y: root.rise * root.size * 1.1 + root.bob

    // a branch to sit on
    Rectangle {
      x: -root.size * 0.2
      y: root.size * 0.86
      width: root.size * 1.4
      height: root.size * 0.07
      radius: height / 2
      color: "#5A3E24"
      rotation: -4
    }

    Loader {
      anchors.fill: parent
      sourceComponent: root.kind === "frog" ? frog : toucan
    }
  }

  Component {
    id: toucan
    Item {
      // tail
      Rectangle { x: root.size * 0.22; y: root.size * 0.62; width: root.size * 0.14; height: root.size * 0.32; radius: width / 2; color: "#15151A"; rotation: 18 }
      // body
      Rectangle { x: root.size * 0.24; y: root.size * 0.28; width: root.size * 0.38; height: root.size * 0.56; radius: width / 2; color: "#1C1C24" }
      // white throat
      Rectangle { x: root.size * 0.4; y: root.size * 0.33; width: root.size * 0.2; height: root.size * 0.24; radius: width / 2; color: "#FFF4D6" }
      // head
      Rectangle { x: root.size * 0.3; y: root.size * 0.16; width: root.size * 0.3; height: root.size * 0.28; radius: width / 2; color: "#1C1C24" }
      // eye
      Rectangle { x: root.size * 0.47; y: root.size * 0.23; width: root.size * 0.09; height: width; radius: width / 2; color: "#7FD6FF"
        Rectangle { anchors.centerIn: parent; width: parent.width * 0.5; height: width; radius: width / 2; color: "#101014" } }
      // the big beak
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: "#8A3A0A"
          strokeWidth: Math.max(1, root.size * 0.01)
          fillGradient: LinearGradient {
            x1: root.size * 0.55; y1: root.size * 0.2; x2: root.size * 0.98; y2: root.size * 0.36
            GradientStop { position: 0.0; color: "#FFD23F" }
            GradientStop { position: 0.6; color: "#FF8A1F" }
            GradientStop { position: 1.0; color: "#D8401A" }
          }
          startX: root.size * 0.57; startY: root.size * 0.2
          PathCubic { x: root.size * 0.98; y: root.size * 0.34; control1X: root.size * 0.76; control1Y: root.size * 0.14; control2X: root.size * 0.93; control2Y: root.size * 0.22 }
          PathCubic { x: root.size * 0.58; y: root.size * 0.36; control1X: root.size * 0.86; control1Y: root.size * 0.4; control2X: root.size * 0.7; control2Y: root.size * 0.38 }
        }
      }
      // feet
      Rectangle { x: root.size * 0.36; y: root.size * 0.82; width: root.size * 0.06; height: root.size * 0.06; radius: width / 2; color: "#4C6A9A" }
      Rectangle { x: root.size * 0.46; y: root.size * 0.82; width: root.size * 0.06; height: root.size * 0.06; radius: width / 2; color: "#4C6A9A" }
    }
  }

  Component {
    id: frog
    Item {
      // back legs
      Rectangle { x: root.size * 0.14; y: root.size * 0.62; width: root.size * 0.28; height: root.size * 0.24; radius: height / 2; color: "#3FA34D" }
      Rectangle { x: root.size * 0.58; y: root.size * 0.62; width: root.size * 0.28; height: root.size * 0.24; radius: height / 2; color: "#3FA34D" }
      // body
      Rectangle {
        x: root.size * 0.2; y: root.size * 0.36; width: root.size * 0.6; height: root.size * 0.5; radius: height / 2
        gradient: Gradient { GradientStop { position: 0.0; color: "#6BD36B" } GradientStop { position: 1.0; color: "#2E8A3A" } }
      }
      // belly
      Rectangle { x: root.size * 0.33; y: root.size * 0.56; width: root.size * 0.34; height: root.size * 0.26; radius: height / 2; color: "#D8F5B8" }
      // eyes: red-eyed tree frog
      Repeater {
        model: [0.24, 0.56]
        Rectangle {
          required property var modelData
          x: root.size * modelData; y: root.size * 0.24; width: root.size * 0.2; height: width; radius: width / 2; color: "#5CC85C"
          Rectangle { anchors.centerIn: parent; width: parent.width * 0.72; height: width; radius: width / 2; color: "#E0352B"
            Rectangle { anchors.centerIn: parent; width: parent.width * 0.32; height: parent.height * 0.7; radius: width / 2; color: "#101010" } }
        }
      }
      // a smile
      Shape {
        anchors.fill: parent
        preferredRendererType: Shape.CurveRenderer
        ShapePath {
          strokeColor: "#1E5A24"
          strokeWidth: Math.max(2, root.size * 0.018)
          capStyle: ShapePath.RoundCap
          fillColor: "transparent"
          startX: root.size * 0.38; startY: root.size * 0.5
          PathQuad { x: root.size * 0.62; y: root.size * 0.5; controlX: root.size * 0.5; controlY: root.size * 0.58 }
        }
      }
      // front feet
      Rectangle { x: root.size * 0.3; y: root.size * 0.8; width: root.size * 0.12; height: root.size * 0.07; radius: height / 2; color: "#F28C28" }
      Rectangle { x: root.size * 0.58; y: root.size * 0.8; width: root.size * 0.12; height: root.size * 0.07; radius: height / 2; color: "#F28C28" }
    }
  }
}
