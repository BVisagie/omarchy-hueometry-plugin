import QtQuick
import QtQuick.Particles
import "js/palette.mjs" as Palette

// A short burst of orb-coloured sparkles, for a solved puzzle.
Item {
  id: root

  function burst() {
    if (Theme.reducedMotion) return
    emitter.burst(140)
  }

  ParticleSystem { id: system; anchors.fill: parent }
  ItemParticle {
    system: system
    fade: true
    delegate: Rectangle {
      readonly property var tone: Palette.orb(Math.floor(Math.random() * 6))
      width: Theme.em * (0.35 + Math.random() * 0.5)
      height: width
      radius: width / 2
      color: tone.light
      border.color: tone.base
      border.width: Math.max(1, width * 0.2)
    }
  }
  Emitter {
    id: emitter
    system: system
    anchors.centerIn: parent
    width: parent.width * 0.5
    height: parent.height * 0.3
    emitRate: 0
    lifeSpan: 1600
    lifeSpanVariation: 500
    velocity: AngleDirection { angle: 270; angleVariation: 70; magnitude: root.height * 0.55; magnitudeVariation: root.height * 0.25 }
    acceleration: PointDirection { y: root.height * 0.6 }
  }
}
